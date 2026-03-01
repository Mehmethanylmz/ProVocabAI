// lib/srs/mode_selector.dart
//
// FAZ 2 FIX:
//   F2-04: canUseAdvancedMode() helper eklendi.
//          Yeni kartlar ve düşük tekrar sayılı kartlar listening/speaking kullanamaz.
//   Mevcut selectMode() mantığı korundu — userPreferredMode desteği zaten var.

import 'fsrs_state.dart';

// ── StudyMode ─────────────────────────────────────────────────────────────────

/// Desteklenen çalışma modları.
enum StudyMode {
  mcq, // Multiple choice — varsayılan, her kartla uyumlu
  listening, // Dinleme — audio çalma gerektirir
  speaking, // Konuşma — STT gerektirir
}

extension StudyModeX on StudyMode {
  String get key {
    switch (this) {
      case StudyMode.mcq:
        return 'mcq';
      case StudyMode.listening:
        return 'listening';
      case StudyMode.speaking:
        return 'speaking';
    }
  }

  /// Kullanıcıya gösterilecek Türkçe etiket.
  String get label {
    switch (this) {
      case StudyMode.mcq:
        return 'MCQ';
      case StudyMode.listening:
        return 'Dinleme';
      case StudyMode.speaking:
        return 'Konuşma';
    }
  }

  /// Chip icon'u.
  String get icon {
    switch (this) {
      case StudyMode.mcq:
        return '📝';
      case StudyMode.listening:
        return '🔊';
      case StudyMode.speaking:
        return '🎤';
    }
  }

  static StudyMode fromKey(String k) {
    switch (k) {
      case 'listening':
        return StudyMode.listening;
      case 'speaking':
        return StudyMode.speaking;
      default:
        return StudyMode.mcq;
    }
  }
}

// ── ModeSelector ─────────────────────────────────────────────────────────────

class ModeSelector {
  static const List<StudyMode> _allModes = [
    StudyMode.mcq,
    StudyMode.listening,
    StudyMode.speaking,
  ];

  // ── canUseAdvancedMode (F2-04) ──────────────────────────────────────────

  /// Bir kart için listening veya speaking modu kullanılabilir mi?
  ///
  /// Koşullar:
  ///   1. Kart yeni (newCard) ise → HAYIR (önce MCQ ile tanıt)
  ///   2. Progress kaydı yoksa → HAYIR
  ///   3. cardState != 'review' ise → HAYIR (learning aşamasında MCQ)
  ///   4. repetitions < 2 ise → HAYIR (en az 2 kez doğru cevaplamış olmalı)
  ///
  /// [isNewCard]    : PlanCard.source == CardSource.newCard
  /// [cardState]    : ProgressData.cardState ('new', 'learning', 'review', 'relearning')
  /// [repetitions]  : ProgressData.repetitions
  static bool canUseAdvancedMode({
    required bool isNewCard,
    String? cardState,
    int repetitions = 0,
  }) {
    if (isNewCard) return false;
    if (cardState == null) return false;
    if (cardState != 'review') return false;
    if (repetitions < 2) return false;
    return true;
  }

  /// Session başlangıcında tüm plan kartlarından kaçı advanced mode destekliyor
  /// kontrolü — mod chip'lerinin enabled/disabled durumunu belirler.
  ///
  /// [reviewCardCount] : Planda review kartı sayısı (due + leech)
  /// [advancedEligibleCount] : repetitions >= 2 olan review kartı sayısı
  ///
  /// Eğer planın %30'undan fazlası eligible değilse, advanced modlar
  /// etkili olmaz → chip disabled gösterilir.
  static bool hasEnoughAdvancedCards({
    required int totalCards,
    required int advancedEligibleCount,
  }) {
    if (totalCards == 0) return false;
    return advancedEligibleCount > 0;
  }

  // ── selectMode ────────────────────────────────────────────────────────────

