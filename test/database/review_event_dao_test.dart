// test/database/review_event_dao_test.dart
//
// F16-03: Dashboard stats consistency with review_events table
// F16-06: Heatmap daily data correctness
//
// Tests ReviewEventDao methods:
//   - getSessionStats: total/correct/wrong/avgResponseMs consistency
//   - getDailyActivityForRange: groups events by day, correct counts per day

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savgolearnvocabulary/database/app_database.dart';

AppDatabase _createTestDb() =>
    AppDatabase.forTesting(NativeDatabase.memory());

WordsCompanion _word(int id) => WordsCompanion.insert(
      id: Value(id),
      partOfSpeech: const Value('noun'),
      categoriesJson: const Value('["a1"]'),
      contentJson: const Value(
          '{"en":{"word":"test","meaning":"deneme"},"tr":{"word":"deneme","meaning":"test"}}'),
      sentencesJson: const Value(
          '{"beginner":{"en":"This is a test.","tr":"Bu bir deneme."}}'),
      difficultyRank: const Value(1),
      sourceLang: const Value('tr'),
      targetLang: const Value('en'),
    );

/// Insert a review event with given parameters.
ReviewEventsCompanion _event({
  required String id,
  required int wordId,
  required String sessionId,
  required bool wasCorrect,
  required int reviewedAt,
  String rating = 'good',
  int responseMs = 1200,
}) =>
    ReviewEventsCompanion.insert(
      id: id,
      wordId: wordId,
      sessionId: sessionId,
      targetLang: 'en',
      rating: rating,
      responseMs: responseMs,
      mode: 'mcq',
      wasCorrect: wasCorrect,
      stabilityBefore: 0.5,
      stabilityAfter: 3.1,
      reviewedAt: reviewedAt,
    );

