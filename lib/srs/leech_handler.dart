// lib/srs/leech_handler.dart
//
// Blueprint T-05: LeechHandler — sıfır dış bağımlılık.
// FSRSState (T-03) bağımlılığı var, başka paket yok.
//
// Kullanım (T-10 StudyZoneBloc._onAnswerSubmitted):
//   final decision = LeechHandler.evaluate(lapses: newState.lapses, repetitions: newState.repetitions);
//   if (decision == LeechDecision.markLeech) {
//     await progressDao.upsertProgress(...isLeech: true);
//   } else if (decision == LeechDecision.suspend) {
//     await progressDao.upsertProgress(...isSuspended: true);
//   }

import 'fsrs_state.dart';

// ── LeechDecision ─────────────────────────────────────────────────────────────

/// LeechHandler.evaluate() dönüş değeri.
enum LeechDecision {
  /// Normal — hiçbir şey yapma.
  none,

  /// lapses >= leechThreshold → isLeech=true yap, kullanıcıya uyar.
  markLeech,

  /// lapses >= suspendThreshold → isSuspended=true yap, plandan çıkar.
  suspend,
}

// ── LeechHandler ─────────────────────────────────────────────────────────────

/// Leech tespiti ve yönetimi — stateless, tüm metodlar pure function.
///
/// Thresholdlar Blueprint D.1.2'den:
///   leechThreshold=4   → markLeech
///   suspendThreshold=8 → suspend
class LeechHandler {
  /// Kaç "again" sonrası leech işaretlenir.
  static const int leechThreshold = 4;

  /// Kaç "again" sonrası kart askıya alınır (plandan çıkar).
  static const int suspendThreshold = 8;

  /// Rewarded ad ile leech'i atlama — stability boost.
  static const double rewardedStabilityBoost = 1.5;

  // ── evaluate ─────────────────────────────────────────────────────────────

  /// Mevcut lapse sayısına göre ne yapılacağını belirle.
  ///
  /// Blueprint T-05:
  ///   lapses=4  → LeechDecision.markLeech
  ///   lapses=8  → LeechDecision.suspend
  ///   lapses<4  → LeechDecision.none
  ///
  /// [lapses]      : FSRSState.lapses (toplam "again" sayısı)
  /// [repetitions] : FSRSState.repetitions — rezerv parametre (gelecek: recovery ratio)
  static LeechDecision evaluate({
    required int lapses,
    required int repetitions,
  }) {
    if (lapses >= suspendThreshold) return LeechDecision.suspend;
    if (lapses >= leechThreshold) return LeechDecision.markLeech;
    return LeechDecision.none;
  }

  // ── resetForRelearning ────────────────────────────────────────────────────

  /// Leech kartı yeniden öğrenme moduna sıfırla.
  ///
  /// Yapılan değişiklikler:
  ///   - cardState → relearning
  ///   - stability → w[0] (FSRS-4.5 again initial) = 0.4072
  ///   - nextReview → şimdi (hemen tekrar göster)
  ///   - repetitions → 0 (yeniden başlıyor)
  ///
  /// lapses değişmez — leech geçmişi korunur.
  static FSRSState resetForRelearning(FSRSState state) {
    return state.copyWith(
      cardState: CardState.relearning,
      stability: 0.4072, // FSRS-4.5 w[0] default
      nextReview: DateTime.now().toUtc(),
      repetitions: 0,
    );
  }

  // ── applyRewardedBoost ────────────────────────────────────────────────────

  /// Rewarded reklam izlendi → leech kartına stability boost uygula.
  ///
  /// Blueprint G.4: RewardType.skipLeech → "Zor kelimeyi atla"
  /// Boost: stability × rewardedStabilityBoost (1.5x)
  /// isLeech → false (bir şans daha)
  /// nextReview → 1 gün sonra (grace period)
  ///
  /// Suspended kartlara uygulanmaz — önce manüel unsuspend gerekir.
  static FSRSState applyRewardedBoost(FSRSState state) {
    final boostedStability =
        (state.stability * rewardedStabilityBoost).clamp(0.1, 36500.0);
    return state.copyWith(
      stability: boostedStability,
      nextReview: DateTime.now().toUtc().add(const Duration(days: 1)),
    );
  }

  // ── isLeech / isSuspended helpers ─────────────────────────────────────────

  /// Kart leech mi? (suspend dahil)
  static bool isLeech(int lapses) => lapses >= leechThreshold;

  /// Kart suspend edilmeli mi?
  static bool isSuspended(int lapses) => lapses >= suspendThreshold;
}
