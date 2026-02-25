// lib/srs/fsrs_engine.dart
//
// FSRS-4.5 referans implementasyonu — sıfır dış bağımlılık, sadece dart:math.
//
// Referans: https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm
// w[17] default değerleri: open-spaced-repetition/fsrs4anki (FSRS-4.5 branch)
// AC-01: Bu dosyadaki tüm metodlar test/srs/fsrs_engine_test.dart ile %100 kapsanmalı.

import 'dart:math' as math;

import 'fsrs_state.dart';

/// FSRS-4.5 algoritması — pure Dart, stateless, const constructor.
///
/// Kullanım (T-10 StudyZoneBloc._onAnswerSubmitted):
///   final engine = const FSRSEngine();
///   final newState = engine.updateCard(currentState, ReviewRating.good);
///   // → newState.nextReview, newState.stability değişti
///   await progressDao.upsertProgress(newState.toCompanion(...));
class FSRSEngine {
  // ── FSRS-4.5 w[17] Default Parametreleri ─────────────────────────────────
  //
  // Kaynak: open-spaced-repetition/fsrs4anki FSRS-4.5 default weights
  // [0.4072, 1.1829, 3.1262, 15.4722, 7.2102, 0.5316, 1.0651, 0.0589,
  //  1.5330, 0.1544, 1.0070, 1.9395, 0.1100, 0.2900, 2.2700, 0.3070, 2.9898]
  //
  // w[0]  → S₀(again):  yeni kart 'again' rating → ilk stability
  // w[1]  → S₀(hard):   yeni kart 'hard'
  // w[2]  → S₀(good):   yeni kart 'good'  (cold-start default: 0.5 → 3.1262)
  // w[3]  → S₀(easy):   yeni kart 'easy'
  // w[4]  → D₀ base:    ilk difficulty hesabı
  // w[5]  → D' weight:  difficulty güncelleme ağırlığı
  // w[6]  → D' decay:   difficulty decay faktörü
  // w[7]  → SRF scale:  stabilityAfterRecall genel ölçek
  // w[8]  → SRF exp:    e^w[8] çarpanı
  // w[9]  → SRF S^:     S^(-w[9]) bileşeni
  // w[10] → SRF R:      e^(w[10]*(1-R)) bileşeni
  // w[11] → SFF scale:  stabilityAfterForgetting scale
  // w[12] → SFF S^:     S^w[12] bileşeni
  // w[13] → SFF D^:     D^(-w[13]) bileşeni
  // w[14] → SFF R:      (1-R)^w[14] bileşeni
  // w[15] → hard mult:  rating=hard → stability multiplier (<1)
  // w[16] → easy mult:  rating=easy → stability multiplier (>1)

  static const List<double> _defaultW = [
    0.4072, // w[0]
    1.1829, // w[1]
    3.1262, // w[2]  — S₀(good): initNewCard(good).stability ≈ 3.1
    15.4722, // w[3]
    7.2102, // w[4]  — D₀ base
    0.5316, // w[5]
    1.0651, // w[6]
    0.0589, // w[7]
    1.5330, // w[8]
    0.1544, // w[9]
    1.0070, // w[10]
    1.9395, // w[11]
    0.1100, // w[12]
    0.2900, // w[13]
    2.2700, // w[14]
    0.3070, // w[15] — hard multiplier
    2.9898, // w[16] — easy multiplier
  ];

  /// Desired retention: 90% — FSRS-4.5 standard.
  /// interval = S * (R^(1/C) - 1) / (19/81) formülünde kullanılır.
  static const double desiredRetention = 0.9;

  /// Difficulty sınır değerleri.
  static const double _minDifficulty = 1.0;
  static const double _maxDifficulty = 10.0;

  /// Stability sınır değerleri (R-15 mitigation: dart:math log/exp hassasiyeti).
  static const double _minStability = 0.1;
  static const double _maxStability = 36500.0; // ~100 yıl

  /// Mod bazlı stability çarpanları (Blueprint T-03).
  /// listening/speaking modları biraz daha zor → stability düşük başlar.
  static const Map<String, double> modeStabilityMultiplier = {
    'mcq': 1.0,
    'listening': 0.92,
    'speaking': 0.88,
  };

  final List<double> w;

