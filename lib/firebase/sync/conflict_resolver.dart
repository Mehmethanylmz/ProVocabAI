// lib/firebase/sync/conflict_resolver.dart
//
// T-17: ConflictResolver — Last-Write-Wins updatedAt karşılaştırması
// Blueprint: resolve(local, remote): remote daha yeni → SyncManager.firestoreToProgress
//                                    local daha yeni  → syncQueue'ya ekle
//
// Strateji: Last-Write-Wins (LWW) — updatedAt (Unix ms) kazanır.
// Tie (eşit updatedAt): remote kazanır (sunucu güvenilir kaynak).

import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import 'sync_manager.dart';

/// Sync çakışma çözümleyicisi.
///
/// Kullanım:
///   final result = await resolver.resolve(local: localProgress, remote: remoteMap);
class ConflictResolver {
  ConflictResolver({
    required AppDatabase db,
    required SyncManager syncManager,
  })  : _db = db,
        _syncManager = syncManager;

  final AppDatabase _db;
  final SyncManager _syncManager;

  static const _uuid = Uuid();

  /// Local progress ile remote Firestore verisi arasındaki çakışmayı çöz.
  ///
  /// [local]  : DB'den gelen ProgressData
  /// [remote] : Firestore'dan gelen Map<String, dynamic>
  ///
  /// Dönüş:
  ///   ConflictResult.remoteWon  → remote uygulandı, local güncellendi
  ///   ConflictResult.localWon   → local syncQueue'ya eklendi (remote gecikmeli)
  ///   ConflictResult.noConflict → updatedAt eşit, remote kazandı (tie-break)
  Future<ConflictResult> resolve({
    required ProgressData local,
    required Map<String, dynamic> remote,
  }) async {
    final remoteUpdatedAt = remote['updatedAt'] as int? ?? 0;
    final localUpdatedAt = local.updatedAt;

    if (remoteUpdatedAt > localUpdatedAt) {
      // Remote daha yeni → Firestore kazanır
      await _syncManager.firestoreToProgress(remote);
      return ConflictResult.remoteWon;
    } else if (localUpdatedAt > remoteUpdatedAt) {
      // Local daha yeni → syncQueue'ya ekle (remote'u override et)
      await _enqueueLocal(local);
      return ConflictResult.localWon;
    } else {
      // Tie → remote kazanır (sunucu güvenilir kaynak)
      await _syncManager.firestoreToProgress(remote);
      return ConflictResult.noConflict;
    }
  }

  /// Birden fazla remote kaydı için toplu çakışma çözümü.
  Future<List<ConflictOutcome>> resolveAll({
    required List<ProgressData> locals,
    required List<Map<String, dynamic>> remotes,
  }) async {
    final outcomes = <ConflictOutcome>[];

    // entityId → local map
    final localMap = {for (final l in locals) '${l.wordId}:${l.targetLang}': l};

    for (final remote in remotes) {
      final wordId = remote['wordId'] as int?;
      final targetLang = remote['targetLang'] as String?;
      if (wordId == null || targetLang == null) continue;

      final entityId = '$wordId:$targetLang';
      final local = localMap[entityId];

      if (local == null) {
        // Local'de yok → remote'u uygula (yeni kayıt)
        await _syncManager.firestoreToProgress(remote);
        outcomes.add(ConflictOutcome(
            entityId: entityId, result: ConflictResult.remoteWon));
        continue;
      }

      final result = await resolve(local: local, remote: remote);
      outcomes.add(ConflictOutcome(entityId: entityId, result: result));
    }

    return outcomes;
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _enqueueLocal(ProgressData local) async {
    final entityId = '${local.wordId}:${local.targetLang}';
    final payload = _progressToMap(local);

    await _db.syncQueueDao.enqueue(
      id: _uuid.v4(),
      entityType: 'progress',
      entityId: entityId,
      payloadJson: jsonEncode(payload),
      operation: 'upsert',
    );
  }

  Map<String, dynamic> _progressToMap(ProgressData p) => {
        'wordId': p.wordId,
        'targetLang': p.targetLang,
        'stability': p.stability,
        'difficulty': p.difficulty,
        'repetitions': p.repetitions,
        'lapses': p.lapses,
        'cardState': p.cardState,
        'nextReviewMs': p.nextReviewMs,
        'lastReviewMs': p.lastReviewMs,
        'updatedAt': p.updatedAt,
        'isLeech': p.isLeech,
        'isSuspended': p.isSuspended,
      };
}

// ── Result types ──────────────────────────────────────────────────────────────

enum ConflictResult {
  remoteWon,
  localWon,
  noConflict,
}

class ConflictOutcome {
  const ConflictOutcome({
    required this.entityId,
    required this.result,
  });

  final String entityId;
  final ConflictResult result;

  @override
  String toString() => 'ConflictOutcome($entityId: $result)';
}
