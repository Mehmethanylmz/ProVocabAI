// lib/srs/plan_models.dart
// Sıfır dış bağımlılık — Flutter, Drift import edilmez.

/// Bir planın içindeki tek kartın kaynağı.
enum CardSource {
  leech, // lapses >= 4 — plana BAŞA alınır
  due, // next_review_ms <= now
  newCard, // progress kaydı yok (ilk kez görülecek)
}

/// Boş plan nedeni — StudyZoneBloc.StudyZoneIdle(emptyReason) için.
enum EmptyReason {
  noCardsAvailable,
  allDone,
  newWordsCapReached,
}

/// Günlük plandaki tek kart girişi.
class PlanCard {
  final int wordId;
  final CardSource source;

  /// ModeSelector başlangıç tercihi — null → ModeSelector karar verir.
  final String? suggestedMode;

  const PlanCard({
    required this.wordId,
    required this.source,
    this.suggestedMode,
  });

  @override
  String toString() => 'PlanCard($wordId, ${source.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanCard && wordId == other.wordId && source == other.source;

  @override
  int get hashCode => Object.hash(wordId, source);
}

/// DailyPlanner.buildPlan() çıktısı — immutable.
///
/// StudyZoneBloc.StudyZoneReady(plan) olarak taşınır.
/// DailyPlanDao.upsertPlan() ile persist edilir.
class DailyPlan {
  final String targetLang;
  final String planDate; // 'YYYY-MM-DD'
  final List<PlanCard> cards; // interleave uygulanmış, sıralı
  final int dueCount;
  final int newCount;
  final int leechCount;
  final int estimatedMinutes;
  final DateTime createdAt;

  const DailyPlan({
    required this.targetLang,
    required this.planDate,
    required this.cards,
    required this.dueCount,
    required this.newCount,
    required this.leechCount,
    required this.estimatedMinutes,
    required this.createdAt,
  });

  int get totalCards => cards.length;
  bool get isEmpty => cards.isEmpty;

  /// DailyPlanDao.cardIdsJson için — jsonEncode ile serialize edilir.
  List<int> get cardIds => cards.map((c) => c.wordId).toList();

  @override
  String toString() => 'DailyPlan($planDate/$targetLang '
      'total=$totalCards due=$dueCount new=$newCount leech=$leechCount '
      '~${estimatedMinutes}min)';
}
