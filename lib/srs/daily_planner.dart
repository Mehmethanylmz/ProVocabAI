// lib/srs/daily_planner.dart
//
// Blueprint T-04.
// Bağımlılıklar: ProgressDao, WordDao (T-02), PlanModels (T-04).
// FSRSEngine bağımlılığı YOK.
//
// Kullanım (T-10 StudyZoneBloc._onLoadPlan):
//   final plan = await DailyPlanner(progressDao: db.progressDao, wordDao: db.wordDao)
//     .buildPlan(targetLang: 'en', categories: ['a1'], newWordsGoal: 10, planDate: '2025-02-24');
//   await db.dailyPlanDao.upsertPlan(DailyPlansCompanion.insert(
//     planDate: plan.planDate, targetLang: plan.targetLang,
//     createdAt: plan.createdAt.millisecondsSinceEpoch,
//     cardIdsJson: Value(jsonEncode(plan.cardIds)),
//     totalCards: Value(plan.totalCards), dueCount: Value(plan.dueCount),
//     newCount: Value(plan.newCount), leechCount: Value(plan.leechCount),
//     estimatedMinutes: Value(plan.estimatedMinutes),
//   ));

import '../database/app_database.dart' hide DailyPlan;
import '../database/daos/progress_dao.dart';
import '../database/daos/word_dao.dart';
import 'plan_models.dart';

// ── Sabitler ─────────────────────────────────────────────────────────────────

class DailyPlannerConfig {
  /// Günlük maksimum overdue kart (Blueprint: overdueCapPerDay=50).
  static const int overdueCapPerDay = 50;

  /// Kaç due'dan sonra 1 new eklenir (Blueprint: her 3 due'dan 1 new).
  static const int dueToNewRatio = 3;

  /// Kart başına tahmini süre (dakika).
  static const double minutesPerCard = 0.4;

  static const int minEstimatedMinutes = 1;
  static const int maxEstimatedMinutes = 120;

  /// Plan başına maksimum leech kart.
  static const int maxLeechPerPlan = 20;
}

// ── DailyPlanner ─────────────────────────────────────────────────────────────

class DailyPlanner {
  final ProgressDao _progressDao;
  final WordDao _wordDao;

  const DailyPlanner({
    required ProgressDao progressDao,
    required WordDao wordDao,
  })  : _progressDao = progressDao,
        _wordDao = wordDao;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Günlük plan oluştur.
  ///
  /// AC-03: due>0 varken DailyPlan.isEmpty == false garantisi.
  /// AC-11: < 500ms (50 due + 10 new senaryosunda).
  Future<DailyPlan> buildPlan({
    required String targetLang,
    required List<String> categories,
    required int newWordsGoal,
    required String planDate,
  }) async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final todayStartMs =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    // 1. Leech kartlar
    final leechRows = await _progressDao.getLeechCards(
      targetLang: targetLang,
      categories: categories,
      limit: DailyPlannerConfig.maxLeechPerPlan,
    );
    final leechIds = leechRows.map((p) => p.wordId).toSet();

    // 2. Due kartlar (leech'ler hariç, cap uygulanır)
    final allDue = await _progressDao.getDueCards(
      targetLang: targetLang,
      categories: categories,
      beforeMs: nowMs,
      limit: DailyPlannerConfig.overdueCapPerDay + leechIds.length,
    );
    final dueOnly = allDue
        .where((p) => !leechIds.contains(p.wordId))
        .take(DailyPlannerConfig.overdueCapPerDay)
        .toList();

    // 3. Yeni kartlar (bugün görülenler düşülür)
    final doneToday = await _progressDao.getNewCardsDoneToday(
      targetLang: targetLang,
      todayStartMs: todayStartMs,
    );
    final remaining = (newWordsGoal - doneToday).clamp(0, newWordsGoal);
    final newWords = remaining > 0
        ? await _wordDao.getNewCards(
            targetLang: targetLang,
            categories: categories,
            limit: remaining,
          )
        : <Word>[];

    // 4. PlanCard dönüşümü
    final leechCards = leechRows
        .map((p) => PlanCard(wordId: p.wordId, source: CardSource.leech))
        .toList();
    final dueCards = dueOnly
        .map((p) => PlanCard(wordId: p.wordId, source: CardSource.due))
        .toList();
    final newCards = newWords
        .map((w) => PlanCard(wordId: w.id, source: CardSource.newCard))
        .toList();

    // 5. Interleave + DailyPlan
    final ordered = _interleave(
        leeches: leechCards, dueCards: dueCards, newCards: newCards);

    return DailyPlan(
      targetLang: targetLang,
      planDate: planDate,
      cards: ordered,
      dueCount: dueCards.length,
      newCount: newCards.length,
      leechCount: leechCards.length,
      estimatedMinutes: _estimateMinutes(ordered.length),
      createdAt: now,
    );
  }

  // ── Private: _interleave ──────────────────────────────────────────────────

  /// Blueprint: leech başa, sonra 3 due : 1 new döngüsü.
  ///
  /// 10 due + 5 new → [d,d,d,n, d,d,d,n, d,d,d,n, d,n, d] = 15 ✓
  List<PlanCard> _interleave({
    required List<PlanCard> leeches,
    required List<PlanCard> dueCards,
    required List<PlanCard> newCards,
  }) {
    final result = <PlanCard>[...leeches];
    int dueIdx = 0;
    int newIdx = 0;
    const ratio = DailyPlannerConfig.dueToNewRatio;

    while (dueIdx < dueCards.length || newIdx < newCards.length) {
      int added = 0;
      while (added < ratio && dueIdx < dueCards.length) {
        result.add(dueCards[dueIdx++]);
        added++;
      }
      if (added > 0 && newIdx < newCards.length) {
        result.add(newCards[newIdx++]);
      } else if (added == 0 && newIdx < newCards.length) {
        // due bitti, kalan new'leri toplu ekle
        result.addAll(newCards.sublist(newIdx));
        break;
      }
    }
    return result;
  }

  // ── Private: _estimateMinutes ─────────────────────────────────────────────

  int _estimateMinutes(int totalCards) {
    if (totalCards == 0) return 0;
    return (totalCards * DailyPlannerConfig.minutesPerCard).ceil().clamp(
          DailyPlannerConfig.minEstimatedMinutes,
          DailyPlannerConfig.maxEstimatedMinutes,
        );
  }
}

// ── DailyPlannerTestable Extension ───────────────────────────────────────────
//
// Private metodları unit test ortamında erişilebilir kılar.
// Üretim kodunda kullanılmaz.

extension DailyPlannerTestable on DailyPlanner {
  List<PlanCard> interleaveForTest({
    required List<PlanCard> leeches,
    required List<PlanCard> dueCards,
    required List<PlanCard> newCards,
  }) =>
      _interleave(leeches: leeches, dueCards: dueCards, newCards: newCards);

  int estimateMinutesForTest(int totalCards) => _estimateMinutes(totalCards);
}
