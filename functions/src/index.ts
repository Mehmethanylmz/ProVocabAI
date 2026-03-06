/**
 * functions/src/index.ts
 *
 * FAZ 4 + FAZ 6 GÜNCELLEME:
 *   calculateWeeklyLeaderboard — Artık root users dokümanını da sıfırlar
 *   checkStreaks               — Root + profile dual update
 *   sendDailyReminders         — YENİ: Her gün 06:00 UTC (09:00 TR)
 *   sendStreakReminder          — Root users dokümanından oku
 *   validateXPUpdate           — Değişiklik yok
 *
 * Deploy:
 *   cd functions && npm install && npm run build
 *   firebase deploy --only functions
 */

import * as admin from "firebase-admin";
import {
  onDocumentUpdated,
  DocumentSnapshot,
} from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";

// ── Init ──────────────────────────────────────────────────────────────────────

admin.initializeApp();
const db = admin.firestore();

// ── Types ─────────────────────────────────────────────────────────────────────

interface UserProfile {
  uid: string;
  displayName?: string;
  weeklyXp: number;
  totalXp: number;
  streak: number;
  weekId?: string;
  lastActiveDate?: string;
  fcmToken?: string;
}

interface LeaderboardEntry {
  uid: string;
  displayName: string;
  weeklyXp: number;
  rank: number;
  updatedAt: number;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function todayString(): string {
  return new Date().toISOString().slice(0, 10);
}

function yesterdayString(): string {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return d.toISOString().slice(0, 10);
}

function currentWeekId(date: Date = new Date()): string {
  const dayOfWeek = date.getDay();
  const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
  const thursday = new Date(date);
  thursday.setDate(date.getDate() + mondayOffset + 3);

  const yearStart = new Date(thursday.getFullYear(), 0, 1);
  const weekNum = Math.ceil(
    ((thursday.getTime() - yearStart.getTime()) / 86_400_000 + 1) / 7
  );
  return `${thursday.getFullYear()}-W${String(weekNum).padStart(2, "0")}`;
}

// ── F1: calculateWeeklyLeaderboard ────────────────────────────────────────────
//
// Pazartesi 00:01 UTC:
//   1. Root users dokümanlarından weeklyXp topla
//   2. weeklyXp azalan → rank ata
//   3. leaderboard/weekly/{weekId} koleksiyonuna yaz (top 100 — arşiv amaçlı)
//   4. Root + profile: weeklyXp → 0 sıfırla

export const calculateWeeklyLeaderboard = onSchedule(
  {
    schedule: "1 0 * * 1",
    timeZone: "UTC",
    region: "us-central1",
  },
  async () => {
    logger.info("calculateWeeklyLeaderboard started");

    const weekId = currentWeekId();

    // Root users dokümanlarını oku (FAZ 4: leaderboard buradan sorgulanır)
    const usersSnap = await db.collection("users").get();

    const entries: { uid: string; displayName: string; weeklyXp: number }[] = [];

    for (const doc of usersSnap.docs) {
      const data = doc.data() as Partial<UserProfile>;
      if ((data.weeklyXp ?? 0) > 0) {
        entries.push({
          uid: doc.id,
          displayName: data.displayName ?? "Anonymous",
          weeklyXp: data.weeklyXp ?? 0,
        });
      }
    }

    entries.sort((a, b) => b.weeklyXp - a.weeklyXp);

    const top100 = entries.slice(0, 100);
    const batch = db.batch();
    const weekRef = db
      .collection("leaderboard")
      .doc("weekly")
      .collection(weekId);

    // Arşiv: top 100'ü leaderboard koleksiyonuna yaz
    top100.forEach((entry, idx) => {
      const leaderboardEntry: LeaderboardEntry = {
        uid: entry.uid,
        displayName: entry.displayName,
        weeklyXp: entry.weeklyXp,
        rank: idx + 1,
        updatedAt: Date.now(),
      };
      batch.set(weekRef.doc(entry.uid), leaderboardEntry);
    });

    // Root + profile: weeklyXp sıfırla
    for (const doc of usersSnap.docs) {
      const data = doc.data() as Partial<UserProfile>;
      if ((data.weeklyXp ?? 0) > 0) {
        batch.update(doc.ref, { weeklyXp: 0 });
      }
    }

    // Profile alt dokümanları da sıfırla
    const profilesSnap = await db.collectionGroup("profile").get();
    for (const doc of profilesSnap.docs) {
      const data = doc.data() as Partial<UserProfile>;
      if ((data.weeklyXp ?? 0) > 0) {
        batch.update(doc.ref, { weeklyXp: 0 });
      }
    }

    await batch.commit();
    logger.info(`Leaderboard written: ${top100.length} entries for ${weekId}`);
  }
);

// ── F2: checkStreaks ──────────────────────────────────────────────────────────

export const checkStreaks = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "UTC",
    region: "us-central1",
  },
  async () => {
    logger.info("checkStreaks started");

    const yesterday = yesterdayString();
    const batch = db.batch();
    let resetCount = 0;

    // Root users dokümanlarını kontrol et
    const usersSnap = await db.collection("users").get();
    for (const doc of usersSnap.docs) {
      const data = doc.data() as Partial<UserProfile>;
      const lastActive = data.lastActiveDate ?? "";
      const streak = data.streak ?? 0;

      if (streak > 0 && lastActive < yesterday) {
        batch.update(doc.ref, { streak: 0 });
        resetCount++;
      }
    }

    // Profile alt dokümanları da sıfırla
    const profilesSnap = await db.collectionGroup("profile").get();
    for (const doc of profilesSnap.docs) {
      const data = doc.data() as Partial<UserProfile>;
      const lastActive = data.lastActiveDate ?? "";
      const streak = data.streak ?? 0;

      if (streak > 0 && lastActive < yesterday) {
        batch.update(doc.ref, { streak: 0 });
      }
    }

    await batch.commit();
    logger.info(`Streaks reset: ${resetCount} users`);
  }
);