  const FSRSEngine({List<double>? weights}) : w = weights ?? _defaultW;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Yeni (hiç görülmemiş) kart için ilk state'i hesapla.
  ///
  /// Blueprint T-03 test: initNewCard(good).stability ≈ 3.1
  /// Dönüş: CardState.learning (again/hard/good) | CardState.review (easy)
  ///
  /// [mode]: 'mcq' | 'listening' | 'speaking' — modeStabilityMultiplier uygulanır.
  FSRSState initNewCard(ReviewRating rating, {String mode = 'mcq'}) {
    final rawStability = _initStability(rating);
    final mult = modeStabilityMultiplier[mode] ?? 1.0;
    final stability = _clampStability(rawStability * mult);
    final difficulty = _initDifficulty(rating);

    // Yeni kartlarda: again/hard/good → learning, easy → direkt review
    final nextState =
        rating == ReviewRating.easy ? CardState.review : CardState.learning;

    final interval = rating == ReviewRating.easy
        ? _nextInterval(stability)
        : 1; // learning adımı: 1 gün sonra tekrar

    final now = DateTime.now().toUtc();

    return FSRSState(
      stability: stability,
      difficulty: difficulty,
      retrievability: 1.0,
      cardState: nextState,
      nextReview: now.add(Duration(days: interval)),
      lastReview: now,
      repetitions: rating == ReviewRating.again ? 0 : 1,
      lapses: rating == ReviewRating.again ? 1 : 0,
    );
  }

  /// Mevcut kartı verilen rating'e göre güncelle.
  ///
  /// Blueprint T-03 test:
  ///   updateCard(state, again).lapses == state.lapses + 1
  ///   updateCard(state, good).cardState == CardState.review (eğer review'daydısa)
  ///
  /// [mode]: modeStabilityMultiplier için.
  FSRSState updateCard(
    FSRSState state,
    ReviewRating rating, {
    String mode = 'mcq',
  }) {
    final now = DateTime.now().toUtc();
    final elapsed = _elapsedDays(state.lastReview, now);
    final r = retrievability(elapsed, state.stability);

    if (rating == ReviewRating.again) {
      return _handleForgetting(state, r, now);
    }
    return _handleRecall(state, rating, r, elapsed, now, mode);
  }

  /// Belirli bir zamanda kartın hatırlanma olasılığını hesapla.
  ///
  /// FSRS-4.5 forgetting curve:
  ///   R(t, S) = (1 + (19/81) * (t/S))^(-0.5)
  ///
  /// t=0 → R=1.0, t=S → R=0.9 (desired retention noktası)
  double retrievability(double elapsedDays, double stability) {
    if (stability <= 0) return 0.0;
    const f = 19.0 / 81.0; // decay factor
    const c = -0.5; // power exponent
    return math.pow(1.0 + f * (elapsedDays / stability), c).toDouble();
  }

  /// Şu anki kart durumuna göre anlık retrievability.
  double currentRetrievability(FSRSState state) {
    final elapsed = _elapsedDays(state.lastReview, DateTime.now().toUtc());
    return retrievability(elapsed, state.stability);
  }

  /// stability → interval (gün) dönüşümü.
  ///
  /// FSRS-4.5: I = S * ln(DR) / ln(0.9)
  /// Bu da: I = S * (DR^(1/C) - 1) / (19/81) ile eşdeğerdir.
  ///
  /// Minimum 1 gün garantisi (R-15 mitigation).
  int nextIntervalDays(double stability) => _nextInterval(stability);

  // ── Private: New Card ─────────────────────────────────────────────────────

  /// S₀(G): ilk stability — rating'e göre w[0..3] indexlenir.
  double _initStability(ReviewRating rating) {
    switch (rating) {
      case ReviewRating.again:
        return w[0];
      case ReviewRating.hard:
        return w[1];
      case ReviewRating.good:
        return w[2];
      case ReviewRating.easy:
        return w[3];
    }
  }

  /// D₀(G): ilk difficulty.
  /// D₀ = w[4] - (G-3) * w[5]
  /// G: again=1, hard=2, good=3, easy=4
  double _initDifficulty(ReviewRating rating) {
    final g = _ratingToInt(rating);
    final d = w[4] - (g - 3) * w[5];
    return _clampDifficulty(d);
  }

  // ── Private: Recall (hard/good/easy) ─────────────────────────────────────

  FSRSState _handleRecall(
    FSRSState state,
    ReviewRating rating,
    double r,
    double elapsed,
    DateTime now,
    String mode,
  ) {
    final newDifficulty = _updateDifficulty(state.difficulty, rating);
    final rawStability = _stabilityAfterRecall(
      state.difficulty,
      state.stability,
      r,
      rating,
    );
    final mult = modeStabilityMultiplier[mode] ?? 1.0;
    final newStability = _clampStability(rawStability * mult);

    // learning kartı yeterince stabil ise review'a geç (stability > 1 gün)
    final newCardState = _nextCardState(state.cardState, newStability);

    final interval = _nextInterval(newStability);

    return state.copyWith(
      stability: newStability,
      difficulty: newDifficulty,
      retrievability: r,
      cardState: newCardState,
      nextReview: now.add(Duration(days: interval)),
      lastReview: now,
      repetitions: state.repetitions + 1,
    );
  }

