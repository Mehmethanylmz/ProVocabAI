// test/srs/fsrs_engine_test.dart
//
// F16-02: FSRS engine unit tests
//   - initNewCard stability values and ordering
//   - updateCard lapse counting and state transitions
//   - Rating → interval ordering (hard < good < easy)
//   - Retrievability formula correctness

import 'package:flutter_test/flutter_test.dart';

import 'package:savgolearnvocabulary/srs/fsrs_engine.dart';
import 'package:savgolearnvocabulary/srs/fsrs_state.dart';

void main() {
  const engine = FSRSEngine();

  group('FSRSEngine.initNewCard', () {
    test('good rating yields stability ≈ w[2] = 3.1262', () {
      final state = engine.initNewCard(ReviewRating.good);
      expect(state.stability, closeTo(3.1262, 0.0001));
    });

    test('stability ordering: again < hard < good < easy', () {
      final again = engine.initNewCard(ReviewRating.again);
      final hard = engine.initNewCard(ReviewRating.hard);
      final good = engine.initNewCard(ReviewRating.good);
      final easy = engine.initNewCard(ReviewRating.easy);

      expect(again.stability, lessThan(hard.stability));
      expect(hard.stability, lessThan(good.stability));
      expect(good.stability, lessThan(easy.stability));
    });

    test('again increments lapses to 1', () {
      final state = engine.initNewCard(ReviewRating.again);
      expect(state.lapses, equals(1));
    });

    test('again gives 0 repetitions (not counted as success)', () {
      final state = engine.initNewCard(ReviewRating.again);
      expect(state.repetitions, equals(0));
    });

    test('good/hard/easy give 1 repetition', () {
      expect(engine.initNewCard(ReviewRating.good).repetitions, equals(1));
      expect(engine.initNewCard(ReviewRating.hard).repetitions, equals(1));
      expect(engine.initNewCard(ReviewRating.easy).repetitions, equals(1));
    });

    test('again/hard/good → learning state', () {
      expect(engine.initNewCard(ReviewRating.again).cardState,
          equals(CardState.learning));
      expect(engine.initNewCard(ReviewRating.hard).cardState,
          equals(CardState.learning));
      expect(engine.initNewCard(ReviewRating.good).cardState,
          equals(CardState.learning));
    });

    test('easy → directly review state (skip learning)', () {
      final state = engine.initNewCard(ReviewRating.easy);
      expect(state.cardState, equals(CardState.review));
    });

    test('easy → interval > 1 day (next review far out)', () {
      final state = engine.initNewCard(ReviewRating.easy);
      final daysUntilReview =
          state.nextReview.difference(DateTime.now().toUtc()).inDays;
      expect(daysUntilReview, greaterThan(1));
    });

    test('mode multiplier: listening reduces stability vs mcq', () {
      final mcq = engine.initNewCard(ReviewRating.good, mode: 'mcq');
      final listening =
          engine.initNewCard(ReviewRating.good, mode: 'listening');
      expect(listening.stability, lessThan(mcq.stability));
    });

    test('mode multiplier: speaking reduces stability more than listening', () {
      final listening =
          engine.initNewCard(ReviewRating.good, mode: 'listening');
      final speaking = engine.initNewCard(ReviewRating.good, mode: 'speaking');
      expect(speaking.stability, lessThan(listening.stability));
    });
  });

  group('FSRSEngine.updateCard — again (forgetting)', () {
    late FSRSState baseState;

    setUp(() {
      // A review-state card with known stability
      baseState = FSRSState(
        stability: 10.0,
        difficulty: 5.0,
        retrievability: 0.9,
        cardState: CardState.review,
        nextReview: DateTime.now().toUtc().add(const Duration(days: 10)),
        lastReview: DateTime.now().toUtc().subtract(const Duration(days: 10)),
        repetitions: 3,
        lapses: 1,
      );
    });

    test('again increments lapses', () {
      final updated = engine.updateCard(baseState, ReviewRating.again);
      expect(updated.lapses, equals(baseState.lapses + 1));
    });

    test('again transitions to relearning state', () {
      final updated = engine.updateCard(baseState, ReviewRating.again);
      expect(updated.cardState, equals(CardState.relearning));
    });

    test('again next review is 1 day out', () {
      final updated = engine.updateCard(baseState, ReviewRating.again);
      final days =
          updated.nextReview.difference(DateTime.now().toUtc()).inDays;
      expect(days, lessThanOrEqualTo(1));
    });

    test('again stability never exceeds pre-lapse stability', () {
      final updated = engine.updateCard(baseState, ReviewRating.again);
      expect(updated.stability, lessThanOrEqualTo(baseState.stability));
    });

    test('again does NOT increment repetitions', () {
      final updated = engine.updateCard(baseState, ReviewRating.again);
      expect(updated.repetitions, equals(baseState.repetitions));
    });
  });

  group('FSRSEngine.updateCard — recall (hard/good/easy)', () {
    late FSRSState reviewState;

    setUp(() {
      reviewState = FSRSState(
        stability: 5.0,
        difficulty: 5.0,
        retrievability: 0.9,
        cardState: CardState.review,
        nextReview: DateTime.now().toUtc().add(const Duration(days: 5)),
        lastReview: DateTime.now().toUtc().subtract(const Duration(days: 5)),
        repetitions: 2,
        lapses: 0,
      );
    });

    test('good keeps review in review state', () {
      final updated = engine.updateCard(reviewState, ReviewRating.good);
      expect(updated.cardState, equals(CardState.review));
    });

    test('good increments repetitions', () {
      final updated = engine.updateCard(reviewState, ReviewRating.good);
      expect(updated.repetitions, equals(reviewState.repetitions + 1));
    });

    test('good does NOT increment lapses', () {
      final updated = engine.updateCard(reviewState, ReviewRating.good);
      expect(updated.lapses, equals(reviewState.lapses));
    });

    test('interval ordering: hard < good < easy', () {
      final hard = engine.updateCard(reviewState, ReviewRating.hard);
      final good = engine.updateCard(reviewState, ReviewRating.good);
      final easy = engine.updateCard(reviewState, ReviewRating.easy);

      final hardDays =
          hard.nextReview.difference(DateTime.now().toUtc()).inDays;
      final goodDays =
          good.nextReview.difference(DateTime.now().toUtc()).inDays;
      final easyDays =
          easy.nextReview.difference(DateTime.now().toUtc()).inDays;

      expect(hardDays, lessThan(goodDays));
      expect(goodDays, lessThan(easyDays));
    });

    test('stability ordering after recall: hard < good < easy', () {
      final hard = engine.updateCard(reviewState, ReviewRating.hard);
      final good = engine.updateCard(reviewState, ReviewRating.good);
      final easy = engine.updateCard(reviewState, ReviewRating.easy);

      expect(hard.stability, lessThan(good.stability));
      expect(good.stability, lessThan(easy.stability));
    });

    test('learning state card with high stability graduates to review', () {
      // Simulate a learning card where good gives stability > 1
      final learningState = reviewState.copyWith(
        cardState: CardState.learning,
        stability: 3.0,
      );
      final updated = engine.updateCard(learningState, ReviewRating.good);
      // With stability > 1 after update, should be review
      expect(updated.cardState, equals(CardState.review));
    });
  });

  group('FSRSEngine.retrievability', () {
    test('retrievability at t=0 is 1.0 (just reviewed)', () {
      final r = engine.retrievability(0, 10.0);
      expect(r, closeTo(1.0, 0.0001));
    });

    test('retrievability at t=S is ≈ 0.9 (desired retention)', () {
      const stability = 10.0;
      final r = engine.retrievability(stability, stability);
      expect(r, closeTo(0.9, 0.01));
    });

    test('retrievability decreases as elapsed time increases', () {
      const stability = 10.0;
      final r1 = engine.retrievability(1, stability);
      final r5 = engine.retrievability(5, stability);
      final r10 = engine.retrievability(10, stability);

      expect(r1, greaterThan(r5));
      expect(r5, greaterThan(r10));
    });

    test('retrievability with 0 stability returns 0.0', () {
      final r = engine.retrievability(5, 0);
      expect(r, equals(0.0));
    });

    test('higher stability means higher retrievability at same elapsed time', () {
      final lowS = engine.retrievability(5, 5.0);
      final highS = engine.retrievability(5, 20.0);
      expect(highS, greaterThan(lowS));
    });
  });

  group('FSRSEngine stability clamps', () {
    test('minimum stability is 0.1 (not 0 or negative)', () {
      // Use a very low stability input — lapse on nearly-forgotten card
      final veryLowState = FSRSState(
        stability: 0.1,
        difficulty: 10.0,
        retrievability: 0.1,
        cardState: CardState.relearning,
        nextReview: DateTime.now().toUtc(),
        lastReview:
            DateTime.now().toUtc().subtract(const Duration(days: 365)),
        repetitions: 0,
        lapses: 7,
      );
      final updated = engine.updateCard(veryLowState, ReviewRating.again);
      expect(updated.stability, greaterThanOrEqualTo(0.1));
    });
  });
}
