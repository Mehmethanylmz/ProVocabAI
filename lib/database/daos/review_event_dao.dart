import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/review_events_table.dart';

part 'review_event_dao.g.dart';

/// ReviewEventDao — Review olaylarının immutable log kaydı.
///
/// ÖNEMLİ: Bu tablo SADECE LOCAL. Firestore'a hiçbir zaman yazılmaz (R-09).
/// 90 günden eski kayıtlar purgeOldEvents() ile temizlenir.
///
/// T-11 SubmitReviewUseCase: insertReviewEvent (transaction içinde)
/// T-13 SessionResultScreen: getSessionEvents (yanlış kelimeleri göster)
/// Cron / app startup: purgeOldEvents
@DriftAccessor(tables: [ReviewEvents])
class ReviewEventDao extends DatabaseAccessor<AppDatabase>
    with _$ReviewEventDaoMixin {
  ReviewEventDao(super.db);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Tek review olayı ekle.
  /// SubmitReviewUseCase db.transaction() bloğu içinde çağırır.
  /// id alanı: UUID (T-11'de uuid paketi ile üretilir).
  Future<void> insertReviewEvent(ReviewEventsCompanion companion) =>
      into(reviewEvents).insert(companion);

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Belirli bir session'ın tüm review olayları.
  /// SessionResultScreen yanlış kelimeleri listelerken kullanır (T-13).
  Future<List<ReviewEvent>> getSessionEvents(String sessionId) => (select(
          reviewEvents)
        ..where((e) => e.sessionId.equals(sessionId))
        ..orderBy([
          (t) => OrderingTerm(expression: t.reviewedAt, mode: OrderingMode.desc)
        ]))
      .get();

  /// Bir session'daki yanlış cevaplanan kelimeler (wasCorrect = false).
  Future<List<ReviewEvent>> getWrongEvents(String sessionId) =>
      (select(reviewEvents)
            ..where((e) =>
                e.sessionId.equals(sessionId) & e.wasCorrect.equals(false)))
          .get();

  // ── Maintenance ───────────────────────────────────────────────────────────

  /// 90 günden eski kayıtları sil — depolama şişmesini önler.
  /// App startup veya bir cron-like timer ile çağrılır.
  Future<int> purgeOldEvents({int retentionDays = 90}) async {
    final cutoffMs = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    return (delete(reviewEvents)
          ..where((e) => e.reviewedAt.isSmallerThanValue(cutoffMs)))
        .go();
  }

  /// Session bazlı doğruluk istatistiği — SessionResultScreen summary için.
  Future<Map<String, int>> getSessionStats(String sessionId) async {
    final result = await customSelect('''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN was_correct = 1 THEN 1 ELSE 0 END) AS correct,
        SUM(CASE WHEN was_correct = 0 THEN 1 ELSE 0 END) AS wrong,
        AVG(response_ms) AS avg_response_ms
      FROM review_events
      WHERE session_id = ?
    ''', variables: [Variable(sessionId)], readsFrom: {reviewEvents})
        .getSingle();

    return {
      'total': result.data['total'] as int? ?? 0,
      'correct': result.data['correct'] as int? ?? 0,
      'wrong': result.data['wrong'] as int? ?? 0,
      'avgResponseMs': (result.data['avg_response_ms'] as num?)?.toInt() ?? 0,
    };
  }
}
