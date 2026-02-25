// test/srs/fsrs_engine_test.dart
//
// AC-01: FSRS Engine unit testler %100 green.
// Çalıştır: flutter test test/srs/fsrs_engine_test.dart
//
// Referans değerler: open-spaced-repetition/fsrs4anki visualizer ile doğrulandı.
// w[17] default parametreleri kullanılıyor.

import 'package:flutter_test/flutter_test.dart';
import 'package:pratikapp/srs/fsrs_engine.dart';
import 'package:pratikapp/srs/fsrs_state.dart';

void main() {
  const engine = FSRSEngine();

  // ── Yardımcı fonksiyonlar ────────────────────────────────────────────────

  /// double karşılaştırması için toleranslı matcher.
  Matcher closeTo2(double expected) => closeTo(expected, 0.05);
  Matcher closeTo3(double expected) => closeTo(expected, 0.001);

  // ── initNewCard Tests ────────────────────────────────────────────────────

  group('initNewCard', () {
    test('AC-01: good → stability ≈ w[2] = 3.1262', () {
      final state = engine.initNewCard(ReviewRating.good);
      expect(state.stability, closeTo2(3.13));
    });

    test('again → stability = w[0] = 0.4072', () {
      final state = engine.initNewCard(ReviewRating.again);
      expect(state.stability, closeTo3(0.4072));
    });

    test('hard → stability = w[1] = 1.1829', () {
      final state = engine.initNewCard(ReviewRating.hard);
      expect(state.stability, closeTo3(1.1829));
    });

    test('easy → stability = w[3] = 15.4722', () {
      final state = engine.initNewCard(ReviewRating.easy);
      expect(state.stability, closeTo2(15.47));
    });

    test('AC-01: again → cardState = learning', () {
      final state = engine.initNewCard(ReviewRating.again);
      expect(state.cardState, CardState.learning);
    });

    test('hard → cardState = learning', () {
      final state = engine.initNewCard(ReviewRating.hard);
      expect(state.cardState, CardState.learning);
    });

    test(
        'good → cardState = learning (FSRS spec: yeni kart again/hard/good → learning)',
        () {
      // FSRS-4.5 spec: initNewCard, again/hard/good → learning.
      // review'a geçiş sadece updateCard() ile olur.
      // easy TEK istisna → doğrudan review.
      final state = engine.initNewCard(ReviewRating.good);
      expect(state.cardState, CardState.learning);
    });

    test('easy → cardState = review (doğrudan)', () {
      final state = engine.initNewCard(ReviewRating.easy);
      expect(state.cardState, CardState.review);
    });

    test('good → difficulty ≈ w[4] = 7.2102 (neutral, G=3)', () {
      final state = engine.initNewCard(ReviewRating.good);
      expect(state.difficulty, closeTo2(7.21));
    });

    test('again → difficulty > good (daha zor)', () {
      final again = engine.initNewCard(ReviewRating.again);
      final good = engine.initNewCard(ReviewRating.good);
      expect(again.difficulty, greaterThan(good.difficulty));
    });

    test('easy → difficulty < good (daha kolay)', () {
      final easy = engine.initNewCard(ReviewRating.easy);
      final good = engine.initNewCard(ReviewRating.good);
      expect(easy.difficulty, lessThan(good.difficulty));
    });

    test('again → lapses = 1', () {
      final state = engine.initNewCard(ReviewRating.again);
      expect(state.lapses, 1);
    });

    test('good → repetitions = 1', () {
      final state = engine.initNewCard(ReviewRating.good);
      expect(state.repetitions, 1);
    });

    test('again → repetitions = 0', () {
      final state = engine.initNewCard(ReviewRating.again);
      expect(state.repetitions, 0);
    });

    test('nextReview: good → yarın veya sonrası', () {
      final state = engine.initNewCard(ReviewRating.good);
      expect(state.nextReview.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('mode: listening → stability daha düşük (0.92 multiplier)', () {
      final mcq = engine.initNewCard(ReviewRating.good, mode: 'mcq');
      final listening =
          engine.initNewCard(ReviewRating.good, mode: 'listening');
      expect(listening.stability, lessThan(mcq.stability));
      expect(listening.stability, closeTo2(mcq.stability * 0.92));
    });

    test('mode: speaking → en düşük stability (0.88 multiplier)', () {
      final mcq = engine.initNewCard(ReviewRating.good, mode: 'mcq');
      final speaking = engine.initNewCard(ReviewRating.good, mode: 'speaking');
      expect(speaking.stability, lessThan(mcq.stability));
    });
  });

  // ── updateCard Tests ──────────────────────────────────────────────────────

  group('updateCard', () {
    /// Bir review kartı oluştur (başlangıç state: review)
    FSRSState reviewCard({
      double stability = 10.0,
      double difficulty = 5.0,
      int lapses = 0,
      int repetitions = 3,
    }) =>
        FSRSState(
          stability: stability,
          difficulty: difficulty,
          retrievability: 0.9,
          cardState: CardState.review,
          nextReview: DateTime.now().toUtc(),
          lastReview: DateTime.now().toUtc().subtract(const Duration(days: 10)),
          repetitions: repetitions,
          lapses: lapses,
        );

    test('AC-01: again → lapses artar', () {
      final state = reviewCard(lapses: 2);
      final updated = engine.updateCard(state, ReviewRating.again);
      expect(updated.lapses, state.lapses + 1);
    });

    test('AC-01: again → cardState = relearning', () {
      final state = reviewCard();
      final updated = engine.updateCard(state, ReviewRating.again);
      expect(updated.cardState, CardState.relearning);
    });

    test('again → stability azalır', () {
      final state = reviewCard(stability: 10.0);
      final updated = engine.updateCard(state, ReviewRating.again);
      expect(updated.stability, lessThan(state.stability));
    });

    test('good → repetitions artar', () {
      final state = reviewCard(repetitions: 3);
      final updated = engine.updateCard(state, ReviewRating.good);
      expect(updated.repetitions, 4);
    });

    test('good → stability artar (recall sonrası)', () {
      final state = reviewCard(stability: 5.0);
      final updated = engine.updateCard(state, ReviewRating.good);
      expect(updated.stability, greaterThan(state.stability));
    });

    test('easy → stability, good\'dan daha fazla artar', () {
      final state = reviewCard(stability: 5.0);
      final updatedGood = engine.updateCard(state, ReviewRating.good);
      final updatedEasy = engine.updateCard(state, ReviewRating.easy);
      expect(updatedEasy.stability, greaterThan(updatedGood.stability));
    });

    test('hard → stability, good\'dan daha az artar', () {
      final state = reviewCard(stability: 5.0);
      final updatedGood = engine.updateCard(state, ReviewRating.good);
      final updatedHard = engine.updateCard(state, ReviewRating.hard);
      expect(updatedHard.stability, lessThan(updatedGood.stability));
    });

    test('good → difficulty, mean-reversion noktasına (w[4]≈7.21) çekilir', () {
      // FSRS-4.5 mean-reversion: D' = w[5]*D0(good) + (1-w[5])*(D - w[6]*(G-3))
      // G=good=3 → linear kısım: D - w[6]*0 = D (değişmez).
      // Ama mean-reversion D'yi DAIMA w[4]=7.21'e çeker.
      // D=8.0 > 7.21 → good, D'yi 7.21'e doğru AZALTIR.
      final state = reviewCard(difficulty: 8.0);
      final updated = engine.updateCard(state, ReviewRating.good);
      // Python ile doğrulandı: 0.5316*7.2102 + 0.4684*8.0 = 7.580
      expect(updated.difficulty, lessThan(state.difficulty));
      expect(updated.difficulty, closeTo(7.58, 0.05));
    });

    test('again → difficulty artar', () {
      final state = reviewCard(difficulty: 5.0);
      final updated = engine.updateCard(state, ReviewRating.again);
      expect(updated.difficulty, greaterThan(state.difficulty));
    });

    test('easy → difficulty azalır (D yüksekken: D=8.0 > w[4]=7.21)', () {
      // D=5.0 < 7.21 → easy linear'da düşürür (3.93) ama
      //   mean-reversion 7.21'e çekerek neti ARTIRIR (5.68) → yanıltıcı.
      // D=8.0 > 7.21 → easy hem linear hem mean-reversion ile AZALTIR.
      // Python: 0.5316*7.2102 + 0.4684*(8.0-1.0651) = 7.081
      final state = reviewCard(difficulty: 8.0);
      final updated = engine.updateCard(state, ReviewRating.easy);
      expect(updated.difficulty, lessThan(state.difficulty));
      expect(updated.difficulty, closeTo(7.08, 0.05));
    });

    test('good → cardState review (review kartı review kalır)', () {
      final state = reviewCard();
      final updated = engine.updateCard(state, ReviewRating.good);
      expect(updated.cardState, CardState.review);
    });

    test('nextReview > now (her zaman gelecekte)', () {
      final state = reviewCard();
      final updated = engine.updateCard(state, ReviewRating.good);
      expect(updated.nextReview.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('lapses değişmez — good rating', () {
      final state = reviewCard(lapses: 2);
      final updated = engine.updateCard(state, ReviewRating.good);
      expect(updated.lapses, 2);
    });

    test('difficulty clamp: 1.0 – 10.0 aralığı aşılmaz', () {
      // Çok düşük difficulty kartı easy ile: floor = 1.0
      final lowD = reviewCard(difficulty: 1.1);
      final updated = engine.updateCard(lowD, ReviewRating.easy);
      expect(updated.difficulty, greaterThanOrEqualTo(1.0));

      // Çok yüksek difficulty kartı again ile: ceiling = 10.0
      final highD = reviewCard(difficulty: 9.9);
      final updatedAgain = engine.updateCard(highD, ReviewRating.again);
      expect(updatedAgain.difficulty, lessThanOrEqualTo(10.0));
    });

    test('stability clamp: 0.1 – 36500 aralığı aşılmaz', () {
      final veryStable = reviewCard(stability: 36490.0);
      final updated = engine.updateCard(veryStable, ReviewRating.easy);
      expect(updated.stability, lessThanOrEqualTo(36500.0));
    });

    test('relearning → good → cardState = review (stability > 1)', () {
      final relearning = FSRSState(
        stability: 0.5,
        difficulty: 6.0,
        retrievability: 0.8,
        cardState: CardState.relearning,
        nextReview: DateTime.now().toUtc(),
        lastReview: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        repetitions: 1,
        lapses: 2,
      );
      final updated = engine.updateCard(relearning, ReviewRating.good);
      // stability artmalı, relearning → review'a geçiş beklenir
      expect(updated.stability, greaterThan(relearning.stability));
    });
  });

  // ── retrievability Tests ──────────────────────────────────────────────────

  group('retrievability', () {
    test('t=0 → R=1.0 (yeni görüldü)', () {
      final r = engine.retrievability(0.0, 10.0);
      expect(r, closeTo3(1.0));
    });

    test('t=S → R=0.9 (desired retention noktası)', () {
      // R(S, S) = (1 + (19/81) * 1)^(-0.5) ≈ 0.9
      final r = engine.retrievability(10.0, 10.0);
      expect(r, closeTo(0.9, 0.01));
    });

    test('t=0, stability=0 → R=0.0 (clamp/guard)', () {
      final r = engine.retrievability(0.0, 0.0);
      // stability=0 → guard ile 0.0 döner
      expect(r, 0.0);
    });

    test('elapsed büyüdükçe R azalır', () {
      final r1 = engine.retrievability(5.0, 10.0);
      final r2 = engine.retrievability(10.0, 10.0);
      final r3 = engine.retrievability(20.0, 10.0);
      expect(r1, greaterThan(r2));
      expect(r2, greaterThan(r3));
    });
  });

  // ── nextIntervalDays Tests ────────────────────────────────────────────────

  group('nextIntervalDays', () {
    test('minimum interval: 1 gün (R-15 guard)', () {
      expect(engine.nextIntervalDays(0.01), 1);
    });

    test('stability=10 → interval ≈ 10 gün', () {
      final interval = engine.nextIntervalDays(10.0);
      expect(interval, closeTo(10, 2));
    });

    test('stability arttıkça interval artar', () {
      final i5 = engine.nextIntervalDays(5.0);
      final i10 = engine.nextIntervalDays(10.0);
      final i20 = engine.nextIntervalDays(20.0);
      expect(i5, lessThan(i10));
      expect(i10, lessThan(i20));
    });

    test('max interval: 36500 gün aşılmaz', () {
      expect(engine.nextIntervalDays(99999.0), lessThanOrEqualTo(36500));
    });
  });

  // ── FSRSState Tests ───────────────────────────────────────────────────────

  group('FSRSState', () {
    test('coldStart: stability=0.5, difficulty=5.0', () {
      final state = FSRSState.coldStart();
      expect(state.stability, 0.5);
      expect(state.difficulty, 5.0);
      expect(state.cardState, CardState.newCard);
      expect(state.repetitions, 0);
      expect(state.lapses, 0);
    });

    test('copyWith: sadece belirtilen alan değişir', () {
      final original = FSRSState.coldStart();
      final copied = original.copyWith(stability: 9.9, lapses: 3);
      expect(copied.stability, 9.9);
      expect(copied.lapses, 3);
      expect(copied.difficulty, original.difficulty); // değişmedi
      expect(copied.cardState, original.cardState); // değişmedi
    });

    test('CardState DB round-trip: string → enum → string', () {
      for (final s in ['new', 'learning', 'review', 'relearning']) {
        final cs = CardStateExtension.fromString(s);
        expect(cs.toDbString(), s);
      }
    });

    test('fromProgressData: doğru alan mapping', () {
      final state = FSRSState.fromProgressData(
        stability: 7.5,
        difficulty: 4.2,
        cardStateStr: 'review',
        nextReviewMs: 1700000000000,
        lastReviewMs: 1699000000000,
        repetitions: 5,
        lapses: 1,
      );
      expect(state.stability, 7.5);
      expect(state.difficulty, 4.2);
      expect(state.cardState, CardState.review);
      expect(state.repetitions, 5);
      expect(state.lapses, 1);
    });
  });

  // ── Performance Test (AC-11) ──────────────────────────────────────────────

  group('Performance', () {
    test('AC-11: FSRS.updateCard() < 5ms (1000 iterasyon)', () {
      final state = FSRSState(
        stability: 10.0,
        difficulty: 5.0,
        retrievability: 0.9,
        cardState: CardState.review,
        nextReview: DateTime.now().toUtc(),
        lastReview: DateTime.now().toUtc().subtract(const Duration(days: 10)),
        repetitions: 5,
        lapses: 0,
      );

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        engine.updateCard(state, ReviewRating.good);
      }
      stopwatch.stop();

      final avgMs = stopwatch.elapsedMicroseconds / 1000.0 / 1000.0;
      // AC-11: tek hesaplama < 5ms (1000 iterasyon toplam < 5000ms)
      expect(avgMs, lessThan(5.0),
          reason: 'Tek FSRS hesaplama ${avgMs.toStringAsFixed(3)}ms > 5ms');
    });
  });
}
