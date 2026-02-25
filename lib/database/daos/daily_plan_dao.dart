import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/daily_plans_table.dart';

part 'daily_plan_dao.g.dart';

/// DailyPlanDao — Günlük çalışma planı kalıcılığı.
///
/// Her gün / dil kombinasyonu için tek kayıt tutulur (upsert).
/// Uygulama kapanıp açıldığında aynı günün planı yeniden hesaplanmaz,
/// persist edilmiş plan devam ettirilir.
///
/// T-04 DailyPlanner.buildPlan(): upsertPlan
/// T-10 StudyZoneBloc._onNextCard(): getTodayPlan (kart bitti mi kontrolü)
/// T-10 StudyZoneBloc._onAnswerSubmitted(): incrementCompleted
@DriftAccessor(tables: [DailyPlans])
class DailyPlanDao extends DatabaseAccessor<AppDatabase>
    with _$DailyPlanDaoMixin {
  DailyPlanDao(super.db);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Plan kaydet veya güncelle (aynı gün + dil için idempotent).
  /// DailyPlanner.buildPlan() çağırır.
  Future<void> upsertPlan(DailyPlansCompanion companion) =>
      into(dailyPlans).insertOnConflictUpdate(companion);

  /// Tamamlanan kart sayısını artır.
  /// StudyZoneBloc._onAnswerSubmitted() her karttan sonra çağırır.
  Future<void> incrementCompleted({
    required String planDate,
    required String targetLang,
  }) async {
    await customStatement('''
      UPDATE daily_plans
      SET completed_cards = completed_cards + 1
      WHERE plan_date = ? AND target_lang = ?
    ''', [planDate, targetLang]);
  }

  /// Tamamlanan kartları toplu güncelle — session abort durumu için.
  Future<void> updateCompletedCounts({
    required String planDate,
    required String targetLang,
    required int completedCards,
  }) =>
      (update(dailyPlans)
            ..where((p) =>
                p.planDate.equals(planDate) & p.targetLang.equals(targetLang)))
          .write(DailyPlansCompanion(completedCards: Value(completedCards)));

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Bugünün planı — uygulama açılışında kontrol edilir.
  /// Null dönerse DailyPlanner.buildPlan() çalıştırılır.
  Future<DailyPlan?> getTodayPlan({
    required String targetLang,
    required String todayDate, // 'YYYY-MM-DD'
  }) =>
      (select(dailyPlans)
            ..where((p) =>
                p.planDate.equals(todayDate) & p.targetLang.equals(targetLang)))
          .getSingleOrNull();

  /// Son N günün planları — Dashboard progress history için.
  Future<List<DailyPlan>> getRecentPlans({
    required String targetLang,
    int days = 30,
  }) =>
      (select(dailyPlans)
            ..where((p) => p.targetLang.equals(targetLang))
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.planDate,
                    mode: OrderingMode.desc,
                  )
            ])
            ..limit(days))
          .get();

  /// Bugünün planı tamamlandı mı?
  /// StudyZoneBloc.LoadPlanRequested: tamamlandıysa Idle(allDone) emit et.
  Future<bool> isTodayPlanComplete({
    required String targetLang,
    required String todayDate,
  }) async {
    final plan = await getTodayPlan(
      targetLang: targetLang,
      todayDate: todayDate,
    );
    if (plan == null) return false;
    return plan.totalCards > 0 && plan.completedCards >= plan.totalCards;
  }
}
