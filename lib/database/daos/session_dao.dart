import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sessions_table.dart';

part 'session_dao.g.dart';

/// SessionDao — Oturum yönetimi.
///
/// Session kayıtları SyncManager tarafından Firestore'a senkronize edilir
/// (users/{uid}/sessions/{sessionId}).
///
/// T-10 StudyZoneBloc._onSessionStarted: insertSession
/// T-10 StudyZoneBloc._onAnswerSubmitted: updateSessionCounts
/// T-11 CompleteSessionUseCase: completeSession
/// T-16 SyncManager: getUnsyncedSessions, markSessionSynced
@DriftAccessor(tables: [Sessions])
class SessionDao extends DatabaseAccessor<AppDatabase> with _$SessionDaoMixin {
  SessionDao(super.db);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Yeni oturum başlat.
  /// id: UUID (StudyZoneBloc._onSessionStarted'da uuid paketi ile üretilir).
  Future<void> insertSession(SessionsCompanion companion) =>
      into(sessions).insert(companion);

  /// Oturum sırasında kart sayaçlarını güncelle (her review sonrası).
  /// StudyZoneBloc._onAnswerSubmitted çağırır.
  Future<void> updateSessionCounts({
    required String sessionId,
    required int totalCards,
    required int correctCards,
    required int xpEarned,
  }) =>
      (update(sessions)..where((s) => s.id.equals(sessionId))).write(
        SessionsCompanion(
          totalCards: Value(totalCards),
          correctCards: Value(correctCards),
          xpEarned: Value(xpEarned),
        ),
      );

  /// Oturumu tamamla: endedAt set et.
  /// CompleteSessionUseCase (T-11) çağırır.
  Future<void> completeSession({
    required String sessionId,
    required int endedAt,
    required int totalCards,
    required int correctCards,
    required int xpEarned,
  }) =>
      (update(sessions)..where((s) => s.id.equals(sessionId))).write(
        SessionsCompanion(
          endedAt: Value(endedAt),
          totalCards: Value(totalCards),
          correctCards: Value(correctCards),
          xpEarned: Value(xpEarned),
        ),
      );

  // ── Read ──────────────────────────────────────────────────────────────────

  /// endedAt null olan aktif oturum — crash recovery için.
  /// App yeniden açılırken kontrol edilir.
  Future<Session?> getActiveSession(String targetLang) => (select(sessions)
        ..where((s) => s.targetLang.equals(targetLang) & s.endedAt.isNull()))
      .getSingleOrNull();

  /// Son N oturum — Dashboard ve history ekranı için.
  Future<List<Session>> getRecentSessions({
    required String targetLang,
    int limit = 30,
  }) =>
      (select(sessions)
            ..where((s) => s.targetLang.equals(targetLang))
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.startedAt,
                    mode: OrderingMode.desc,
                  )
            ])
            ..limit(limit))
          .get();

  /// Belirli bir oturum — SessionResultScreen için.
  Future<Session?> getSessionById(String sessionId) =>
      (select(sessions)..where((s) => s.id.equals(sessionId)))
          .getSingleOrNull();

  // ── Sync ──────────────────────────────────────────────────────────────────

  /// Henüz Firestore'a sync edilmemiş tamamlanmış oturumlar.
  /// T-16 SyncManager.syncPendingSessions() kullanır.
  Future<List<Session>> getUnsyncedSessions() => (select(sessions)
        ..where((s) => s.isSynced.equals(false) & s.endedAt.isNotNull()))
      .get();

  /// Firestore'a başarıyla yazılan oturumu işaretle.
  Future<void> markSessionSynced(String sessionId) =>
      (update(sessions)..where((s) => s.id.equals(sessionId)))
          .write(const SessionsCompanion(isSynced: Value(true)));

  // ── Stats ─────────────────────────────────────────────────────────────────

  /// Bugünkü toplam XP — Dashboard ve DailyPlanner için.
  Future<int> getTodayXP({
    required String targetLang,
    required int todayStartMs,
  }) async {
    final result = await customSelect('''
      SELECT COALESCE(SUM(xp_earned), 0) AS total_xp
      FROM sessions
      WHERE target_lang = ?
        AND started_at >= ?
        AND ended_at IS NOT NULL
    ''',
        variables: [Variable(targetLang), Variable(todayStartMs)],
        readsFrom: {sessions}).getSingle();
    return result.data['total_xp'] as int? ?? 0;
  }

  /// Bu haftaki toplam kart sayısı — Leaderboard XP hesabında kullanılır.
  Future<Map<String, int>> getWeeklyStats({
    required String targetLang,
    required int weekStartMs,
  }) async {
    final result = await customSelect('''
      SELECT
        COALESCE(SUM(total_cards), 0) AS total_cards,
        COALESCE(SUM(correct_cards), 0) AS correct_cards,
        COALESCE(SUM(xp_earned), 0) AS xp_earned,
        COUNT(*) AS session_count
      FROM sessions
      WHERE target_lang = ?
        AND started_at >= ?
        AND ended_at IS NOT NULL
    ''',
        variables: [Variable(targetLang), Variable(weekStartMs)],
        readsFrom: {sessions}).getSingle();

    return {
      'totalCards': result.data['total_cards'] as int? ?? 0,
      'correctCards': result.data['correct_cards'] as int? ?? 0,
      'xpEarned': result.data['xp_earned'] as int? ?? 0,
      'sessionCount': result.data['session_count'] as int? ?? 0,
    };
  }
}
