// test/srs/t05_test.dart
//
// T-05: LeechHandler + ModeSelector testleri.
// Çalıştır: flutter test test/srs/t05_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pratikapp/srs/fsrs_state.dart';
import 'package:pratikapp/srs/leech_handler.dart';
import 'package:pratikapp/srs/mode_selector.dart';

void main() {
  // ── LeechHandler Tests ────────────────────────────────────────────────────

  group('LeechHandler.evaluate', () {
    test('Blueprint: lapses=4 → markLeech', () {
      expect(
        LeechHandler.evaluate(lapses: 4, repetitions: 10),
        LeechDecision.markLeech,
      );
    });

    test('Blueprint: lapses=8 → suspend', () {
      expect(
        LeechHandler.evaluate(lapses: 8, repetitions: 5),
        LeechDecision.suspend,
      );
    });

    test('lapses=0 → none', () {
      expect(
          LeechHandler.evaluate(lapses: 0, repetitions: 0), LeechDecision.none);
    });

    test('lapses=3 → none (threshold altında)', () {
      expect(
          LeechHandler.evaluate(lapses: 3, repetitions: 5), LeechDecision.none);
    });

    test('lapses=5 → markLeech (4-7 arası)', () {
      expect(LeechHandler.evaluate(lapses: 5, repetitions: 3),
          LeechDecision.markLeech);
    });

    test('lapses=7 → markLeech (suspend eşiği altında)', () {
      expect(LeechHandler.evaluate(lapses: 7, repetitions: 2),
          LeechDecision.markLeech);
    });

    test('lapses=9 → suspend (threshold üstünde)', () {
      expect(LeechHandler.evaluate(lapses: 9, repetitions: 1),
          LeechDecision.suspend);
    });

    test('threshold sabitleri doğru', () {
      expect(LeechHandler.leechThreshold, 4);
      expect(LeechHandler.suspendThreshold, 8);
    });
  });

  group('LeechHandler.resetForRelearning', () {
    test('cardState → relearning', () {
      final state = _reviewState(lapses: 4);
      final reset = LeechHandler.resetForRelearning(state);
      expect(reset.cardState, CardState.relearning);
    });

    test('stability → 0.4072 (FSRS w[0])', () {
      final state = _reviewState(stability: 10.0);
      final reset = LeechHandler.resetForRelearning(state);
      expect(reset.stability, closeTo(0.4072, 0.0001));
    });

    test('nextReview → şimdi veya geçmiş (hemen göster)', () {
      final state = _reviewState();
      final reset = LeechHandler.resetForRelearning(state);
      expect(
        reset.nextReview
            .isBefore(DateTime.now().toUtc().add(const Duration(seconds: 5))),
        isTrue,
        reason: 'resetForRelearning nextReview şimdi olmalı',
      );
    });

    test('repetitions → 0 (yeniden başlıyor)', () {
      final state = _reviewState(repetitions: 10);
      final reset = LeechHandler.resetForRelearning(state);
      expect(reset.repetitions, 0);
    });

    test('lapses değişmez (geçmiş korunur)', () {
      final state = _reviewState(lapses: 5);
      final reset = LeechHandler.resetForRelearning(state);
      expect(reset.lapses, 5);
    });
  });

  group('LeechHandler.applyRewardedBoost', () {
    test('stability 1.5x artır', () {
      final state = _reviewState(stability: 2.0);
      final boosted = LeechHandler.applyRewardedBoost(state);
      expect(boosted.stability, closeTo(3.0, 0.01));
    });

    test('nextReview → 1 gün sonra', () {
      final state = _reviewState();
      final boosted = LeechHandler.applyRewardedBoost(state);
      final tomorrow = DateTime.now().toUtc().add(const Duration(hours: 23));
      expect(boosted.nextReview.isAfter(tomorrow), isTrue);
    });

    test('stability clamp: çok yüksek değer 36500 aşmaz', () {
      final state = _reviewState(stability: 30000.0);
      final boosted = LeechHandler.applyRewardedBoost(state);
      expect(boosted.stability, lessThanOrEqualTo(36500.0));
    });

    test('lapses değişmez', () {
      final state = _reviewState(lapses: 4);
      final boosted = LeechHandler.applyRewardedBoost(state);
      expect(boosted.lapses, 4);
    });
  });

  group('LeechHandler helpers', () {
    test('isLeech: lapses<4 → false',
        () => expect(LeechHandler.isLeech(3), false));
    test('isLeech: lapses=4 → true',
        () => expect(LeechHandler.isLeech(4), true));
    test('isLeech: lapses=8 → true',
        () => expect(LeechHandler.isLeech(8), true));
    test('isSuspended: lapses<8 → false',
        () => expect(LeechHandler.isSuspended(7), false));
    test('isSuspended: lapses=8 → true',
        () => expect(LeechHandler.isSuspended(8), true));
  });

  // ── ModeSelector Tests ────────────────────────────────────────────────────

  group('ModeSelector.selectMode', () {
    test('Blueprint: {mcq:5, listening:5, speaking:0} → speaking', () {
      final mode = ModeSelector.selectMode(
        modeHistory: {'mcq': 5, 'listening': 5, 'speaking': 0},
        cardState: CardState.review,
        isMiniSession: false,
      );
      expect(mode, StudyMode.speaking);
    });

    test('Blueprint: isMiniSession=true → mcq', () {
      final mode = ModeSelector.selectMode(
        modeHistory: {'mcq': 0, 'listening': 10, 'speaking': 10},
        cardState: CardState.review,
        isMiniSession: true,
      );
      expect(mode, StudyMode.mcq);
    });

    test('cardState=newCard → mcq (yeni kelime tanıtımı)', () {
      final mode = ModeSelector.selectMode(
        modeHistory: {'mcq': 0, 'listening': 0, 'speaking': 0},
        cardState: CardState.newCard,
        isMiniSession: false,
      );
      expect(mode, StudyMode.mcq);
    });

    test('boş history → mcq (ilk sırada)', () {
      final mode = ModeSelector.selectMode(
        modeHistory: {},
        cardState: CardState.review,
        isMiniSession: false,
      );
      expect(mode, StudyMode.mcq);
    });

    test('{mcq:0, listening:2, speaking:5} → mcq (en az)', () {
      final mode = ModeSelector.selectMode(
        modeHistory: {'mcq': 0, 'listening': 2, 'speaking': 5},
        cardState: CardState.review,
        isMiniSession: false,
      );
      expect(mode, StudyMode.mcq);
    });

    test('{mcq:3, listening:0, speaking:3} → listening (en az)', () {
      final mode = ModeSelector.selectMode(
        modeHistory: {'mcq': 3, 'listening': 0, 'speaking': 3},
        cardState: CardState.review,
        isMiniSession: false,
      );
      expect(mode, StudyMode.listening);
    });

    test('isMiniSession trumps cardState=newCard', () {
      // Her iki kural da mcq veriyor — sonuç mcq
      final mode = ModeSelector.selectMode(
        modeHistory: {},
        cardState: CardState.newCard,
        isMiniSession: true,
      );
      expect(mode, StudyMode.mcq);
    });

    test('userPreferredMode: dominant değilse tercihi ver', () {
      // speaking 2 kez, mcq 2 kez — speaking dominant değil → tercihi ver
      final mode = ModeSelector.selectMode(
        modeHistory: {'mcq': 2, 'listening': 1, 'speaking': 2},
        cardState: CardState.review,
        isMiniSession: false,
        userPreferredMode: StudyMode.speaking,
      );
      expect(mode, StudyMode.speaking);
    });

    test('userPreferredMode: dominant ise alternatife geç', () {
      // mcq=10, listening=0, speaking=0 → mcq dominant (10-0=10 >= 3) → alternatif
      final mode = ModeSelector.selectMode(
        modeHistory: {'mcq': 10, 'listening': 0, 'speaking': 0},
        cardState: CardState.review,
        isMiniSession: false,
        userPreferredMode: StudyMode.mcq,
      );
      // Alternatif: listening veya speaking (ikisi de 0, mcq değil) → mcq hariç en az
      expect(mode, isNot(StudyMode.mcq));
    });

    test('relearning kartı → en az kullanılan (mcq forced değil)', () {
      final mode = ModeSelector.selectMode(
        modeHistory: {'mcq': 5, 'listening': 5, 'speaking': 1},
        cardState: CardState.relearning,
        isMiniSession: false,
      );
      expect(mode, StudyMode.speaking);
    });
  });

  group('ModeSelector._getDominantMode', () {
    test('{mcq:5, listening:2, speaking:1} → mcq', () {
      expect(
        ModeSelector.getDominantMode({'mcq': 5, 'listening': 2, 'speaking': 1}),
        StudyMode.mcq,
      );
    });

    test('boş history → mcq (default first)', () {
      expect(ModeSelector.getDominantMode({}), StudyMode.mcq);
    });

    test('{mcq:3, listening:3, speaking:3} → mcq (eşitlik: enum sırası)', () {
      expect(
        ModeSelector.getDominantMode({'mcq': 3, 'listening': 3, 'speaking': 3}),
        StudyMode.mcq,
      );
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

FSRSState _reviewState({
  double stability = 5.0,
  double difficulty = 5.0,
  int lapses = 0,
  int repetitions = 3,
  CardState state = CardState.review,
}) =>
    FSRSState(
      stability: stability,
      difficulty: difficulty,
      retrievability: 0.9,
      cardState: state,
      nextReview: DateTime.now().toUtc(),
      lastReview: DateTime.now().toUtc().subtract(const Duration(days: 5)),
      repetitions: repetitions,
      lapses: lapses,
    );
