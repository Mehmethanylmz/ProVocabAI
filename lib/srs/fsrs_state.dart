// lib/srs/fsrs_state.dart
//
// Sıfır dış bağımlılık.
// FSRSEngine, StudyZoneBloc, SubmitReviewUseCase ve testler bu dosyayı kullanır.

/// Kullanıcının karta verdiği 4-lü yanıt puanı.
/// Blueprint G.2 UI: "Çok Zor / Zor / İyi / Kolay"
enum ReviewRating {
  again, // 1 — Tamamen unutuldu
  hard, // 2 — Zorlandı ama hatırlandı
  good, // 3 — Normal başarı (ReviewRatingSheet default)
  easy, // 4 — Çok kolay, interval uzasın
}

/// Kartın FSRS yaşam döngüsü aşaması.
/// DB sütununda 'new' | 'learning' | 'review' | 'relearning' olarak saklanır.
enum CardState {
  newCard, // 'new'
  learning, // 'learning'
  review, // 'review'
  relearning, // 'relearning'
}

extension CardStateExtension on CardState {
  String toDbString() {
    switch (this) {
      case CardState.newCard:
        return 'new';
      case CardState.learning:
        return 'learning';
      case CardState.review:
        return 'review';
      case CardState.relearning:
        return 'relearning';
    }
  }

  static CardState fromString(String s) {
    switch (s) {
      case 'learning':
        return CardState.learning;
      case 'review':
        return CardState.review;
      case 'relearning':
        return CardState.relearning;
      default:
        return CardState.newCard;
    }
  }
}

/// FSRS-4.5 kart durumu — immutable value object.
///
/// Veri akışı:
///   ProgressDao.getCardProgress() → FSRSState.fromProgressData()
///   FSRSEngine.updateCard(state, rating) → yeni FSRSState
///   ProgressCompanion (Drift write) → state alanları map edilir
class FSRSState {
  /// Kartın hafızada kalma süresi (gün). Clamp: 0.1 – 36500.
  final double stability;

  /// Öğrenme zorluğu. Clamp: 1.0 – 10.0.
  final double difficulty;

  /// Anlık hatırlama olasılığı (0.0 – 1.0).
  /// DB'ye yazılmaz; FSRSEngine.retrievability() ile anlık hesaplanır.
  final double retrievability;

  /// Mevcut yaşam döngüsü aşaması.
  final CardState cardState;

  /// Bir sonraki review hedef tarihi (UTC).
  final DateTime nextReview;

  /// Son review tarihi (UTC). Yeni kart: epoch (1970-01-01).
  final DateTime lastReview;

  /// Toplam başarılı review sayısı (again hariç tüm rating'ler).
  final int repetitions;

  /// Toplam "again" sayısı — LeechHandler bu değeri izler.
  final int lapses;

  const FSRSState({
    required this.stability,
    required this.difficulty,
    required this.retrievability,
    required this.cardState,
    required this.nextReview,
    required this.lastReview,
    required this.repetitions,
    required this.lapses,
  });

  // ── Factories ─────────────────────────────────────────────────────────────

  /// Hiç görülmemiş kart için FSRS-4.5 cold-start değerleri.
  /// Blueprint C.2.2: stability = w[2] = 0.5, difficulty = w[4] = 5.0
  factory FSRSState.coldStart() => FSRSState(
        stability: 0.5,
        difficulty: 5.0,
        retrievability: 1.0,
        cardState: CardState.newCard,
        nextReview: DateTime.now().toUtc(),
        lastReview: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        repetitions: 0,
        lapses: 0,
      );

  /// ProgressDao satırından FSRSState üret.
  /// ProgressDao.getCardProgress() → bu factory → FSRSEngine.updateCard()
  factory FSRSState.fromProgressData({
    required double stability,
    required double difficulty,
    required String cardStateStr,
    required int nextReviewMs,
    required int lastReviewMs,
    required int repetitions,
    required int lapses,
  }) =>
      FSRSState(
        stability: stability,
        difficulty: difficulty,
        retrievability: 1.0, // FSRSEngine.retrievability() ile yenilenir
        cardState: CardStateExtension.fromString(cardStateStr),
        nextReview:
            DateTime.fromMillisecondsSinceEpoch(nextReviewMs, isUtc: true),
        lastReview:
            DateTime.fromMillisecondsSinceEpoch(lastReviewMs, isUtc: true),
        repetitions: repetitions,
        lapses: lapses,
      );

  // ── DB helpers ────────────────────────────────────────────────────────────

  String get cardStateString => cardState.toDbString();

  // ── copyWith ──────────────────────────────────────────────────────────────

  FSRSState copyWith({
    double? stability,
    double? difficulty,
    double? retrievability,
    CardState? cardState,
    DateTime? nextReview,
    DateTime? lastReview,
    int? repetitions,
    int? lapses,
  }) =>
      FSRSState(
        stability: stability ?? this.stability,
        difficulty: difficulty ?? this.difficulty,
        retrievability: retrievability ?? this.retrievability,
        cardState: cardState ?? this.cardState,
        nextReview: nextReview ?? this.nextReview,
        lastReview: lastReview ?? this.lastReview,
        repetitions: repetitions ?? this.repetitions,
        lapses: lapses ?? this.lapses,
      );

  @override
  String toString() => 'FSRSState(s=${stability.toStringAsFixed(4)}, '
      'd=${difficulty.toStringAsFixed(4)}, '
      'r=${retrievability.toStringAsFixed(4)}, '
      '${cardState.toDbString()}, '
      'reps=$repetitions, lapses=$lapses)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FSRSState &&
          stability == other.stability &&
          difficulty == other.difficulty &&
          cardState == other.cardState &&
          repetitions == other.repetitions &&
          lapses == other.lapses;

  @override
  int get hashCode =>
      Object.hash(stability, difficulty, cardState, repetitions, lapses);
}
