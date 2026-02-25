// lib/firebase/firestore/leaderboard_service.dart
//
// T-20: LeaderboardService — Firestore leaderboard okuma + XP güncelleme
// Blueprint:
//   getWeeklyLeaderboard(weekId) → top 100
//   getUserRank(userId, weekId)  → kullanıcının sırası
//   updateUserXP(uid, xpDelta)   → profile.totalXp + weeklyXp atomik artış

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore leaderboard koleksiyonu: leaderboard/weekly/{weekId}/{uid}
/// XP profil koleksiyonu: users/{uid}/profile/main
class LeaderboardService {
  LeaderboardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ── Leaderboard okuma ─────────────────────────────────────────────────────

  /// Haftalık top 100 listeyi döndür.
  /// [weekId]: "2025-W04" formatında ISO week ID.
  /// Cloud Function (calculateWeeklyLeaderboard) tarafından yazılır.
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard(String weekId) async {
    final snap = await _firestore
        .collection('leaderboard')
        .doc('weekly')
        .collection(weekId)
        .orderBy('rank')
        .limit(100)
        .get();

    return snap.docs
        .map((d) => LeaderboardEntry.fromMap(d.id, d.data()))
        .toList();
  }

  /// Kullanıcının haftalık sırası.
  /// Firestore'da kaydı yoksa null döner (top 100 dışında).
  Future<LeaderboardEntry?> getUserRank(String userId, String weekId) async {
    final doc = await _firestore
        .collection('leaderboard')
        .doc('weekly')
        .collection(weekId)
        .doc(userId)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return LeaderboardEntry.fromMap(doc.id, doc.data()!);
  }

  // ── XP güncelleme ─────────────────────────────────────────────────────────

  /// Session tamamlandığında Firestore profile'a XP yaz.
  /// Online ise: doğrudan increment.
  /// Offline: SyncQueue'ya bırakılır (CompleteSession use case'de).
  ///
  /// FieldValue.increment — atomik, race condition'a karşı güvenli.
  Future<void> updateUserXP(String uid, int xpDelta) async {
    if (xpDelta <= 0) return;

    final ref = _firestore.doc('users/$uid/profile/main');
    await ref.set(
      {
        'totalXp': FieldValue.increment(xpDelta),
        'weeklyXp': FieldValue.increment(xpDelta),
        'lastActiveDate': _todayString(),
        'uid': uid,
      },
      SetOptions(merge: true),
    );
  }

  /// Günlük streak kontrolü için lastActiveDate güncelle.
  Future<void> updateLastActive(String uid) async {
    await _firestore.doc('users/$uid/profile/main').set(
      {'lastActiveDate': _todayString(), 'uid': uid},
      SetOptions(merge: true),
    );
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String _todayString() => DateTime.now().toIso8601String().substring(0, 10);
}

// ── Data class ────────────────────────────────────────────────────────────────

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.weeklyXp,
    required this.rank,
  });

  final String uid;
  final String displayName;
  final int weeklyXp;
  final int rank;

  factory LeaderboardEntry.fromMap(String uid, Map<String, dynamic> map) {
    return LeaderboardEntry(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'Anonymous',
      weeklyXp: (map['weeklyXp'] as num?)?.toInt() ?? 0,
      rank: (map['rank'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() => 'LeaderboardEntry(rank=$rank, uid=$uid, xp=$weeklyXp)';
}
