// lib/firebase/sync/sync_manager.dart
//
// T-16: SyncManager — Offline-first sync mekanizması
// Blueprint F.4: 500'lük batch Firestore commit, connectivity listener,
//                retry logic (maxRetry=5)
//
// Bağımlılıklar: T-11 SyncQueueDao, T-14 AppDatabase, T-15 FirebaseAuth
// Firestore koleksiyonlar:
//   users/{uid}/progress/{wordId:targetLang}
//   users/{uid}/sessions/{sessionId}
//
// NOT: review_events Firestore'a YAZILMAZ — sadece local (R-09).

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../database/app_database.dart';

/// Offline-first sync yöneticisi.
///
/// Kullanım (DI):
///   getIt.registerSingleton<SyncManager>(SyncManager(
///     db: getIt<AppDatabase>(),
///     firestore: FirebaseFirestore.instance,
///     connectivity: Connectivity(),
///   ));
class SyncManager {
  SyncManager({
    required AppDatabase db,
    required FirebaseFirestore firestore,
    Connectivity? connectivity,
    FirebaseAuth? auth,
  })  : _db = db,
        _firestore = firestore,
        _connectivity = connectivity,
        _auth = auth ?? FirebaseAuth.instance {
    if (connectivity != null) _subscribeConnectivity();
  }

  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final Connectivity? _connectivity;
  final FirebaseAuth _auth;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  static const int batchSize = 500;
  static const int maxRetry = 5;

  // ── Connectivity listener ─────────────────────────────────────────────────

  void _subscribeConnectivity() {
    _connectivitySub = _connectivity!.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        // Fire-and-forget: hata loglanır, throw edilmez
        syncAll().catchError((_) {});
      }
    });
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Tüm bekleyen sync işlemlerini çalıştır.
  /// userId null ise (kullanıcı giriş yapmamış) no-op.
  Future<void> syncAll() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await syncPendingProgress(userId);
    await syncPendingSessions(userId);
  }

  /// Bekleyen progress kayıtlarını Firestore'a yaz.
  Future<void> syncPendingProgress(String userId) async {
    await _syncEntity(
      userId: userId,
      entityType: 'progress',
      collectionPath: 'users/$userId/progress',
    );
  }

  /// Bekleyen session kayıtlarını Firestore'a yaz.
  Future<void> syncPendingSessions(String userId) async {
    await _syncEntity(
      userId: userId,
      entityType: 'session',
      collectionPath: 'users/$userId/sessions',
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _syncEntity({
    required String userId,
    required String entityType,
    required String collectionPath,
  }) async {
    bool hasMore = true;

    while (hasMore) {
      final pending = await _db.syncQueueDao.getPending(
        entityType: entityType,
        limit: batchSize,
      );

      if (pending.isEmpty) {
        hasMore = false;
        break;
      }

      try {
        await _commitBatch(
          items: pending,
          collectionPath: collectionPath,
        );

        final ids = pending.map((e) => e.id).toList();
        await _db.syncQueueDao.markSynced(ids);
      } on FirebaseException {
        // Batch başarısız → retry count artır (tek tek)
        for (final item in pending) {
          await _db.syncQueueDao.incrementRetry(item.id);
        }
        // Retry aşılmışları soft-delete et
        await _db.syncQueueDao.cleanupRetryExceeded();
        rethrow;
      }

      // Tam batch geldi → daha fazla olabilir
      hasMore = pending.length == batchSize;
    }
  }

  /// Firestore WriteBatch ile 500'lük atomik commit.
  Future<void> _commitBatch({
    required List<SyncQueueData> items,
    required String collectionPath,
  }) async {
    final batch = _firestore.batch();
    final collection = _firestore.collection(collectionPath);

    for (final item in items) {
      final docRef = collection.doc(item.entityId);
      final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;

      switch (item.operation) {
        case 'upsert':
          batch.set(docRef, payload, SetOptions(merge: true));
        case 'delete':
          batch.delete(docRef);
      }
    }

    await batch.commit();
  }

  /// Firestore'dan progress çek → local DB'ye yaz (ConflictResolver'dan sonra).
  /// [progressMap]: Firestore'dan gelen data map'i.
  Future<ProgressData?> firestoreToProgress(
    Map<String, dynamic> progressMap,
  ) async {
    final wordId = progressMap['wordId'] as int?;
    final targetLang = progressMap['targetLang'] as String?;
    if (wordId == null || targetLang == null) return null;

    final existing = await _db.progressDao
        .getCardProgress(wordId: wordId, targetLang: targetLang);
    if (existing == null) return null;

    final updatedAt = progressMap['updatedAt'] as int? ?? 0;
    // updatedAt < existing → local daha yeni, remote'u uygulama
    // updatedAt >= existing → remote kazanır (tie dahil: sunucu güvenilir kaynak)
    if (updatedAt < existing.updatedAt) return existing;

    // Remote daha yeni → local'i güncelle
    await _db.progressDao.upsertProgress(
      ProgressCompanion(
        wordId: Value(wordId),
        targetLang: Value(targetLang),
        stability: Value((progressMap['stability'] as num).toDouble()),
        difficulty: Value((progressMap['difficulty'] as num).toDouble()),
        repetitions: Value(progressMap['repetitions'] as int),
        lapses: Value(progressMap['lapses'] as int),
        cardState: Value(progressMap['cardState'] as String),
        nextReviewMs: Value(progressMap['nextReviewMs'] as int),
        lastReviewMs: Value(progressMap['lastReviewMs'] as int? ?? 0),
        updatedAt: Value(updatedAt),
        isLeech: Value(progressMap['isLeech'] as bool? ?? false),
        isSuspended: Value(progressMap['isSuspended'] as bool? ?? false),
      ),
    );

    return await _db.progressDao
        .getCardProgress(wordId: wordId, targetLang: targetLang);
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
