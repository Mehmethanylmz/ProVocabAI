import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/progress_table.dart';
import '../tables/words_table.dart';

part 'progress_dao.g.dart';

/// ProgressDao — FSRS ilerleme kaydı erişim katmanı.
///
/// Eski sqflite şeması (mastery_level/due_date) tamamen kaldırıldı.
/// Tüm sorgular FSRS alanları (stability, difficulty, card_state,
/// next_review_ms, lapses) üzerinden çalışır.
///
/// T-04 DailyPlanner: getDueCards, getLeechCards, getNewCardsDoneToday
/// T-10 StudyZoneBloc._onAnswerSubmitted: upsertProgress (transaction içinde)
/// T-11 SubmitReviewUseCase: upsertProgress atomic transaction
@DriftAccessor(tables: [Progress, Words])
class ProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.db);

  // ── Core Queries (DailyPlanner için) ────────────────────────────────────

  /// Due kartlar: next_review_ms <= şimdi, suspend değil, 'new' değil.
  ///
  /// Blueprint E.4.1 ile birebir uyumlu.
  /// [beforeMs] : DateTime.now().millisecondsSinceEpoch
  /// [limit]    : overdueCapPerDay = 50 (DailyPlanner sabit)
  ///
  /// idx_progress_due index'i bu sorguyu hızlandırır.
  Future<List<ProgressData>> getDueCards({
    required String targetLang,
    required List<String> categories,
    required int beforeMs,
    int limit = 200,
  }) async {
    if (categories.isEmpty || categories.contains('all')) {
      // Kategori filtresi yok — basit Drift query builder yeterli.
      return (select(progress).join([
        innerJoin(words, words.id.equalsExp(progress.wordId)),
      ])
            ..where(
              progress.targetLang.equals(targetLang) &
                  progress.nextReviewMs.isSmallerOrEqualValue(beforeMs) &
                  progress.isSuspended.equals(false) &
                  progress.cardState.isNotIn(['new']),
            )
            ..orderBy([OrderingTerm(expression: progress.nextReviewMs)])
            ..limit(limit))
          .map((row) => row.readTable(progress))
          .get();
    }

    // Kategori filtresi — LIKE pattern (R-12 mitigation).
    final categoryWhere =
        categories.map((_) => 'w.categories_json LIKE ?').join(' OR ');
    final categoryArgs = categories.map((c) => '%"$c"%').toList();

    final rows = await customSelect('''
      SELECT p.*
      FROM progress p
      INNER JOIN words w ON w.id = p.word_id
      WHERE p.target_lang = ?
        AND p.next_review_ms <= ?
        AND p.is_suspended = 0
        AND p.card_state != 'new'
        AND ($categoryWhere)
      ORDER BY p.next_review_ms ASC
      LIMIT ?
    ''', variables: [
      Variable(targetLang),
      Variable(beforeMs),
      ...categoryArgs.map(Variable.new),
      Variable(limit),
    ], readsFrom: {
      progress,
      words
    }).get();

    return rows.map((r) => _progressFromRow(r.data)).toList();
  }

  /// Leech kartlar: is_leech = true, is_suspended = false.
  /// DailyPlanner interleave mantığında başa alınır.
  Future<List<ProgressData>> getLeechCards({
    required String targetLang,
    required List<String> categories,
    int limit = 20,
  }) async {
    if (categories.isEmpty || categories.contains('all')) {
      return (select(progress).join([
        innerJoin(words, words.id.equalsExp(progress.wordId)),
      ])
            ..where(
              progress.targetLang.equals(targetLang) &
                  progress.isLeech.equals(true) &
                  progress.isSuspended.equals(false),
            )
            ..limit(limit))
          .map((row) => row.readTable(progress))
          .get();
    }

    final categoryWhere =
        categories.map((_) => 'w.categories_json LIKE ?').join(' OR ');
    final categoryArgs = categories.map((c) => '%"$c"%').toList();

    final rows = await customSelect('''
      SELECT p.*
      FROM progress p
      INNER JOIN words w ON w.id = p.word_id
      WHERE p.target_lang = ?
        AND p.is_leech = 1
        AND p.is_suspended = 0
        AND ($categoryWhere)
      LIMIT ?
    ''', variables: [
      Variable(targetLang),
      ...categoryArgs.map(Variable.new),
      Variable(limit),
    ], readsFrom: {
      progress,
      words
    }).get();

    return rows.map((r) => _progressFromRow(r.data)).toList();
  }

  /// Bugün zaten görülmüş yeni kart sayısı.
  /// DailyPlanner'ın newWordsGoal aşımını önlemek için kullanılır.
  /// last_review_ms bugünün başından büyük ve card_state != 'new' → o gün başlatıldı.
  Future<int> getNewCardsDoneToday({
    required String targetLang,
    required int todayStartMs,
  }) async {
    final result = await customSelect('''
      SELECT COUNT(*) AS cnt
      FROM progress
      WHERE target_lang = ?
        AND last_review_ms >= ?
        AND repetitions = 1
    ''',
        variables: [Variable(targetLang), Variable(todayStartMs)],
        readsFrom: {progress}).getSingle();
    return result.data['cnt'] as int;
  }

  // ── FSRS State Okuma ─────────────────────────────────────────────────────

  /// Tek kart için mevcut FSRS state'i getir.
  /// StudyZoneBloc._onAnswerSubmitted: FSRSEngine.updateCard(state, rating)
  /// Progress kaydı yoksa null döner → yeni kart (cold-start).
  Future<ProgressData?> getCardProgress({
    required int wordId,
    required String targetLang,
  }) =>
      (select(progress)
            ..where((p) =>
                p.wordId.equals(wordId) & p.targetLang.equals(targetLang)))
          .getSingleOrNull();

  // ── Write Operations ──────────────────────────────────────────────────────

  /// FSRS güncellemesi sonrası progress kaydını yazar/günceller.
  /// insertOnConflictUpdate: kayıt yoksa INSERT, varsa UPDATE (upsert).
  ///
  /// SubmitReviewUseCase bunu transaction içinde çağırır (T-11):
  ///   await db.transaction(() async {
  ///     await progressDao.upsertProgress(companion);
  ///     await reviewEventDao.insertReviewEvent(eventCompanion);
  ///     await syncQueueDao.enqueue('progress', ...);
  ///   });
  Future<void> upsertProgress(ProgressCompanion companion) =>
      into(progress).insertOnConflictUpdate(companion);

  /// Leech işaretleme — LeechHandler.evaluate() çağrısı sonrası.
  Future<void> markAsLeech({
    required int wordId,
    required String targetLang,
  }) =>
      (update(progress)
            ..where((p) =>
                p.wordId.equals(wordId) & p.targetLang.equals(targetLang)))
          .write(const ProgressCompanion(isLeech: Value(true)));

  /// Suspend işlemi — lapses >= 8 durumunda.
  Future<void> suspendCard({
    required int wordId,
    required String targetLang,
  }) =>
      (update(progress)
            ..where((p) =>
                p.wordId.equals(wordId) & p.targetLang.equals(targetLang)))
          .write(const ProgressCompanion(
        isLeech: Value(true),
        isSuspended: Value(true),
      ));

  /// ModeSelector'ın mod geçmişini günceller.
  /// StudyZoneBloc._onAnswerSubmitted sonrası çağrılır.
  Future<void> updateModeHistory({
    required int wordId,
    required String targetLang,
    required String modeHistoryJson,
  }) =>
      (update(progress)
            ..where((p) =>
                p.wordId.equals(wordId) & p.targetLang.equals(targetLang)))
          .write(ProgressCompanion(modeHistoryJson: Value(modeHistoryJson)));

  // ── Dashboard Queries ─────────────────────────────────────────────────────

  /// Mastered kart sayısı (stability >= 21 → 3 hafta üzeri stabilite).
  /// Dashboard'da gösterilir. Eski mastery_level >= 4 yerine FSRS stability threshold.
  Future<int> getMasteredCount(String targetLang) async {
    final result = await customSelect('''
      SELECT COUNT(*) AS cnt
      FROM progress
      WHERE target_lang = ?
        AND stability >= 21.0
        AND card_state = 'review'
        AND is_suspended = 0
    ''', variables: [Variable(targetLang)], readsFrom: {progress}).getSingle();
    return result.data['cnt'] as int;
  }

  /// Bugün review edilen kart sayısı.
  Future<int> getReviewedTodayCount({
    required String targetLang,
    required int todayStartMs,
  }) async {
    final result = await customSelect('''
      SELECT COUNT(*) AS cnt
      FROM progress
      WHERE target_lang = ?
        AND last_review_ms >= ?
    ''',
        variables: [Variable(targetLang), Variable(todayStartMs)],
        readsFrom: {progress}).getSingle();
    return result.data['cnt'] as int;
  }

  /// Toplam leech kart sayısı — Dashboard için.
  Future<int> getLeechCount(String targetLang) async {
    final result = await customSelect('''
      SELECT COUNT(*) AS cnt
      FROM progress
      WHERE target_lang = ?
        AND is_leech = 1
        AND is_suspended = 0
    ''', variables: [Variable(targetLang)], readsFrom: {progress}).getSingle();
    return result.data['cnt'] as int;
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  /// customSelect sonucu Map'ten ProgressData üretir.
  /// Drift'in TypedResult dışında kullanımı için gerekli.
  ProgressData _progressFromRow(Map<String, dynamic> data) {
    return ProgressData(
      wordId: data['word_id'] as int,
      targetLang: data['target_lang'] as String,
      stability: (data['stability'] as num).toDouble(),
      difficulty: (data['difficulty'] as num).toDouble(),
      cardState: data['card_state'] as String,
      nextReviewMs: data['next_review_ms'] as int,
      lastReviewMs: data['last_review_ms'] as int,
      lapses: data['lapses'] as int,
      repetitions: data['repetitions'] as int,
      isLeech: data['is_leech'] == 1,
      isSuspended: data['is_suspended'] == 1,
      modeHistoryJson: data['mode_history_json'] as String? ?? '{}',
      updatedAt: data['updated_at'] as int,
    );
  }
}
