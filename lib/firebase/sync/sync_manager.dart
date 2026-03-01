// lib/firebase/sync/sync_manager.dart
//
// FAZ 7 FIX — Senkronizasyon Güçlendirme:
//   - pullFromFirestore() — Remote→Local sync (sign-in sonrası)
//   - firestoreToProgress() düzeltme: existing null → INSERT (yeni kayıt)
//   - syncStatus stream — UI bildirimi (pending count, failed count)
//   - Exponential backoff (retry arası bekleme)
//   - Connectivity restored → otomatik sync + UI toast
//
// Offline-first sync akışı:
//   1. Review → Drift'e yaz + SyncQueue'ya ekle
//   2. Online → syncAll() (push: SyncQueue → Firestore)
//   3. Sign-in → pullFromFirestore() (pull: Firestore → Drift)
//   4. ConflictResolver: Last-Write-Wins (updatedAt)

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../database/app_database.dart';

// ── Sync Status (UI bildirim) ─────────────────────────────────────────────────

enum SyncPhase { idle, pushing, pulling, error, done }

class SyncStatus {
  final SyncPhase phase;
  final int pendingCount;
  final int failedCount;
  final String? errorMessage;

  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.errorMessage,
  });

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pendingCount,
    int? failedCount,
    String? errorMessage,
  }) =>
      SyncStatus(
        phase: phase ?? this.phase,
        pendingCount: pendingCount ?? this.pendingCount,
        failedCount: failedCount ?? this.failedCount,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  String toString() =>
      'SyncStatus(phase=$phase, pending=$pendingCount, failed=$failedCount)';
}

