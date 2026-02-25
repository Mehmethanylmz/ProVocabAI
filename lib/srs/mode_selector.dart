// lib/srs/mode_selector.dart
//
// Blueprint T-05: ModeSelector — sıfır dış bağımlılık.
// CardState (T-03) bağımlılığı var.
//
// Kullanım (T-10 StudyZoneBloc._onSessionStarted / _onNextCard):
//   final mode = ModeSelector.selectMode(
//     modeHistory: {'mcq': 5, 'listening': 5, 'speaking': 0},
//     cardState: CardState.review,
//     isMiniSession: false,
//   );
//   // → 'speaking' (en az kullanılan)

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

/// Kart için hangi çalışma modunun seçileceğini belirler — stateless, pure.
///
/// Öncelik sırası:
///   1. isMiniSession=true → her zaman MCQ (Blueprint: mini session MCQ only)
///   2. cardState == newCard → MCQ (yeni kelime tanıtımı)
///   3. userPreferredMode != null → tercih edileni ver (history'ye göre rotate)
///   4. modeHistory'den en az kullanılanı seç
class ModeSelector {
  static const List<StudyMode> _allModes = [
    StudyMode.mcq,
    StudyMode.listening,
    StudyMode.speaking,
  ];

  // ── selectMode ────────────────────────────────────────────────────────────

  /// Bir sonraki kart için mod seç.
  ///
  /// [modeHistory]       : {'mcq': 5, 'listening': 3, 'speaking': 0}
  ///                       Eksik modlar 0 olarak değerlendirilir.
  /// [cardState]         : Yeni kartlar → MCQ forced.
  /// [isMiniSession]     : true → MCQ forced (Blueprint: mini=MCQ only).
  /// [userPreferredMode] : Kullanıcı tercihini modeHistory'ye göre rotate et.
  ///                       null → tamamen otomatik.
  ///
  /// Blueprint T-05 test:
  ///   modeHistory={mcq:5,listening:5,speaking:0} → 'speaking'
  ///   isMiniSession=true → 'mcq'
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

  // ── _getLeastUsedMode ─────────────────────────────────────────────────────

  /// modeHistory'deki en düşük count'lu modu döndür.
  ///
  /// Eşitlik durumunda: mcq < listening < speaking (enum sırası).
  ///
  /// Blueprint T-05: {mcq:5, listening:5, speaking:0} → speaking
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

  /// Kullanıcının tercih ettiği modu genel dengeye göre rotate et.
  ///
  /// Eğer tercih edilen mod dominant (diğerlerinden 3+ fazla) ise
  /// en az kullanılan alternatife geç, yoksa tercihi ver.
  static StudyMode _rotatePreferred(
    Map<String, int> history,
    StudyMode preferred,
  ) {
    final prefCount = history[preferred.key] ?? 0;
    final dominantThreshold = 3;

    // Diğer tüm modlardan fazla mı kullanılmış?
    final others = _allModes.where((m) => m != preferred);
    final allOthersLower = others
        .every((m) => prefCount - (history[m.key] ?? 0) >= dominantThreshold);

    if (allOthersLower) {
      // Dominant → alternatife geç
      return _alternativeMode(history, preferred);
    }
    return preferred;
  }

  // ── _alternativeMode ──────────────────────────────────────────────────────

  /// Belirtilen modun dışındaki en az kullanılan modu döndür.
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

  // ── _getDominantMode ──────────────────────────────────────────────────────

  /// History'deki en çok kullanılan modu döndür.
  /// Eşitlik: mcq > listening > speaking (enum sırası).
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
