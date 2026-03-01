// lib/firebase/firestore/leaderboard_service.dart
//
// FAZ 4 FIX:
//   F4-01: users/{uid} root dokümanına weekId alanı eklendi
//   F4-02: updateUserXP() → yeni hafta kontrolü + weeklyXp sıfırlama
//   F4-03: getWeeklyLeaderboard() → users collection query (Cloud Function gereksiz)
//   F4-04: getUserRank() → leaderboard listesinden pozisyon hesapla
//
// Firestore yapısı:
//   users/{uid}  ← root level doküman (leaderboard sorgusu için)
//     weeklyXp: number
//     totalXp: number
//     displayName: string
//     photoUrl: string
//     weekId: "2026-W09"  ← her XP güncellemesinde set edilir
//     lastActiveDate: "2026-02-28"
//
// NOT: users/{uid}/profile/main hala detaylı profil için kullanılır (auth service).
//      Root doküman leaderboard + XP sorguları içindir.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/week_id_helper.dart';

class LeaderboardService {
  LeaderboardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ── Leaderboard okuma (F4-03) ───────────────────────────────────────────

  /// Haftalık top 100 listeyi users koleksiyonundan döndür.
  ///
  /// Cloud Function GEREKMEZ — doğrudan users/{uid} dokümanlarını sorgular.
  /// [weekId]: "2026-W09" formatında ISO week ID.
  ///
  /// Firestore composite index gerekli:
  ///   Collection: users | weekId ASC, weeklyXp DESC
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard(String weekId) async {
    final snap = await _firestore
        .collection('users')
        .where('weekId', isEqualTo: weekId)
        .where('weeklyXp', isGreaterThan: 0)
        .orderBy('weeklyXp', descending: true)
        .limit(100)
        .get();

    final entries = <LeaderboardEntry>[];
    for (var i = 0; i < snap.docs.length; i++) {
      final doc = snap.docs[i];
      entries.add(LeaderboardEntry.fromMap(
        doc.id,
        doc.data(),
        rank: i + 1, // Sıralama pozisyondan hesaplanır
      ));
    }
    return entries;
  }

  /// Kullanıcının haftalık sırası.
  ///
  /// Leaderboard listesinde varsa oradan döner.
  /// Yoksa weeklyXp'den büyük kaç kullanıcı var sayarak hesaplar.
  Future<LeaderboardEntry?> getUserRank(String userId, String weekId) async {
    // Önce kullanıcının root dokümanını oku
    final userDoc = await _firestore.doc('users/$userId').get();
    if (!userDoc.exists || userDoc.data() == null) return null;

    final data = userDoc.data()!;
    final userWeekId = data['weekId'] as String?;
    final weeklyXp = (data['weeklyXp'] as num?)?.toInt() ?? 0;

    // Bu hafta aktif değilse veya XP = 0 ise rank yok
    if (userWeekId != weekId || weeklyXp <= 0) return null;

    // Kullanıcının üstünde kaç kişi var?
    final aboveSnap = await _firestore
        .collection('users')
        .where('weekId', isEqualTo: weekId)
        .where('weeklyXp', isGreaterThan: weeklyXp)
        .count()
        .get();

    final rank = (aboveSnap.count ?? 0) + 1;

    return LeaderboardEntry(
      uid: userId,
      displayName: (data['displayName'] as String?) ?? 'Anonim',
      photoUrl: data['photoUrl'] as String?,
      weeklyXp: weeklyXp,
      totalXp: (data['totalXp'] as num?)?.toInt() ?? 0,
      rank: rank,
    );
  }

  // ── XP güncelleme (F4-02) ───────────────────────────────────────────────

  /// Session tamamlandığında hem root users/{uid} hem profile dokümanına XP yaz.
  ///
  /// Hafta değişmişse weeklyXp sıfırlanır ve yeni weekId set edilir.
  /// FieldValue.increment — atomik, race condition'a karşı güvenli.
  ///
  /// Root doküman: leaderboard sorgusu için (weekId + weeklyXp indexed)
  /// Profile doküman: detaylı profil bilgileri için
  Future<void> updateUserXP({
    required String uid,
    required int xpDelta,
    String? displayName,
    String? photoUrl,
  }) async {
    if (xpDelta <= 0) return;

    final currentWeekId = WeekIdHelper.currentWeekId();
    final rootRef = _firestore.doc('users/$uid');
    final profileRef = _firestore.doc('users/$uid/profile/main');

    // Mevcut weekId'yi kontrol et — hafta değişti mi?
    final snap = await rootRef.get();
    final storedWeekId = snap.data()?['weekId'] as String?;
    final isNewWeek = storedWeekId != currentWeekId;

    // Root doküman: leaderboard query için
    final rootData = <String, dynamic>{
      'totalXp': FieldValue.increment(xpDelta),
      'weeklyXp': isNewWeek ? xpDelta : FieldValue.increment(xpDelta),
      'weekId': currentWeekId,
      'uid': uid,
      'lastActiveDate': _todayString(),
    };

    // displayName varsa ekle (ilk XP güncellemesinde profil bilgisi de yaz)
    if (displayName != null) rootData['displayName'] = displayName;
    if (photoUrl != null) rootData['photoUrl'] = photoUrl;

    // displayName hiç yoksa default ekle
    if (!snap.exists || snap.data()?['displayName'] == null) {
      rootData['displayName'] ??= 'Anonim';
    }

    await rootRef.set(rootData, SetOptions(merge: true));

    // Profile doküman: auth service ile uyumlu
    await profileRef.set(
      {
        'totalXp': FieldValue.increment(xpDelta),
        'weeklyXp': isNewWeek ? xpDelta : FieldValue.increment(xpDelta),
        'lastActiveDate': _todayString(),
      },
      SetOptions(merge: true),
    );
  }

  /// Günlük streak kontrolü için lastActiveDate güncelle.
  Future<void> updateLastActive(String uid) async {
    final batch = _firestore.batch();

    batch.set(
      _firestore.doc('users/$uid'),
      {'lastActiveDate': _todayString(), 'uid': uid},
      SetOptions(merge: true),
    );
    batch.set(
      _firestore.doc('users/$uid/profile/main'),
      {'lastActiveDate': _todayString()},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String _todayString() => DateTime.now().toIso8601String().substring(0, 10);
}

// ── Data class ────────────────────────────────────────────────────────────────

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.weeklyXp,
    this.totalXp = 0,
    required this.rank,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final int weeklyXp;
  final int totalXp;
  final int rank;

  factory LeaderboardEntry.fromMap(
    String uid,
    Map<String, dynamic> map, {
    int rank = 0,
  }) {
    return LeaderboardEntry(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'Anonim',
      photoUrl: map['photoUrl'] as String?,
      weeklyXp: (map['weeklyXp'] as num?)?.toInt() ?? 0,
      totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
      rank: rank > 0 ? rank : (map['rank'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() => 'LeaderboardEntry(rank=$rank, uid=$uid, xp=$weeklyXp)';
}