  // ── Private: Forgetting (again) ───────────────────────────────────────────

  FSRSState _handleForgetting(FSRSState state, double r, DateTime now) {
    final newDifficulty =
        _updateDifficulty(state.difficulty, ReviewRating.again);
    final newStability = _clampStability(
      _stabilityAfterForgetting(state.difficulty, state.stability, r),
    );
    final newLapses = state.lapses + 1;

    return state.copyWith(
      stability: newStability,
      difficulty: newDifficulty,
      retrievability: r,
      cardState: CardState.relearning,
      nextReview: now.add(const Duration(days: 1)),
      lastReview: now,
      lapses: newLapses,
    );
  }

  // ── Private: Core FSRS-4.5 Formulas ──────────────────────────────────────

  /// D'(D, G) = D - w[6] * (G - 3)
  /// Sonra mean-reversion: D' = w[5]*D₀(good) + (1-w[5])*D'
  double _updateDifficulty(double d, ReviewRating rating) {
    final g = _ratingToInt(rating);
    // Adım 1: linear shift
    final dPrime = d - w[6] * (g - 3);
    // Adım 2: mean-reversion (D₀(good) = w[4] - 0 * w[5] = w[4])
    final d0Good = w[4];
    final reverted = w[5] * d0Good + (1 - w[5]) * dPrime;
    return _clampDifficulty(reverted);
  }

  /// S'r(D, S, R, G) — Recall sonrası stability artışı.
  ///
  /// FSRS-4.5:
  ///   S'r = S * (e^w[8] * (11-D) * S^(-w[9]) * (e^(w[10]*(1-R))-1)
  ///            * w[15] [if hard] * w[16] [if easy] + 1)
  double _stabilityAfterRecall(
    double d,
    double s,
    double r,
    ReviewRating rating,
  ) {
    double multiplier = 1.0;
    if (rating == ReviewRating.hard) multiplier = w[15];
    if (rating == ReviewRating.easy) multiplier = w[16];

    final sInc = math.exp(w[8]) *
        (11.0 - d) *
        math.pow(s, -w[9]) *
        (math.exp(w[10] * (1.0 - r)) - 1.0) *
        multiplier;

    return s * (sInc + 1.0);
  }

  /// S'f(D, S, R) — Forgetting (again) sonrası stability.
  ///
  /// FSRS-4.5:
  ///   S'f = w[11] * D^(-w[12]) * ((S+1)^w[13] - 1) * e^(w[14]*(1-R))
  ///   min(S'f, S) — lapse sonrası stability asla öncekinden yüksek olamaz
  double _stabilityAfterForgetting(double d, double s, double r) {
    final sf = w[11] *
        math.pow(d, -w[12]) *
        (math.pow(s + 1.0, w[13]) - 1.0) *
        math.exp(w[14] * (1.0 - r));
    // Lapse sonrası stability öncekinden yüksek olamaz (R-15)
    return math.min(sf, s);
  }

  /// stability → interval (gün).
  ///
  /// I = S * ln(DR) / ln(0.9) ≡ S * log_{0.9}(DR)
  /// desiredRetention = 0.9 → I ≈ S (çünkü log_{0.9}(0.9) = 1)
  ///
  /// R-15: minimum 1, maximum 36500 gün (clamp).
  int _nextInterval(double stability) {
    final i = stability * math.log(desiredRetention) / math.log(0.9);
    return i.clamp(1.0, _maxStability).round();
  }

  // ── Private: Card State Transitions ──────────────────────────────────────

  CardState _nextCardState(CardState current, double newStability) {
    switch (current) {
      case CardState.newCard:
      case CardState.learning:
        // stability > 1 gün → review'a terfi
        return newStability > 1.0 ? CardState.review : CardState.learning;
      case CardState.review:
        return CardState.review;
      case CardState.relearning:
        return newStability > 1.0 ? CardState.review : CardState.relearning;
    }
  }

  // ── Private: Utils ────────────────────────────────────────────────────────

  /// İki tarih arasındaki gün farkı (kesirli, UTC).
  double _elapsedDays(DateTime from, DateTime to) {
    final ms = to.difference(from).inMilliseconds;
    return ms / Duration.millisecondsPerDay;
  }

  int _ratingToInt(ReviewRating rating) {
    switch (rating) {
      case ReviewRating.again:
        return 1;
      case ReviewRating.hard:
        return 2;
      case ReviewRating.good:
        return 3;
      case ReviewRating.easy:
        return 4;
    }
  }

  double _clampDifficulty(double d) => d.clamp(_minDifficulty, _maxDifficulty);

  double _clampStability(double s) => s.clamp(_minStability, _maxStability);
}
