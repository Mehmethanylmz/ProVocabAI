import 'package:drift/drift.dart';

/// Drift tablo tanımı: sync_queue
///
/// Offline-first sync mekanizması için bekleyen işlemlerin kuyruğu.
/// SyncManager.syncPendingProgress() tarafından işlenir.
///
/// entity_type değerleri: 'progress' | 'session'
/// (review_events Firestore'a yazılmaz — sadece local tutulur)
class SyncQueue extends Table {
  /// UUID.
  TextColumn get id => text()();

  /// Hangi varlık tipi: 'progress' | 'session'
  TextColumn get entityType => text()();

  /// İlgili kaydın ID'si.
  /// progress → 'wordId:targetLang' formatı
  /// session → sessionId
  TextColumn get entityId => text()();

  /// İşlem tipi: 'upsert' | 'delete'
  TextColumn get operation => text().withDefault(const Constant('upsert'))();

  /// Firestore'a gönderilecek payload — JSON encoded.
  TextColumn get payloadJson => text()();

  /// Kaç kez denendi (max 5 — R-05 mitigation).
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Kuyruğa eklenme zamanı (Unix ms).
  IntColumn get createdAt => integer()();

  /// Son deneme zamanı (Unix ms). null → henüz denenmedi.
  IntColumn get lastAttemptAt => integer().nullable()();

  /// Soft-delete: retry >= 5 olduğunda set edilir.
  /// SyncManager bu kayıtları işlemez, kullanıcıya toast gösterilir.
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
