/**
 * functions/src/index.ts
 *
 * T-18: Cloud Functions Deploy (4 Function)
 * Blueprint F.5:
 *   calculateWeeklyLeaderboard  — Cron: Pazartesi 00:01 UTC
 *   checkStreaks                — Cron: Her gün 03:00 UTC
 *   sendStreakReminder          — Cron: Her gün 18:00 UTC
 *   validateXPUpdate            — Firestore onUpdate trigger
 *
 * Deploy:
 *   cd functions && npm install && npm run build
 *   firebase deploy --only functions
 *
 * Test (emulator):
 *   firebase emulators:start --only functions,firestore
 *   cd functions && npm test
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
  lastActiveDate?: string; // YYYY-MM-DD
  fcmToken?: string;
}

interface LeaderboardEntry {
  uid: string;
  displayName: string;
  weeklyXp: number;
  rank: number;
  updatedAt: number;
}

// ── Helper: today date string ─────────────────────────────────────────────────

function todayString(): string {
  return new Date().toISOString().slice(0, 10); // YYYY-MM-DD
}

function yesterdayString(): string {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return d.toISOString().slice(0, 10);
}

/** ISO week identifier: "2025-W04" */
function currentWeekId(): string {
  const now = new Date();
  const jan4 = new Date(now.getFullYear(), 0, 4);
  const dayOfYear =
    Math.floor((now.getTime() - new Date(now.getFullYear(), 0, 0).getTime()) /
      86_400_000);
  const weekNum = Math.ceil(
    (dayOfYear + jan4.getDay()) / 7
  );
  return `${now.getFullYear()}-W${String(weekNum).padStart(2, "0")}`;
}

// ── F1: calculateWeeklyLeaderboard ────────────────────────────────────────────
//
// Pazartesi 00:01 UTC'de:
//   1. Tüm users/*/profile dökümanlarından weeklyXp topla
//   2. weeklyXp azalan → rank ata
//   3. leaderboard/weekly/{weekId} koleksiyonuna yaz (top 100)
//   4. Tüm kullanıcıların weeklyXp → 0 sıfırla

export const calculateWeeklyLeaderboard = onSchedule(
  {
    schedule: "1 0 * * 1", // Pazartesi 00:01 UTC
    timeZone: "UTC",
    region: "us-central1",
  },
  async () => {
    logger.info("calculateWeeklyLeaderboard started");

    const weekId = currentWeekId();
    const profilesSnap = await db.collectionGroup("profile").get();

    const entries: { uid: string; displayName: string; weeklyXp: number }[] =
      [];

    for (const doc of profilesSnap.docs) {
      const data = doc.data() as Partial<UserProfile>;
      if ((data.weeklyXp ?? 0) > 0) {
        entries.push({
          uid: data.uid ?? doc.ref.parent.parent?.id ?? "",
          displayName: data.displayName ?? "Anonymous",
          weeklyXp: data.weeklyXp ?? 0,
        });
      }
    }

    // Sort descending by weeklyXp
    entries.sort((a, b) => b.weeklyXp - a.weeklyXp);

    // Write top 100 to leaderboard
    const top100 = entries.slice(0, 100);
    const batch = db.batch();
    const weekRef = db.collection("leaderboard").doc("weekly")
      .collection(weekId);

    // Clear previous week entries first
    const prevSnap = await weekRef.get();
    for (const doc of prevSnap.docs) {
      batch.delete(doc.ref);
    }

    // Write new rankings
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

    // Reset weeklyXp for all users
    for (const doc of profilesSnap.docs) {
      batch.update(doc.ref, { weeklyXp: 0 });
    }

    await batch.commit();
    logger.info(`Leaderboard written: ${top100.length} entries for ${weekId}`);
  }
);

// ── F2: checkStreaks ──────────────────────────────────────────────────────────
//
// Her gün 03:00 UTC:
//   lastActiveDate < dün olan kullanıcıların streak = 0

export const checkStreaks = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "UTC",
    region: "us-central1",
  },
  async () => {
    logger.info("checkStreaks started");

    const yesterday = yesterdayString();
    const profilesSnap = await db.collectionGroup("profile").get();

    const batch = db.batch();
    let resetCount = 0;

    for (const doc of profilesSnap.docs) {
      const data = doc.data() as Partial<UserProfile>;
      const lastActive = data.lastActiveDate ?? "";
      const streak = data.streak ?? 0;

      // Dün aktif olmayan ve streaki olan kullanıcılar sıfırlanır
      if (streak > 0 && lastActive < yesterday) {
        batch.update(doc.ref, { streak: 0 });
        resetCount++;
      }
    }

    await batch.commit();
    logger.info(`Streaks reset: ${resetCount} users`);
  }
);

// ── F3: sendStreakReminder ────────────────────────────────────────────────────
//
// Her gün 18:00 UTC:
//   streak > 0 AND lastActiveDate < bugün olan kullanıcılara FCM push

export const sendStreakReminder = onSchedule(
  {
    schedule: "0 18 * * *",
    timeZone: "UTC",
    region: "us-central1",
  },
  async () => {
    logger.info("sendStreakReminder started");

    const today = todayString();
    const profilesSnap = await db.collectionGroup("profile").get();

    const messaging = admin.messaging();
    let sentCount = 0;

    for (const doc of profilesSnap.docs) {
      const data = doc.data() as Partial<UserProfile>;
      const streak = data.streak ?? 0;
      const lastActive = data.lastActiveDate ?? "";
      const fcmToken = data.fcmToken;

      // streak aktif ama bugün gelmemiş → reminder gönder
      if (streak > 0 && lastActive < today && fcmToken) {
        try {
          await messaging.send({
            token: fcmToken,
            notification: {
              title: "🔥 Serinizi Koruyun!",
              body: `${streak} günlük seriniz tehlikede. Bugün çalışmayı unutmayın!`,
            },
            data: {
              route: "/study_zone",
              type: "streak_reminder",
            },
            android: {
              priority: "normal",
              notification: {
                channelId: "streak_reminder",
              },
            },
            apns: {
              payload: {
                aps: {
                  badge: 1,
                },
              },
            },
          });
          sentCount++;
        } catch (err) {
          logger.warn(`FCM send failed for uid ${data.uid}:`, err);
          // Geçersiz token → temizle
          if (
            (err as { code?: string }).code ===
            "messaging/registration-token-not-registered"
          ) {
            await doc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
          }
        }
      }
    }

    logger.info(`Streak reminders sent: ${sentCount}`);
  }
);

// ── F4: validateXPUpdate ──────────────────────────────────────────────────────
//
// Firestore trigger: users/{userId}/profile/{profileId} onUpdate
//   weeklyXp delta > 500 → revert + suspiciousActivity = true

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

    // Blueprint: delta > 500 → şüpheli aktivite
    if (delta > 500) {
      logger.warn(
        `Suspicious XP update: userId=${event.params.userId}, ` +
        `delta=${delta} (${xpBefore} → ${xpAfter})`
      );

      // Eski değere döndür + suspiciousActivity flag koy
      await after.ref.update({
        weeklyXp: xpBefore,
        suspiciousActivity: true,
        suspiciousActivityAt: Date.now(),
      });
    }
  }
);