// ── F3: sendDailyReminders (YENİ — FAZ 6) ──────────────────────────────────
//
// Her gün 06:00 UTC (09:00 Türkiye):
//   Bugün hiç çalışmamış kullanıcılara push bildirim

export const sendDailyReminders = onSchedule(
  {
    schedule: "0 6 * * *", // 06:00 UTC = 09:00 TR
    timeZone: "UTC",
    region: "us-central1",
  },
  async () => {
    logger.info("sendDailyReminders started");

    const today = todayString();
    const messaging = admin.messaging();
    let sentCount = 0;

    // Root users dokümanlarını oku
    const usersSnap = await db.collection("users").get();

    const messages: admin.messaging.TokenMessage[] = [];

    for (const doc of usersSnap.docs) {
      const data = doc.data() as Partial<UserProfile>;
      const lastActive = data.lastActiveDate ?? "";
      const fcmToken = data.fcmToken;

      // Bugün çalışmamış + token var
      if (lastActive !== today && fcmToken) {
        messages.push({
          token: fcmToken,
          notification: {
            title: "Bugün çalışmayı unutma! 📚",
            body: "Günlük kelime hedefiniz sizi bekliyor.",
          },
          data: {
            route: "/study_zone",
            type: "daily_reminder",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "savgo_main",
            },
          },
          apns: {
            payload: {
              aps: {
                badge: 1,
                sound: "default",
              },
            },
          },
        });
      }
    }

    // Batch send (500'lük gruplar — FCM limiti)
    const chunkSize = 500;
    for (let i = 0; i < messages.length; i += chunkSize) {
      const chunk = messages.slice(i, i + chunkSize);
      try {
        const result = await messaging.sendEach(chunk);
        sentCount += result.successCount;

        // Geçersiz token'ları temizle
        result.responses.forEach((resp, idx) => {
          if (
            resp.error?.code === "messaging/registration-token-not-registered" ||
            resp.error?.code === "messaging/invalid-registration-token"
          ) {
            const failedToken = chunk[idx].token;
            // Token'ı Firestore'dan sil
            usersSnap.docs
              .filter((d) => d.data().fcmToken === failedToken)
              .forEach((d) => {
                d.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
              });
          }
        });
      } catch (err) {
        logger.warn("Batch send error:", err);
      }
    }

    logger.info(`Daily reminders sent: ${sentCount}/${messages.length}`);
  }
);

