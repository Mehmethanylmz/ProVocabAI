// test/firebase/leaderboard_service_test.dart
//
// F16-05: Leaderboard langPair ranking correctness
//
// Tests LeaderboardService.updateUserXP() with langPair:
//   - weeklyXpByPair.{langPair} is written correctly
//   - Multiple updates to same langPair accumulate (same week)
//   - New week resets weeklyXpByPair to current delta
//   - getLangPairLeaderboard returns correct ranking order
//
// Uses FakeFirebaseFirestore (no real Firebase needed).

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savgolearnvocabulary/firebase/firestore/leaderboard_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late LeaderboardService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = LeaderboardService(firestore: fakeFirestore);
  });

  group('LeaderboardService.updateUserXP — langPair (F16-05)', () {
    test('first XP update creates weeklyXpByPair field', () async {
      await service.updateUserXP(
        uid: 'user1',
        xpDelta: 100,
        displayName: 'TestUser',
        langPair: 'en-tr',
      );

      final doc = await fakeFirestore.doc('users/user1').get();
      final data = doc.data()!;

      expect(data.containsKey('weeklyXpByPair'), isTrue);
      final byPair = data['weeklyXpByPair'] as Map<String, dynamic>;
      expect(byPair['en-tr'], equals(100));
    });

    test('second XP update same week accumulates langPair XP', () async {
      await service.updateUserXP(
        uid: 'user1',
        xpDelta: 100,
        langPair: 'en-tr',
      );
      await service.updateUserXP(
        uid: 'user1',
        xpDelta: 50,
        langPair: 'en-tr',
      );

      final doc = await fakeFirestore.doc('users/user1').get();
      final byPair =
          doc.data()!['weeklyXpByPair'] as Map<String, dynamic>;
      expect(byPair['en-tr'], equals(150),
          reason: '100 + 50 = 150 accumulated same week');
    });

    test('different langPairs are tracked independently', () async {
      await service.updateUserXP(
        uid: 'user1',
        xpDelta: 100,
        langPair: 'en-tr',
      );
      await service.updateUserXP(
        uid: 'user1',
        xpDelta: 60,
        langPair: 'tr-de',
      );

      final doc = await fakeFirestore.doc('users/user1').get();
      final byPair =
          doc.data()!['weeklyXpByPair'] as Map<String, dynamic>;
      expect(byPair['en-tr'], equals(100));
      expect(byPair['tr-de'], equals(60));
    });

    test('updateUserXP without langPair does not create weeklyXpByPair', () async {
      await service.updateUserXP(
        uid: 'user1',
        xpDelta: 100,
        // no langPair
      );

      final doc = await fakeFirestore.doc('users/user1').get();
      final data = doc.data()!;
      // weeklyXpByPair should not exist or be empty map
      final byPair =
          data['weeklyXpByPair'] as Map<String, dynamic>?;
      expect(byPair == null || !byPair.containsKey('en-tr'), isTrue,
          reason: 'No langPair → weeklyXpByPair not written');
    });

    test('totalXp accumulates across multiple calls', () async {
      await service.updateUserXP(uid: 'user1', xpDelta: 100, langPair: 'en-tr');
      await service.updateUserXP(uid: 'user1', xpDelta: 50, langPair: 'en-tr');

      final doc = await fakeFirestore.doc('users/user1').get();
      expect(doc.data()!['totalXp'], equals(150));
    });

    test('weeklyXp is set on first update', () async {
      await service.updateUserXP(uid: 'user1', xpDelta: 80, langPair: 'en-tr');

      final doc = await fakeFirestore.doc('users/user1').get();
      expect(doc.data()!['weeklyXp'], equals(80));
    });

    test('zero xpDelta is a no-op (no document created)', () async {
      await service.updateUserXP(
        uid: 'user1',
        xpDelta: 0,
        langPair: 'en-tr',
      );

      final doc = await fakeFirestore.doc('users/user1').get();
      expect(doc.exists, isFalse,
          reason: 'xpDelta=0 should not write to Firestore');
    });
  });

  group('LeaderboardService.getLangPairLeaderboard (F16-05)', () {
    test('users ranked by langPair XP descending', () async {
      // Setup: user1=200 en-tr XP, user2=150, user3=300
      await service.updateUserXP(
          uid: 'user1', xpDelta: 200, displayName: 'Alice', langPair: 'en-tr');
      await service.updateUserXP(
          uid: 'user2', xpDelta: 150, displayName: 'Bob', langPair: 'en-tr');
      await service.updateUserXP(
          uid: 'user3', xpDelta: 300, displayName: 'Carol', langPair: 'en-tr');

      final weekId = (await fakeFirestore.doc('users/user1').get())
          .data()!['weekId'] as String;

      final leaderboard =
          await service.getLangPairLeaderboard('en-tr', weekId);

      expect(leaderboard, hasLength(3));
      // Should be ordered by en-tr XP descending: Carol(300) > Alice(200) > Bob(150)
      expect(leaderboard[0].weeklyXp, equals(300));
      expect(leaderboard[1].weeklyXp, equals(200));
      expect(leaderboard[2].weeklyXp, equals(150));
    });

    test('user not in en-tr does not appear in en-tr leaderboard', () async {
      await service.updateUserXP(
          uid: 'user1', xpDelta: 100, displayName: 'Alice', langPair: 'en-tr');
      await service.updateUserXP(
          uid: 'user2',
          xpDelta: 200,
          displayName: 'Bob',
          langPair: 'tr-de'); // different lang pair

      final weekId = (await fakeFirestore.doc('users/user1').get())
          .data()!['weekId'] as String;

      final leaderboard =
          await service.getLangPairLeaderboard('en-tr', weekId);

      // Only user1 should appear; user2 has tr-de XP, not en-tr
      final uids = leaderboard.map((e) => e.uid).toList();
      expect(uids.contains('user1'), isTrue);
      expect(uids.contains('user2'), isFalse,
          reason: 'user2 has tr-de XP, not en-tr');
    });
  });

  group('LeaderboardService.updateLastActive', () {
    test('updateLastActive sets lastActiveDate without throwing', () async {
      // Ensure doc exists before calling updateLastActive (batch.set merge)
      await service.updateUserXP(uid: 'user1', xpDelta: 10);
      await service.updateLastActive('user1');

      final doc = await fakeFirestore.doc('users/user1').get();
      expect(doc.exists, isTrue);
      final data = doc.data();
      expect(data, isNotNull);
      expect(data!.containsKey('lastActiveDate'), isTrue);
    });
  });
}