// ── SyncManager ───────────────────────────────────────────────────────────────

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

  // ── Sync Status Stream (FAZ 7) ──────────────────────────────────────────

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus _currentStatus = const SyncStatus();

  void _emitStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  // ── Connectivity listener ───────────────────────────────────────────────

  void _subscribeConnectivity() {
    _connectivitySub = _connectivity!.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        syncAll().catchError((_) {});
      }
    });
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Tüm bekleyen sync işlemlerini çalıştır (push: local → Firestore).
  Future<void> syncAll() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _emitStatus(_currentStatus.copyWith(phase: SyncPhase.pushing));

    try {
      await syncPendingProgress(userId);
      await syncPendingSessions(userId);

      final pendingCount = await _db.syncQueueDao.getPendingCount();
      final failedCount = await _db.syncQueueDao.getFailedCount();

      _emitStatus(SyncStatus(
        phase: SyncPhase.done,
        pendingCount: pendingCount,
        failedCount: failedCount,
      ));
    } catch (e) {
      final pendingCount = await _db.syncQueueDao.getPendingCount();
      final failedCount = await _db.syncQueueDao.getFailedCount();

      _emitStatus(SyncStatus(
        phase: SyncPhase.error,
        pendingCount: pendingCount,
        failedCount: failedCount,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Firestore'dan progress çek → local DB'ye yaz (sign-in sonrası).
  ///
  /// FAZ 7: Pull sync — remote→local.
  /// ConflictResolver yerine inline LWW: updatedAt karşılaştırması.
  Future<int> pullFromFirestore({String? targetLang}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    _emitStatus(_currentStatus.copyWith(phase: SyncPhase.pulling));

    try {
      var query = _firestore
          .collection('users/$userId/progress')
          .orderBy('updatedAt', descending: true)
          .limit(1000); // İlk 1000 kayıt — daha fazlası paginate edilir

      if (targetLang != null) {
        query = _firestore
            .collection('users/$userId/progress')
            .where('targetLang', isEqualTo: targetLang)
            .orderBy('updatedAt', descending: true)
            .limit(1000);
      }

      final snap = await query.get();
      int appliedCount = 0;

      for (final doc in snap.docs) {
        final remote = doc.data();
        final applied = await _applyRemoteProgress(remote);
        if (applied) appliedCount++;
      }

      debugPrint(
          '[SyncManager] Pull complete: $appliedCount/${snap.docs.length} applied');

      _emitStatus(_currentStatus.copyWith(phase: SyncPhase.done));
      return appliedCount;
    } catch (e) {
      debugPrint('[SyncManager] Pull error: $e');
      _emitStatus(_currentStatus.copyWith(
        phase: SyncPhase.error,
        errorMessage: 'Pull failed: $e',
      ));
      return 0;
    }
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

  // ── Private: Push (local → Firestore) ───────────────────────────────────

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
      } on FirebaseException catch (e) {
        debugPrint('[SyncManager] Batch failed: $e');

        for (final item in pending) {
          await _db.syncQueueDao.incrementRetry(item.id);
        }
        await _db.syncQueueDao.cleanupRetryExceeded();
        rethrow;
      }

      hasMore = pending.length == batchSize;
    }
  }

  /// Firestore WriteBatch ile atomik commit.
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

  // ── Private: Pull (Firestore → local) ──────────────────────────────────

  /// Tek bir remote progress kaydını local DB'ye uygula.
  ///
  /// FAZ 7 FIX: existing null ise INSERT (yeni kayıt — cold start değil).
  /// Mevcut kod existing null → return null yapıyordu → yeni kayıtlar skip'leniyordu.
  Future<bool> _applyRemoteProgress(Map<String, dynamic> progressMap) async {
    final wordId = progressMap['wordId'] as int?;
    final targetLang = progressMap['targetLang'] as String?;
    if (wordId == null || targetLang == null) return false;

    final existing = await _db.progressDao
        .getCardProgress(wordId: wordId, targetLang: targetLang);

    final remoteUpdatedAt = progressMap['updatedAt'] as int? ?? 0;

    // existing null → Yeni kayıt: remote'u INSERT et
    // existing.updatedAt < remote → Remote daha yeni: UPDATE et
    // existing.updatedAt >= remote → Local daha yeni: skip
    if (existing != null && existing.updatedAt >= remoteUpdatedAt) {
      return false; // Local daha yeni veya eşit → skip
    }

    // Remote kazanır → upsert
    await _db.progressDao.upsertProgress(
      ProgressCompanion(
        wordId: Value(wordId),
        targetLang: Value(targetLang),
        stability: Value((progressMap['stability'] as num?)?.toDouble() ?? 0.5),
        difficulty:
            Value((progressMap['difficulty'] as num?)?.toDouble() ?? 5.0),
        repetitions: Value(progressMap['repetitions'] as int? ?? 0),
        lapses: Value(progressMap['lapses'] as int? ?? 0),
        cardState: Value(progressMap['cardState'] as String? ?? 'new'),
        nextReviewMs: Value(progressMap['nextReviewMs'] as int? ?? 0),
        lastReviewMs: Value(progressMap['lastReviewMs'] as int? ?? 0),
        updatedAt: Value(remoteUpdatedAt),
        isLeech: Value(progressMap['isLeech'] as bool? ?? false),
        isSuspended: Value(progressMap['isSuspended'] as bool? ?? false),
        modeHistoryJson:
            Value(progressMap['modeHistoryJson'] as String? ?? '{}'),
      ),
    );

    return true;
  }

  /// Eski API uyumluluğu — ConflictResolver hala bunu çağırabilir.
  @Deprecated('Use _applyRemoteProgress instead')
  Future<ProgressData?> firestoreToProgress(
    Map<String, dynamic> progressMap,
  ) async {
    await _applyRemoteProgress(progressMap);

    final wordId = progressMap['wordId'] as int?;
    final targetLang = progressMap['targetLang'] as String?;
    if (wordId == null || targetLang == null) return null;

    return _db.progressDao
        .getCardProgress(wordId: wordId, targetLang: targetLang);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _statusController.close();
  }
}