// ── F4: sendStreakReminder ────────────────────────────────────────────────────
//
// Her gün 17:00 UTC (20:00 TR):
//   streak > 0 AND bugün çalışmamış → push bildirimi

export const sendStreakReminder = onSchedule(
  {
    schedule: "0 17 * * *", // 17:00 UTC = 20:00 TR
    timeZone: "UTC",
    region: "us-central1",
  },
  async () => {
    logger.info("sendStreakReminder started");

    const today = todayString();
    const messaging = admin.messaging();
    let sentCount = 0;

    // Root users dokümanlarını oku (FAZ 4 yapısı)
    const usersSnap = await db.collection("users").get();

    const messages: admin.messaging.TokenMessage[] = [];

    for (const doc of usersSnap.docs) {
      const data = doc.data() as Partial<UserProfile>;
      const streak = data.streak ?? 0;
      const lastActive = data.lastActiveDate ?? "";
      const fcmToken = data.fcmToken;
      const weeklyXp = data.weeklyXp ?? 0;

      // Streak aktif veya bu hafta çalışmış AMA bugün gelmemiş + token var
      if ((streak > 0 || weeklyXp > 0) && lastActive !== today && fcmToken) {
        const title =
          streak > 0
            ? `🔥 ${streak} günlük serini kaybetme!`
            : "📖 Bu haftaki çalışmana devam et!";
        const body =
          streak > 0
            ? "Bu haftaki çalışma serisini korumak için hemen başla."
            : "Günlük kelime hedefiniz sizi bekliyor.";

        messages.push({
          token: fcmToken,
          notification: { title, body },
          data: {
            route: "/study_zone",
            type: "streak_reminder",
          },
          android: {
            priority: "normal",
            notification: {
              channelId: "savgo_main",
            },
          },
          apns: {
            payload: {
              aps: { badge: 1 },
            },
          },
        });
      }
    }

    // Batch send
    const chunkSize = 500;
    for (let i = 0; i < messages.length; i += chunkSize) {
      const chunk = messages.slice(i, i + chunkSize);
      try {
        const result = await messaging.sendEach(chunk);
        sentCount += result.successCount;

        // Geçersiz token temizleme
        result.responses.forEach((resp, idx) => {
          if (
            resp.error?.code === "messaging/registration-token-not-registered" ||
            resp.error?.code === "messaging/invalid-registration-token"
          ) {
            const failedToken = chunk[idx].token;
            usersSnap.docs
              .filter((d) => d.data().fcmToken === failedToken)
              .forEach((d) => {
                d.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
              });
          }
        });
      } catch (err) {
        logger.warn("Batch send error:", err);
      }
    }

    logger.info(`Streak reminders sent: ${sentCount}/${messages.length}`);
  }
);

// ── F5: validateXPUpdate ──────────────────────────────────────────────────────

export const validateXPUpdate = onDocumentUpdated(
  {
    document: "users/{userId}/profile/{profileId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data?.before as DocumentSnapshot | undefined;
    const after = event.data?.after as DocumentSnapshot | undefined;

    if (!before || !after) return;

    const beforeData = before.data() as Partial<UserProfile> | undefined;
    const afterData = after.data() as Partial<UserProfile> | undefined;

    if (!beforeData || !afterData) return;

    const xpBefore = beforeData.weeklyXp ?? 0;
    const xpAfter = afterData.weeklyXp ?? 0;
    const delta = xpAfter - xpBefore;

    if (delta > 500) {
      logger.warn(
        `Suspicious XP update: userId=${event.params.userId}, ` +
        `delta=${delta} (${xpBefore} → ${xpAfter})`
      );

      await after.ref.update({
        weeklyXp: xpBefore,
        suspiciousActivity: true,
        suspiciousActivityAt: Date.now(),
      });
    }
  }
);