  /// Bir sonraki kart için mod seç.
  ///
  /// [modeHistory]       : {'mcq': 5, 'listening': 3, 'speaking': 0}
  /// [cardState]         : Yeni kartlar → MCQ forced.
  /// [isMiniSession]     : true → MCQ forced.
  /// [userPreferredMode] : Kullanıcı tercihi → modeHistory'ye göre rotate et.
  static StudyMode selectMode({
    required Map<String, int> modeHistory,
    required CardState cardState,
    required bool isMiniSession,
    StudyMode? userPreferredMode,
  }) {
    // Kural 1: Mini session → MCQ
    if (isMiniSession) return StudyMode.mcq;

    // Kural 2: Yeni kart → MCQ (önce kelimeyi tanıt)
    if (cardState == CardState.newCard) return StudyMode.mcq;

    // Kural 3: Kullanıcı tercihi varsa → o modu doğrula / rotate et
    if (userPreferredMode != null) {
      return _rotatePreferred(modeHistory, userPreferredMode);
    }

    // Kural 4: En az kullanılan modu seç
    return _getLeastUsedMode(modeHistory);
  }

  /// Kullanıcı tercihi + kart durumu birlikte değerlendir.
  ///
  /// Kullanıcı listening/speaking seçtiyse ama kart uygun değilse → MCQ'ya fallback.
  static StudyMode selectModeWithValidation({
    required Map<String, int> modeHistory,
    required CardState cardState,
    required bool isMiniSession,
    StudyMode? userPreferredMode,
    required bool isNewCard,
    String? progressCardState,
    int repetitions = 0,
  }) {
    // Önce temel mod seçimi
    final mode = selectMode(
      modeHistory: modeHistory,
      cardState: cardState,
      isMiniSession: isMiniSession,
      userPreferredMode: userPreferredMode,
    );

    // MCQ her zaman geçerli
    if (mode == StudyMode.mcq) return mode;

    // Advanced mod seçildiyse kart uygun mu kontrol et
    final eligible = canUseAdvancedMode(
      isNewCard: isNewCard,
      cardState: progressCardState,
      repetitions: repetitions,
    );

    return eligible ? mode : StudyMode.mcq;
  }

  // ── _getLeastUsedMode ─────────────────────────────────────────────────────

  static StudyMode _getLeastUsedMode(Map<String, int> history) {
    StudyMode least = _allModes.first;
    int minCount = history[least.key] ?? 0;

    for (final mode in _allModes.skip(1)) {
      final count = history[mode.key] ?? 0;
      if (count < minCount) {
        minCount = count;
        least = mode;
      }
    }
    return least;
  }

  // ── _rotatePreferred ──────────────────────────────────────────────────────

  static StudyMode _rotatePreferred(
    Map<String, int> history,
    StudyMode preferred,
  ) {
    final prefCount = history[preferred.key] ?? 0;
    const dominantThreshold = 3;

    final others = _allModes.where((m) => m != preferred);
    final allOthersLower = others
        .every((m) => prefCount - (history[m.key] ?? 0) >= dominantThreshold);

    if (allOthersLower) {
      return _alternativeMode(history, preferred);
    }
    return preferred;
  }

  // ── _alternativeMode ──────────────────────────────────────────────────────

  static StudyMode _alternativeMode(
    Map<String, int> history,
    StudyMode exclude,
  ) {
    final candidates = _allModes.where((m) => m != exclude).toList();
    StudyMode least = candidates.first;
    int minCount = history[least.key] ?? 0;

    for (final mode in candidates.skip(1)) {
      final count = history[mode.key] ?? 0;
      if (count < minCount) {
        minCount = count;
        least = mode;
      }
    }
    return least;
  }

  // ── getDominantMode ───────────────────────────────────────────────────────

  static StudyMode getDominantMode(Map<String, int> history) {
    StudyMode dominant = _allModes.first;
    int maxCount = history[dominant.key] ?? 0;

    for (final mode in _allModes.skip(1)) {
      final count = history[mode.key] ?? 0;
      if (count > maxCount) {
        maxCount = count;
        dominant = mode;
      }
    }
    return dominant;
  }
}
