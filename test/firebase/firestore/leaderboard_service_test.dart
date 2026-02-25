// test/firebase/firestore/leaderboard_service_test.dart
//
// T-20 Acceptance Criteria:
//   AC: updateUserXP → profile.weeklyXp arttı
//   AC: updateUserXP → profile.totalXp arttı
//   AC: getWeeklyLeaderboard → entries rank sıralı döner
//   AC: getUserRank → kullanıcının sırası doğru
//   AC: getUserRank → top100 dışındaki kullanıcı null döner
//   AC: updateUserXP delta<=0 → Firestore'a yazılmaz
//
// Çalıştır: flutter test test/firebase/firestore/leaderboard_service_test.dart

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pratikapp/firebase/firestore/leaderboard_service.dart';
import 'package:pratikapp/core/utils/week_id_helper.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late LeaderboardService service;
  const weekId = '2025-W04';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = LeaderboardService(firestore: fakeFirestore);
  });

  // ── updateUserXP ──────────────────────────────────────────────────────────

  group('updateUserXP', () {
    test('AC: weeklyXp arttı', () async {
      await service.updateUserXP('user-alice', 50);

      final doc =
          await fakeFirestore.doc('users/user-alice/profile/main').get();
      expect(doc.data()?['weeklyXp'], 50);
    });

    test('AC: totalXp arttı', () async {
      await service.updateUserXP('user-bob', 100);

      final doc = await fakeFirestore.doc('users/user-bob/profile/main').get();
      expect(doc.data()?['totalXp'], 100);
    });

    test('AC: birden fazla session → XP birikir', () async {
      await service.updateUserXP('user-charlie', 30);
      await service.updateUserXP('user-charlie', 70);

      final doc =
          await fakeFirestore.doc('users/user-charlie/profile/main').get();
      // fake_cloud_firestore FieldValue.increment'i destekler
      expect(doc.data()?['weeklyXp'], 100);
      expect(doc.data()?['totalXp'], 100);
    });

    test('AC: delta<=0 → Firestore\'a yazılmaz', () async {
      await service.updateUserXP('user-zero', 0);
      await service.updateUserXP('user-zero', -10);

      final doc = await fakeFirestore.doc('users/user-zero/profile/main').get();
      expect(doc.exists, isFalse, reason: 'delta<=0 → hiçbir şey yazılmamalı');
    });

    test('AC: uid ve lastActiveDate profile\'a eklenir', () async {
      await service.updateUserXP('user-date-test', 20);

      final doc =
          await fakeFirestore.doc('users/user-date-test/profile/main').get();
      expect(doc.data()?['uid'], 'user-date-test');
      expect(doc.data()?['lastActiveDate'], isNotNull);
    });
  });

  // ── getWeeklyLeaderboard ──────────────────────────────────────────────────

  group('getWeeklyLeaderboard', () {
    Future<void> _seedLeaderboard() async {
      final weekRef = fakeFirestore
          .collection('leaderboard')
          .doc('weekly')
          .collection(weekId);

      await weekRef.doc('uid-1').set({
        'uid': 'uid-1',
        'displayName': 'Alice',
        'weeklyXp': 500,
        'rank': 1,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      await weekRef.doc('uid-2').set({
        'uid': 'uid-2',
        'displayName': 'Bob',
        'weeklyXp': 300,
        'rank': 2,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      await weekRef.doc('uid-3').set({
        'uid': 'uid-3',
        'displayName': 'Charlie',
        'weeklyXp': 150,
        'rank': 3,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }

    test('AC: entries rank sıralı döner', () async {
      await _seedLeaderboard();

      final entries = await service.getWeeklyLeaderboard(weekId);

      expect(entries.length, 3);
      expect(entries[0].rank, 1);
      expect(entries[0].displayName, 'Alice');
      expect(entries[1].rank, 2);
      expect(entries[2].rank, 3);
    });

    test('AC: weeklyXp doğru map\'lendi', () async {
      await _seedLeaderboard();

      final entries = await service.getWeeklyLeaderboard(weekId);
      expect(entries[0].weeklyXp, 500);
      expect(entries[1].weeklyXp, 300);
    });

    test('AC: boş leaderboard → boş liste döner', () async {
      final entries = await service.getWeeklyLeaderboard('2025-W99');
      expect(entries.isEmpty, isTrue);
    });
  });

  // ── getUserRank ───────────────────────────────────────────────────────────

  group('getUserRank', () {
    test('AC: top100\'deki kullanıcı sırası doğru', () async {
      await fakeFirestore
          .collection('leaderboard')
          .doc('weekly')
          .collection(weekId)
          .doc('uid-alice')
          .set({
        'uid': 'uid-alice',
        'displayName': 'Alice',
        'weeklyXp': 400,
        'rank': 1
      });

      final entry = await service.getUserRank('uid-alice', weekId);

      expect(entry, isNotNull);
      expect(entry!.rank, 1);
      expect(entry.weeklyXp, 400);
    });

    test('AC: top100 dışındaki kullanıcı → null döner', () async {
      final entry = await service.getUserRank('uid-not-in-list', weekId);
      expect(entry, isNull);
    });
  });

  // ── WeekIdHelper ──────────────────────────────────────────────────────────

  group('WeekIdHelper', () {
    test('AC: format YYYY-Www', () {
      final id = WeekIdHelper.currentWeekId(DateTime.utc(2025, 1, 6));
      expect(id, matches(RegExp(r'^\d{4}-W\d{2}$')));
    });

    test('AC: Pazartesi 2025-01-06 → 2025-W02', () {
      final id = WeekIdHelper.currentWeekId(DateTime.utc(2025, 1, 6));
      expect(id, '2025-W02');
    });
  });
}
