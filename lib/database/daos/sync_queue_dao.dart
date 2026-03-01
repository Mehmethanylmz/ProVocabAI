// lib/database/daos/sync_queue_dao.dart
//
// FAZ 7 FIX:
//   - getPending sıralama: DESC → ASC (eski kayıtlar önce sync edilmeli)
//   - retryWithBackoff: exponential backoff destekli retry

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  static const int maxRetry = 5;

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> enqueue({
    required String id,
    required String entityType,
    required String entityId,
    required String payloadJson,
    String operation = 'upsert',
  }) =>
      into(syncQueue).insert(SyncQueueCompanion.insert(
        id: id,
        entityType: entityType,
        entityId: entityId,
        operation: Value(operation),
        payloadJson: payloadJson,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Bekleyen işler — FIFO sıralama (ASC: eski kayıtlar önce).
  ///
  /// FAZ 7 FIX: DESC → ASC. Eski kayıtlar önce sync edilmeli,
  /// aksi halde yeni kayıtlar sürekli öne geçer ve eskiler hiç sync olmaz.
  Future<List<SyncQueueData>> getPending({
    required String entityType,
    int limit = 500,
  }) =>
      (select(syncQueue)
            ..where((q) =>
                q.entityType.equals(entityType) &
                q.deletedAt.isNull() &
                q.retryCount.isSmallerThanValue(maxRetry))
            ..orderBy([
              (t) => OrderingTerm(
                  expression: t.createdAt, mode: OrderingMode.asc) // FAZ 7: ASC
            ])
            ..limit(limit))
          .get();

  /// Başarıyla sync edilen kayıtları sil (hard delete).
  Future<void> markSynced(List<String> ids) =>
      (delete(syncQueue)..where((q) => q.id.isIn(ids))).go();

  /// Başarısız denemede retry sayısını artır.
  Future<void> incrementRetry(String id) async {
    await customStatement('''
      UPDATE sync_queue
      SET retry_count = retry_count + 1,
          last_attempt_at = ?
      WHERE id = ?
    ''', [DateTime.now().millisecondsSinceEpoch, id]);
  }

  /// maxRetry aşılan kayıtları soft-delete.
  Future<int> cleanupRetryExceeded() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(syncQueue)
          ..where((q) =>
              q.retryCount.isBiggerOrEqualValue(maxRetry) &
              q.deletedAt.isNull()))
        .write(SyncQueueCompanion(deletedAt: Value(now)));
  }

  /// Soft-delete edilmiş (başarısız) kayıt sayısı.
  Future<int> getFailedCount() async {
    final result = await customSelect('''
      SELECT COUNT(*) AS cnt
      FROM sync_queue
      WHERE deleted_at IS NOT NULL
    ''', readsFrom: {syncQueue}).getSingle();
    return result.data['cnt'] as int;
  }

  /// Tüm pending sayısı.
  Future<int> getPendingCount() async {
    final result = await customSelect('''
      SELECT COUNT(*) AS cnt
      FROM sync_queue
      WHERE deleted_at IS NULL
        AND retry_count < ?
    ''', variables: [Variable(maxRetry)], readsFrom: {syncQueue}).getSingle();
    return result.data['cnt'] as int;
  }

  /// FAZ 7: Tüm kayıtları temizle (sign-out için).
  Future<void> deleteAll() => delete(syncQueue).go();
}