void main() {
  late AppDatabase db;

  setUp(() async {
    db = _createTestDb();
    // Insert test words
    for (var i = 1; i <= 5; i++) {
      await db.wordDao.insertWordRaw(_word(i));
    }
    // Insert test session
    await db.into(db.sessions).insert(SessionsCompanion.insert(
          id: 'session-001',
          targetLang: 'en',
          startedAt: DateTime.now().millisecondsSinceEpoch,
        ));
  });

  tearDown(() => db.close());

  // ── F16-03: Dashboard stats consistency ──────────────────────────────────

  group('ReviewEventDao.getSessionStats (F16-03)', () {
    test('correct total / correct / wrong counts from 5 correct + 3 wrong',
        () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Insert 5 correct events
      for (var i = 0; i < 5; i++) {
        await db.into(db.reviewEvents).insert(_event(
              id: 'e-correct-$i',
              wordId: (i % 5) + 1,
              sessionId: 'session-001',
              wasCorrect: true,
              reviewedAt: now - (5 - i) * 1000,
              responseMs: 1000 + i * 100,
            ));
      }
      // Insert 3 wrong events
      for (var i = 0; i < 3; i++) {
        await db.into(db.reviewEvents).insert(_event(
              id: 'e-wrong-$i',
              wordId: (i % 5) + 1,
              sessionId: 'session-001',
              wasCorrect: false,
              rating: 'again',
              reviewedAt: now - i * 500,
              responseMs: 2000 + i * 200,
            ));
      }

      final stats =
          await db.reviewEventDao.getSessionStats('session-001');

      expect(stats['total'], equals(8));
      expect(stats['correct'], equals(5));
      expect(stats['wrong'], equals(3));
      expect(stats['total'],
          equals(stats['correct']! + stats['wrong']!),
          reason: 'total must equal correct + wrong');
    });

    test('empty session returns zeros', () async {
      await db.into(db.sessions).insert(SessionsCompanion.insert(
            id: 'session-empty',
            targetLang: 'en',
            startedAt: DateTime.now().millisecondsSinceEpoch,
          ));

      final stats =
          await db.reviewEventDao.getSessionStats('session-empty');
      expect(stats['total'], equals(0));
      expect(stats['correct'], equals(0));
      expect(stats['wrong'], equals(0));
    });

    test('avgResponseMs is reasonable average', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      // Insert 2 events with known response times: 1000ms + 3000ms → avg 2000ms
      await db.into(db.reviewEvents).insert(_event(
            id: 'e-avg-1',
            wordId: 1,
            sessionId: 'session-001',
            wasCorrect: true,
            reviewedAt: now - 2000,
            responseMs: 1000,
          ));
      await db.into(db.reviewEvents).insert(_event(
            id: 'e-avg-2',
            wordId: 2,
            sessionId: 'session-001',
            wasCorrect: false,
            reviewedAt: now - 1000,
            responseMs: 3000,
          ));

      final stats =
          await db.reviewEventDao.getSessionStats('session-001');
      expect(stats['avgResponseMs'], closeTo(2000, 1),
          reason: '(1000+3000)/2 = 2000ms');
    });

    test('getWrongEvents returns only wasCorrect=false', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.reviewEvents).insert(_event(
            id: 'e-right',
            wordId: 1,
            sessionId: 'session-001',
            wasCorrect: true,
            reviewedAt: now - 2000,
          ));
      await db.into(db.reviewEvents).insert(_event(
            id: 'e-wrong',
            wordId: 2,
            sessionId: 'session-001',
            wasCorrect: false,
            rating: 'again',
            reviewedAt: now - 1000,
          ));

      final wrongEvents =
          await db.reviewEventDao.getWrongEvents('session-001');
      expect(wrongEvents, hasLength(1));
      expect(wrongEvents.first.wasCorrect, isFalse);
      expect(wrongEvents.first.wordId, equals(2));
    });
  });

  // ── F16-06: Heatmap daily data correctness ───────────────────────────────

  group('ReviewEventDao.getDailyActivityForRange (F16-06)', () {
    test('events on 2 different days produce 2 map entries', () async {
      // Day 1: 3 events (2 correct, 1 wrong)
      // Day 2: 2 events (1 correct, 1 wrong)
      final day1 = DateTime(2026, 1, 10, 10, 0, 0).toUtc();
      final day2 = DateTime(2026, 1, 11, 10, 0, 0).toUtc();

      final events = [
        _event(
            id: 'e1',
            wordId: 1,
            sessionId: 'session-001',
            wasCorrect: true,
            reviewedAt: day1.millisecondsSinceEpoch),
        _event(
            id: 'e2',
            wordId: 2,
            sessionId: 'session-001',
            wasCorrect: true,
            reviewedAt:
                day1.add(const Duration(hours: 1)).millisecondsSinceEpoch),
        _event(
            id: 'e3',
            wordId: 3,
            sessionId: 'session-001',
            wasCorrect: false,
            rating: 'again',
            reviewedAt:
                day1.add(const Duration(hours: 2)).millisecondsSinceEpoch),
        _event(
            id: 'e4',
            wordId: 4,
            sessionId: 'session-001',
            wasCorrect: true,
            reviewedAt: day2.millisecondsSinceEpoch),
        _event(
            id: 'e5',
            wordId: 5,
            sessionId: 'session-001',
            wasCorrect: false,
            rating: 'again',
            reviewedAt:
                day2.add(const Duration(hours: 1)).millisecondsSinceEpoch),
      ];

      for (final e in events) {
        await db.into(db.reviewEvents).insert(e);
      }

      final fromMs =
          DateTime(2026, 1, 10).toUtc().millisecondsSinceEpoch;
      final toMs =
          DateTime(2026, 1, 12).toUtc().millisecondsSinceEpoch;

      final activity =
          await db.reviewEventDao.getDailyActivityForRange(fromMs, toMs);

      expect(activity, hasLength(2),
          reason: 'Should return 2 keys (one per day)');
      expect(activity.containsKey('2026-01-10'), isTrue);
      expect(activity.containsKey('2026-01-11'), isTrue);
    });

    test('day1 questionCount=3 correctCount=2', () async {
      final day1 = DateTime(2026, 2, 5, 9, 0, 0).toUtc();

      for (var i = 0; i < 3; i++) {
        await db.into(db.reviewEvents).insert(_event(
              id: 'e-day1-$i',
              wordId: (i % 5) + 1,
              sessionId: 'session-001',
              wasCorrect: i < 2, // first 2 correct, last 1 wrong
              reviewedAt:
                  day1.add(Duration(minutes: i * 10)).millisecondsSinceEpoch,
            ));
      }

      final fromMs =
          DateTime(2026, 2, 5).toUtc().millisecondsSinceEpoch;
      final toMs =
          DateTime(2026, 2, 6).toUtc().millisecondsSinceEpoch;

      final activity =
          await db.reviewEventDao.getDailyActivityForRange(fromMs, toMs);

      expect(activity['2026-02-05']?['questionCount'], equals(3));
      expect(activity['2026-02-05']?['correctCount'], equals(2));
    });

    test('events outside date range are excluded', () async {
      final inRange = DateTime(2026, 3, 1, 10, 0, 0).toUtc();
      final outOfRange = DateTime(2026, 3, 10, 10, 0, 0).toUtc();

      await db.into(db.reviewEvents).insert(_event(
            id: 'e-in',
            wordId: 1,
            sessionId: 'session-001',
            wasCorrect: true,
            reviewedAt: inRange.millisecondsSinceEpoch,
          ));
      await db.into(db.reviewEvents).insert(_event(
            id: 'e-out',
            wordId: 2,
            sessionId: 'session-001',
            wasCorrect: true,
            reviewedAt: outOfRange.millisecondsSinceEpoch,
          ));

      final fromMs =
          DateTime(2026, 3, 1).toUtc().millisecondsSinceEpoch;
      final toMs =
          DateTime(2026, 3, 2).toUtc().millisecondsSinceEpoch;

      final activity =
          await db.reviewEventDao.getDailyActivityForRange(fromMs, toMs);

      expect(activity.containsKey('2026-03-10'), isFalse,
          reason: 'Event on day 10 must be excluded');
      expect(activity.containsKey('2026-03-01'), isTrue);
    });

    test('empty range returns empty map', () async {
      final fromMs =
          DateTime(2025, 1, 1).toUtc().millisecondsSinceEpoch;
      final toMs =
          DateTime(2025, 1, 2).toUtc().millisecondsSinceEpoch;

      final activity =
          await db.reviewEventDao.getDailyActivityForRange(fromMs, toMs);

      expect(activity, isEmpty);
    });

    test('all-correct day has correctCount == questionCount', () async {
      final day = DateTime(2026, 4, 15, 8, 0, 0).toUtc();
      for (var i = 0; i < 5; i++) {
        await db.into(db.reviewEvents).insert(_event(
              id: 'e-all-correct-$i',
              wordId: (i % 5) + 1,
              sessionId: 'session-001',
              wasCorrect: true,
              reviewedAt:
                  day.add(Duration(minutes: i * 5)).millisecondsSinceEpoch,
            ));
      }

      final activity = await db.reviewEventDao.getDailyActivityForRange(
        DateTime(2026, 4, 15).toUtc().millisecondsSinceEpoch,
        DateTime(2026, 4, 16).toUtc().millisecondsSinceEpoch,
      );

      final dayData = activity['2026-04-15']!;
      expect(dayData['questionCount'], equals(5));
      expect(dayData['correctCount'], equals(5));
    });
  });
}
