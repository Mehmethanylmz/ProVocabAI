// test/srs/xp_calculator_test.dart
//
// T-06 Acceptance Criteria:
//   BP: speaking+easy+isNew+streak=5 → XP=45
//   BP: todayXPForWord=10 → applyDailyWordCap returns 0
//   BP: streak=10 (%5==0) → 1.5x multiplier
//
// Çalıştır: flutter test test/srs/xp_calculator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pratikapp/srs/fsrs_state.dart';
import 'package:pratikapp/srs/mode_selector.dart';
import 'package:pratikapp/srs/xp_calculator.dart';

void main() {
  // ── calculateReviewXP — Blueprint Kriterleri ──────────────────────────────

  group('calculateReviewXP — Blueprint', () {
    test('BP: speaking + easy + isNew + streak=5 → 45 XP', () {
      // base=20, r=1.25, new=5 → (20*1.25+5)*1.5*1.0 = (25+5)*1.5 = 45
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.speaking,
        rating: ReviewRating.easy,
        isNew: true,
        streak: 5,
        hasBonus: false,
      );
      expect(xp, 45);
    });

    test('BP: streak=10 (%5==0) → 1.5x multiplier uygulanır', () {
      final xpStreak10 = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.good,
        isNew: false,
        streak: 10,
        hasBonus: false,
      );
      final xpStreak9 = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.good,
        isNew: false,
        streak: 9,
        hasBonus: false,
      );
      // streak=10: 10*1.0*1.5 = 15, streak=9: 10*1.0*1.0 = 10
      expect(xpStreak10, 15);
      expect(xpStreak9, 10);
      expect(xpStreak10, greaterThan(xpStreak9));
    });

    test('again → 0 XP (ratingMultiplier=0.0)', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.speaking,
        rating: ReviewRating.again,
        isNew: true,
        streak: 10,
        hasBonus: true,
      );
      expect(xp, 0);
    });
  });

  // ── calculateReviewXP — Mode Base XP ─────────────────────────────────────

  group('calculateReviewXP — mode base XP', () {
    test('mcq + good + no streak + no bonus = 10', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.good,
        isNew: false,
        streak: 0,
        hasBonus: false,
      );
      expect(xp, 10); // 10 * 1.0 * 1.0 = 10
    });

    test('listening + good + no streak = 15', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.listening,
        rating: ReviewRating.good,
        isNew: false,
        streak: 0,
        hasBonus: false,
      );
      expect(xp, 15); // 15 * 1.0 = 15
    });

    test('speaking + good + no streak = 20', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.speaking,
        rating: ReviewRating.good,
        isNew: false,
        streak: 0,
        hasBonus: false,
      );
      expect(xp, 20); // 20 * 1.0 = 20
    });

    test('speaking > listening > mcq (aynı koşullar)', () {
      int xp(StudyMode m) => XPCalculator.calculateReviewXP(
            mode: m,
            rating: ReviewRating.good,
            isNew: false,
            streak: 0,
            hasBonus: false,
          );
      expect(xp(StudyMode.speaking), greaterThan(xp(StudyMode.listening)));
      expect(xp(StudyMode.listening), greaterThan(xp(StudyMode.mcq)));
    });
  });

  // ── calculateReviewXP — Rating Multiplier ────────────────────────────────

  group('calculateReviewXP — rating multiplier', () {
    test('hard = 0.75x → mcq+hard = floor(10*0.75) = 7', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.hard,
        isNew: false,
        streak: 0,
        hasBonus: false,
      );
      expect(xp, 7);
    });

    test('easy = 1.25x → mcq+easy = floor(10*1.25) = 12', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.easy,
        isNew: false,
        streak: 0,
        hasBonus: false,
      );
      expect(xp, 12);
    });

    test('easy > good > hard > again sıralaması', () {
      int xp(ReviewRating r) => XPCalculator.calculateReviewXP(
            mode: StudyMode.mcq,
            rating: r,
            isNew: false,
            streak: 0,
            hasBonus: false,
          );
      expect(xp(ReviewRating.easy), greaterThan(xp(ReviewRating.good)));
      expect(xp(ReviewRating.good), greaterThan(xp(ReviewRating.hard)));
      expect(xp(ReviewRating.hard), greaterThan(xp(ReviewRating.again)));
      expect(xp(ReviewRating.again), 0);
    });
  });

  // ── calculateReviewXP — isNew Bonus ──────────────────────────────────────

  group('calculateReviewXP — isNew bonus', () {
    test('isNew=true → +5 XP (mcq+good+noStreak)', () {
      final withNew = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.good,
        isNew: true,
        streak: 0,
        hasBonus: false,
      );
      final withoutNew = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.good,
        isNew: false,
        streak: 0,
        hasBonus: false,
      );
      expect(withNew - withoutNew, 5);
    });

    test('isNew bonus again ile gelse de 0 (again multiplier=0)', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.speaking,
        rating: ReviewRating.again,
        isNew: true,
        streak: 5,
        hasBonus: false,
      );
      expect(xp, 0);
    });
  });

  // ── calculateReviewXP — Streak Multiplier ────────────────────────────────

  group('calculateReviewXP — streak multiplier', () {
    test('streak=0 → 1.0x', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.good,
        isNew: false,
        streak: 0,
        hasBonus: false,
      );
      expect(xp, 10); // 10*1.0
    });

    test('streak=1 → 1.0x (5\'in katı değil)', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.good,
        isNew: false,
        streak: 1,
        hasBonus: false,
      );
      expect(xp, 10);
    });

    test('streak=5 → 1.5x', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.good,
        isNew: false,
        streak: 5,
        hasBonus: false,
      );
      expect(xp, 15); // 10*1.5
    });

    test('streak=15 → 1.5x', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.good,
        isNew: false,
        streak: 15,
        hasBonus: false,
      );
      expect(xp, 15);
    });

    test('streak=7 → 1.0x (5\'in katı değil)', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.good,
        isNew: false,
        streak: 7,
        hasBonus: false,
      );
      expect(xp, 10);
    });
  });

  // ── calculateReviewXP — Rewarded Ad Bonus ────────────────────────────────

  group('calculateReviewXP — hasBonus (doubleXP)', () {
    test('hasBonus=true → 2x (mcq+good = 10 → 20)', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.good,
        isNew: false,
        streak: 0,
        hasBonus: true,
      );
      expect(xp, 20);
    });

    test('hasBonus + streak=5 → 2x × 1.5x (mcq+good = 30)', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.mcq,
        rating: ReviewRating.good,
        isNew: false,
        streak: 5,
        hasBonus: true,
      );
      expect(xp, 30); // 10 * 1.5 * 2.0 = 30
    });

    test('hasBonus + again → 0 (again her zaman 0)', () {
      final xp = XPCalculator.calculateReviewXP(
        mode: StudyMode.speaking,
        rating: ReviewRating.again,
        isNew: false,
        streak: 0,
        hasBonus: true,
      );
      expect(xp, 0);
    });
  });

  // ── applyDailyWordCap ─────────────────────────────────────────────────────

  group('applyDailyWordCap', () {
    test('BP: todayXPForWord=10 → returns 0 (cap dolmuş)', () {
      final capped = XPCalculator.applyDailyWordCap(
        earnedXP: 5,
        todayXPForWord: 10,
      );
      expect(capped, 0);
    });

    test('todayXPForWord=0 → earnedXP tam verilir', () {
      final capped = XPCalculator.applyDailyWordCap(
        earnedXP: 8,
        todayXPForWord: 0,
      );
      expect(capped, 8);
    });

    test('todayXPForWord=3, earnedXP=8 → 7 (kalan cap kadar)', () {
      final capped = XPCalculator.applyDailyWordCap(
        earnedXP: 8,
        todayXPForWord: 3,
      );
      expect(capped, 7); // min(8, 10-3=7) = 7
    });

    test('todayXPForWord=15 (cap aşıldı) → 0', () {
      final capped = XPCalculator.applyDailyWordCap(
        earnedXP: 5,
        todayXPForWord: 15,
      );
      expect(capped, 0);
    });

    test('earnedXP=2, todayXPForWord=9 → 1 (kalan 1)', () {
      final capped = XPCalculator.applyDailyWordCap(
        earnedXP: 2,
        todayXPForWord: 9,
      );
      expect(capped, 1);
    });

    test('earnedXP=0 → 0 (XP kazanılmamış)', () {
      final capped = XPCalculator.applyDailyWordCap(
        earnedXP: 0,
        todayXPForWord: 0,
      );
      expect(capped, 0);
    });

    test('dailyWordCap sabiti = 10', () {
      expect(XPCalculator.dailyWordCap, 10);
    });
  });

  // ── Sabitler ──────────────────────────────────────────────────────────────

  group('XPCalculator sabitleri', () {
    test('newCardBonus = 5', () => expect(XPCalculator.newCardBonus, 5));
    test('streakMilestoneMultiplier = 1.5',
        () => expect(XPCalculator.streakMilestoneMultiplier, 1.5));
    test('rewardedAdMultiplier = 2.0',
        () => expect(XPCalculator.rewardedAdMultiplier, 2.0));
    test('modeBaseXP: mcq=10, listening=15, speaking=20', () {
      expect(XPCalculator.modeBaseXP[StudyMode.mcq], 10);
      expect(XPCalculator.modeBaseXP[StudyMode.listening], 15);
      expect(XPCalculator.modeBaseXP[StudyMode.speaking], 20);
    });
  });
}
