// test/core/monitoring/performance_audit_test.dart
//
// T-22: Performance Audit — Blueprint AC-11
//
// Hedefler:
//   FSRS calc    < 5ms    (tek updateCard çağrısı)
//   buildPlan()  < 500ms  (50 due + 10 new kart ile)
//   interleaveForTest < 10ms (100 kart)
//
// NOT: cold start < 2s → flutter run --profile + DevTools'ta manuel ölçülür.
//
// Çalıştır: flutter test test/core/monitoring/performance_audit_test.dart

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pratikapp/database/app_database.dart';
import 'package:pratikapp/srs/daily_planner.dart';
import 'package:pratikapp/srs/fsrs_engine.dart';
import 'package:pratikapp/srs/fsrs_state.dart';
import 'package:pratikapp/srs/plan_models.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

AppDatabase _newDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> _seedWords(AppDatabase db, int count) async {
  for (var i = 1; i <= count; i++) {
    await db.wordDao.insertWordRaw(WordsCompanion.insert(
      id: Value(i),
      contentJson: Value(
          '{"en":{"word":"word$i","meaning":"meaning$i"},"tr":{"word":"kelime$i","meaning":"anlam$i"}}'),
      categoriesJson: Value('["general"]'),
      sentencesJson: Value('{}'),
      difficultyRank: Value(1),
    ));
  }
}

Future<void> _seedDueProgress(AppDatabase db, int count, String lang) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final yesterday = now - 86400000;
  for (var i = 1; i <= count; i++) {
    await db.progressDao.upsertProgress(ProgressCompanion.insert(
      wordId: i,
      targetLang: lang,
      stability: const Value(2.0),
      difficulty: const Value(5.0),
      cardState: const Value('review'),
      repetitions: const Value(3),
      lapses: const Value(0),
      nextReviewMs: Value(yesterday),
      lastReviewMs: Value(yesterday),
      updatedAt: Value(now),
    ));
  }
}

void main() {
  // ── FSRS calc < 5ms ────────────────────────────────────────────────────────

  group('AC-11: FSRS hesaplama < 5ms', () {
    test('updateCard() 1000 iterasyon → ortalama < 5ms', () {
      final engine = FSRSEngine();
      // FSRSState: gerçek imza (retrievability, nextReview, lastReview — DateTime)
      final now = DateTime.now();
      final state = FSRSState(
        stability: 2.4,
        difficulty: 5.0,
        retrievability: 0.9,
        cardState: CardState.learning,
        nextReview: now,
        lastReview: now,
        repetitions: 1,
        lapses: 0,
      );

      const iterations = 1000;
      final sw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        engine.updateCard(state, ReviewRating.good);
      }
      sw.stop();

      final avgMs = sw.elapsedMicroseconds / 1000.0 / iterations;
      expect(
        avgMs,
        lessThan(5.0),
        reason:
            'FSRS updateCard ortalama ${avgMs.toStringAsFixed(3)}ms > 5ms (AC-11)',
      );
    });

    test('initNewCard() 1000 iterasyon → ortalama < 5ms', () {
      final engine = FSRSEngine();
      const iterations = 1000;
      final sw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        // initNewCard gerçek imzası: (ReviewRating rating, {String mode})
        engine.initNewCard(ReviewRating.good);
      }
      sw.stop();

      final avgMs = sw.elapsedMicroseconds / 1000.0 / iterations;
      expect(
        avgMs,
        lessThan(5.0),
        reason:
            'FSRS initNewCard ortalama ${avgMs.toStringAsFixed(3)}ms > 5ms (AC-11)',
      );
    });
  });

  // ── buildPlan() < 500ms ────────────────────────────────────────────────────

  group('AC-11: buildPlan() < 500ms', () {
    late AppDatabase db;

    setUp(() async {
      db = _newDb();
      await _seedWords(db, 60);
      await _seedDueProgress(db, 50, 'en');
    });

    tearDown(() async => db.close());

    test('50 due + 10 new → buildPlan() < 500ms', () async {
      final planner = DailyPlanner(
        progressDao: db.progressDao,
        wordDao: db.wordDao,
      );

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final sw = Stopwatch()..start();
      final plan = await planner.buildPlan(
        targetLang: 'en',
        categories: [],
        newWordsGoal: 10,
        planDate: today, // required param
      );
      sw.stop();

      expect(
        sw.elapsedMilliseconds,
        lessThan(500),
        reason: 'buildPlan() ${sw.elapsedMilliseconds}ms > 500ms (AC-11)',
      );
      expect(plan.totalCards, greaterThan(0));
    });
  });

  // ── interleaveForTest < 10ms ──────────────────────────────────────────────

  group('DailyPlanner interleaveForTest < 10ms (100 kart)', () {
    late AppDatabase db;

    setUp(() {
      db = _newDb();
    });

    tearDown(() async => db.close());

    test('interleave 100 PlanCard < 10ms', () {
      // interleaveForTest sadece list sort — DB IO yok, DAO kullanılmaz
      final planner = DailyPlanner(
        progressDao: db.progressDao,
        wordDao: db.wordDao,
      );

      // PlanCard gerçek imzası: {required wordId, required CardSource source}
      final leeches = List.generate(
          5,
          (i) => PlanCard(
                wordId: i + 1,
                source: CardSource.leech,
              ));
      final dueCards = List.generate(
          65,
          (i) => PlanCard(
                wordId: i + 6,
                source: CardSource.due,
              ));
      final newCards = List.generate(
          30,
          (i) => PlanCard(
                wordId: i + 71,
                source: CardSource.newCard,
              ));

      final sw = Stopwatch()..start();
      final result = planner.interleaveForTest(
        leeches: leeches,
        dueCards: dueCards,
        newCards: newCards,
      );
      sw.stop();

      expect(
        sw.elapsedMilliseconds,
        lessThan(10),
        reason: 'interleaveForTest ${sw.elapsedMilliseconds}ms > 10ms',
      );
      expect(result.length, leeches.length + dueCards.length + newCards.length);
      // Leech kartlar başta olmalı
      expect(result.take(5).every((c) => c.source == CardSource.leech), isTrue);
    });
  });
}
