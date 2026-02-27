"use strict";
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
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateXPUpdate = exports.sendStreakReminder = exports.checkStreaks = exports.calculateWeeklyLeaderboard = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const v2_1 = require("firebase-functions/v2");
// ── Init ──────────────────────────────────────────────────────────────────────
admin.initializeApp();
const db = admin.firestore();
// ── Helper: today date string ─────────────────────────────────────────────────
function todayString() {
    return new Date().toISOString().slice(0, 10); // YYYY-MM-DD
}
function yesterdayString() {
    const d = new Date();
    d.setDate(d.getDate() - 1);
    return d.toISOString().slice(0, 10);
}
/** ISO week identifier: "2025-W04" */
function currentWeekId() {
    const now = new Date();
    const jan4 = new Date(now.getFullYear(), 0, 4);
    const dayOfYear = Math.floor((now.getTime() - new Date(now.getFullYear(), 0, 0).getTime()) /
        86400000);
    const weekNum = Math.ceil((dayOfYear + jan4.getDay()) / 7);
    return `${now.getFullYear()}-W${String(weekNum).padStart(2, "0")}`;
}
// ── F1: calculateWeeklyLeaderboard ────────────────────────────────────────────
//
// Pazartesi 00:01 UTC'de:
//   1. Tüm users/*/profile dökümanlarından weeklyXp topla
//   2. weeklyXp azalan → rank ata
//   3. leaderboard/weekly/{weekId} koleksiyonuna yaz (top 100)
//   4. Tüm kullanıcıların weeklyXp → 0 sıfırla
exports.calculateWeeklyLeaderboard = (0, scheduler_1.onSchedule)({
    schedule: "1 0 * * 1", // Pazartesi 00:01 UTC
    timeZone: "UTC",
    region: "us-central1",
}, async () => {
    v2_1.logger.info("calculateWeeklyLeaderboard started");
    const weekId = currentWeekId();
    const profilesSnap = await db.collectionGroup("profile").get();
    const entries = [];
    for (const doc of profilesSnap.docs) {
        const data = doc.data();
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
        const leaderboardEntry = {
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
    v2_1.logger.info(`Leaderboard written: ${top100.length} entries for ${weekId}`);
});
// ── F2: checkStreaks ──────────────────────────────────────────────────────────
//
// Her gün 03:00 UTC:
//   lastActiveDate < dün olan kullanıcıların streak = 0
exports.checkStreaks = (0, scheduler_1.onSchedule)({
    schedule: "0 3 * * *",
    timeZone: "UTC",
    region: "us-central1",
}, async () => {
    v2_1.logger.info("checkStreaks started");
    const yesterday = yesterdayString();
    const profilesSnap = await db.collectionGroup("profile").get();
    const batch = db.batch();
    let resetCount = 0;
    for (const doc of profilesSnap.docs) {
        const data = doc.data();
        const lastActive = data.lastActiveDate ?? "";
        const streak = data.streak ?? 0;
        // Dün aktif olmayan ve streaki olan kullanıcılar sıfırlanır
        if (streak > 0 && lastActive < yesterday) {
            batch.update(doc.ref, { streak: 0 });
            resetCount++;
        }
    }
    await batch.commit();
    v2_1.logger.info(`Streaks reset: ${resetCount} users`);
});
// ── F3: sendStreakReminder ────────────────────────────────────────────────────
//
// Her gün 18:00 UTC:
//   streak > 0 AND lastActiveDate < bugün olan kullanıcılara FCM push
exports.sendStreakReminder = (0, scheduler_1.onSchedule)({
    schedule: "0 18 * * *",
    timeZone: "UTC",
    region: "us-central1",
}, async () => {
    v2_1.logger.info("sendStreakReminder started");
    const today = todayString();
    const profilesSnap = await db.collectionGroup("profile").get();
    const messaging = admin.messaging();
    let sentCount = 0;
    for (const doc of profilesSnap.docs) {
        const data = doc.data();
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
            }
            catch (err) {
                v2_1.logger.warn(`FCM send failed for uid ${data.uid}:`, err);
                // Geçersiz token → temizle
                if (err.code ===
                    "messaging/registration-token-not-registered") {
                    await doc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
                }
            }
        }
    }
    v2_1.logger.info(`Streak reminders sent: ${sentCount}`);
});
// ── F4: validateXPUpdate ──────────────────────────────────────────────────────
//
// Firestore trigger: users/{userId}/profile/{profileId} onUpdate
//   weeklyXp delta > 500 → revert + suspiciousActivity = true
exports.validateXPUpdate = (0, firestore_1.onDocumentUpdated)({
    document: "users/{userId}/profile/{profileId}",
    region: "us-central1",
}, async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!before || !after)
        return;
    const beforeData = before.data();
    const afterData = after.data();
    if (!beforeData || !afterData)
        return;
    const xpBefore = beforeData.weeklyXp ?? 0;
    const xpAfter = afterData.weeklyXp ?? 0;
    const delta = xpAfter - xpBefore;
    // Blueprint: delta > 500 → şüpheli aktivite
    if (delta > 500) {
        v2_1.logger.warn(`Suspicious XP update: userId=${event.params.userId}, ` +
            `delta=${delta} (${xpBefore} → ${xpAfter})`);
        // Eski değere döndür + suspiciousActivity flag koy
        await after.ref.update({
            weeklyXp: xpBefore,
            suspiciousActivity: true,
            suspiciousActivityAt: Date.now(),
        });
    }
});
//# sourceMappingURL=index.js.map