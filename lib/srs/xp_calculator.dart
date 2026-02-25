// lib/srs/xp_calculator.dart
//
// Blueprint T-06: XPCalculator — sıfır dış bağımlılık.
// ReviewRating (T-03) + StudyMode (T-05) kullanır.
//
// Kullanım (T-10 StudyZoneBloc._onAnswerSubmitted):
//   final xp = XPCalculator.calculateReviewXP(
//     mode: StudyMode.speaking, rating: ReviewRating.easy,
//     isNew: true, streak: 5, hasBonus: false,
//   );
//   final capped = XPCalculator.applyDailyWordCap(
//     earnedXP: xp, todayXPForWord: progressRow.todayXp,
//   );
//   // capped → Firestore profile.weeklyXp += capped

import 'fsrs_state.dart';
import 'mode_selector.dart';

// ── XPCalculator ──────────────────────────────────────────────────────────────

/// Review başına XP hesaplama — stateless, pure functions.
///
/// XP Formülü:
///   base     = modeBaseXP[mode]           (mcq:10, listening:15, speaking:20)
///   rated    = base × ratingMultiplier    (again:0.0, hard:0.75, good:1.0, easy:1.25)
///   withNew  = rated + (isNew ? newBonus : 0)  (newBonus=5)
///   streakM  = streak>0 && streak%5==0 ? 1.5 : 1.0
///   final    = floor(withNew × streakM × (hasBonus ? 2.0 : 1.0))
///
/// Anti-spam: applyDailyWordCap() ile kelime başına günlük 10 XP sınırı.
class XPCalculator {
  // ── Sabitler ──────────────────────────────────────────────────────────────

  /// Mode başına baz XP.
  /// Zorluk sırasına göre: MCQ < Listening < Speaking.
  static const Map<StudyMode, int> modeBaseXP = {
    StudyMode.mcq: 10,
    StudyMode.listening: 15,
    StudyMode.speaking: 20,
  };

  /// Rating çarpanları.
  /// again=0 → başarısız review XP kazandırmaz.
  static const Map<ReviewRating, double> ratingMultiplier = {
    ReviewRating.again: 0.0,
    ReviewRating.hard: 0.75,
    ReviewRating.good: 1.0,
    ReviewRating.easy: 1.25,
  };

  /// Yeni kart (ilk kez görülen) için ekstra XP.
  static const int newCardBonus = 5;

  /// Her 5 streak'te bir streak multiplier (anti-spam değil, motivasyon).
  /// streak > 0 && streak % 5 == 0 → 1.5x
  static const double streakMilestoneMultiplier = 1.5;

  /// Rewarded ad bonus multiplier (Blueprint G.4: doubleXP).
  static const double rewardedAdMultiplier = 2.0;

  /// Kelime başına günlük maksimum XP (anti-spam cap).
  /// todayXPForWord >= dailyWordCap → 0 XP kazanılır.
  static const int dailyWordCap = 10;

  // ── calculateReviewXP ─────────────────────────────────────────────────────

  /// Bir review için kazanılan XP'yi hesapla.
  ///
  /// [mode]      : 'mcq' | 'listening' | 'speaking'
  /// [rating]    : again / hard / good / easy
  /// [isNew]     : İlk kez görülen kart → +newCardBonus (5 XP)
  /// [streak]    : Mevcut oturum streak sayısı.
  ///               streak>0 && streak%5==0 → 1.5x multiplier
  /// [hasBonus]  : Rewarded ad izlendi → 2x (Blueprint G.4 doubleXP)
  ///
  /// Blueprint test:
  ///   speaking + easy + isNew + streak=5 → 45 XP
  ///   streak=10 (%5==0) → 1.5x uygulanır
  ///   again → 0 XP (ratingMultiplier=0.0)
  static int calculateReviewXP({
    required StudyMode mode,
    required ReviewRating rating,
    required bool isNew,
    required int streak,
    required bool hasBonus,
  }) {
    final base = modeBaseXP[mode] ?? 10;
    final rMult = ratingMultiplier[rating] ?? 0.0;

    // again → 0 (kısa devre)
    if (rMult == 0.0) return 0;

    final rated = base * rMult;
    final withNew = rated + (isNew ? newCardBonus : 0);
    final streakM = _streakMultiplier(streak);
    final bonusM = hasBonus ? rewardedAdMultiplier : 1.0;

    return (withNew * streakM * bonusM).floor();
  }

  // ── applyDailyWordCap ─────────────────────────────────────────────────────

  /// Anti-spam: kelime başına günlük XP sınırını uygula.
  ///
  /// [earnedXP]       : calculateReviewXP() sonucu
  /// [todayXPForWord] : Bu kelime için bugün kazanılmış toplam XP
  ///                    (progress.todayXp veya reviewEvents toplamı)
  ///
  /// Blueprint T-06 test:
  ///   todayXPForWord=10 → returns 0   (cap dolmuş)
  ///   todayXPForWord=3, earnedXP=8    → returns 7  (cap=10, kalan=7)
  ///   todayXPForWord=0, earnedXP=5    → returns 5  (tam)
  static int applyDailyWordCap({
    required int earnedXP,
    required int todayXPForWord,
  }) {
    final remaining = dailyWordCap - todayXPForWord;
    if (remaining <= 0) return 0;
    return earnedXP.clamp(0, remaining);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  /// streak > 0 ve 5'in katı → 1.5x, aksi halde 1.0x.
  static double _streakMultiplier(int streak) {
    if (streak > 0 && streak % 5 == 0) return streakMilestoneMultiplier;
    return 1.0;
  }
}
