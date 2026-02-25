import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

/// SyncQueueDao — Offline-first sync kuyruğu.
///
/// review_event'ler bu kuyruğa EKLENMEZ (sadece local tutulur, R-09).
/// Sadece 'progress' ve 'session' entity'leri sync edilir.
///
/// T-11 SubmitReviewUseCase: enqueue('progress', ...)
/// T-11 CompleteSessionUseCase: enqueue('session', ...)
/// T-16 SyncManager: getPending, markSynced, incrementRetry, cleanupRetryExceeded
@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  static const int maxRetry = 5;

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Sync kuyruğuna yeni iş ekle.
  /// [entityType] : 'progress' | 'session'
  /// [entityId]   : progress → 'wordId:targetLang' | session → sessionId
  /// [payloadJson]: Firestore'a yazılacak JSON (jsonEncode ile üret)
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

  /// Belirli entity tipindeki bekleyen işler.
  /// deletedAt IS NULL: soft-delete edilmişleri atla.
  /// retryCount < maxRetry: aşılmış olanları atla.
  /// T-16 SyncManager batch'lerken 500'lük limit uygular.
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
              (t) =>
                  OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
            ])
            ..limit(limit))
          .get();

  /// Başarıyla sync edilen kayıtları sil (hard delete — yer açmak için).
  Future<void> markSynced(List<String> ids) =>
      (delete(syncQueue)..where((q) => q.id.isIn(ids))).go();

  /// Başarısız denemede retry sayısını artır ve son deneme zamanını kaydet.
  Future<void> incrementRetry(String id) async {
    await customStatement('''
      UPDATE sync_queue
      SET retry_count = retry_count + 1,
          last_attempt_at = ?
      WHERE id = ?
    ''', [DateTime.now().millisecondsSinceEpoch, id]);
  }

  /// maxRetry aşılan kayıtları soft-delete et (R-05 mitigation).
  /// SyncManager bu kayıtları işlemez.
  /// Kullanıcıya "bir veri sync edilemedi" toast gösterilir.
  Future<int> cleanupRetryExceeded() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(syncQueue)
          ..where((q) =>
              q.retryCount.isBiggerOrEqualValue(maxRetry) &
              q.deletedAt.isNull()))
        .write(SyncQueueCompanion(deletedAt: Value(now)));
  }

  /// Soft-delete edilmiş (başarısız) kayıt sayısı — kullanıcı bildirimi için.
  Future<int> getFailedCount() async {
    final result = await customSelect('''
      SELECT COUNT(*) AS cnt
      FROM sync_queue
      WHERE deleted_at IS NOT NULL
    ''', readsFrom: {syncQueue}).getSingle();
    return result.data['cnt'] as int;
  }

  /// Tüm pending sayısı — connectivity restored sonrası UI badge için.
  Future<int> getPendingCount() async {
    final result = await customSelect('''
      SELECT COUNT(*) AS cnt
      FROM sync_queue
      WHERE deleted_at IS NULL
        AND retry_count < ?
    ''', variables: [Variable(maxRetry)], readsFrom: {syncQueue}).getSingle();
    return result.data['cnt'] as int;
  }
}
