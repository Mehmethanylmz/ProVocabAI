// lib/features/study_zone/domain/usecases/submit_review.dart
//
// Blueprint T-11: Drift transaction — progress UPSERT, reviewEvent INSERT,
// syncQueue INSERT, LeechHandler.evaluate() check.
//
// Şema kaynak: lib/database/tables/ (T-01 gerçek tanımlar)

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../database/app_database.dart';
import '../../../../srs/fsrs_state.dart';
import '../../../../srs/leech_handler.dart';
import '../../../../srs/mode_selector.dart';

class SubmitReviewParams {
  final int wordId;
  final String targetLang;
  final String sessionId;
  final FSRSState updatedFSRS;

  /// Review öncesi stability (log amaçlı review_events.stabilityBefore).
  final double stabilityBefore;

  final ReviewRating rating;
  final StudyMode mode;
  final int responseMs;
  final int xpEarned;
  final bool isNew;

  const SubmitReviewParams({
    required this.wordId,
    required this.targetLang,
    required this.sessionId,
    required this.updatedFSRS,
    required this.stabilityBefore,
    required this.rating,
    required this.mode,
    required this.responseMs,
    required this.xpEarned,
    required this.isNew,
  });
}

class SubmitReview {
  final AppDatabase _db;
  static const _uuid = Uuid();

  const SubmitReview(this._db);

  /// Tek Drift transaction icinde:
  ///   1. progress UPSERT (FSRSState + LeechHandler sonucu)
  ///   2. review_events INSERT
  ///   3. sync_queue INSERT (offline-first)
  ///
  /// Donus: LeechDecision (Bloc UI uyarisi icin)
  Future<LeechDecision> call(SubmitReviewParams p) async {
    final decision = LeechHandler.evaluate(
      lapses: p.updatedFSRS.lapses,
      repetitions: p.updatedFSRS.repetitions,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    final reviewEventId = _uuid.v4();

    await _db.transaction(() async {
      // 1. progress UPSERT
      await _db.into(_db.progress).insertOnConflictUpdate(
            ProgressCompanion.insert(
              wordId: p.wordId,
              targetLang: p.targetLang,
              stability: Value(p.updatedFSRS.stability),
              difficulty: Value(p.updatedFSRS.difficulty),
              cardState: Value(p.updatedFSRS.cardState.toDbString()),
              nextReviewMs:
                  Value(p.updatedFSRS.nextReview.millisecondsSinceEpoch),
              lastReviewMs: Value(now),
              repetitions: Value(p.updatedFSRS.repetitions),
              lapses: Value(p.updatedFSRS.lapses),
              isLeech: Value(LeechHandler.isLeech(p.updatedFSRS.lapses)),
              isSuspended: Value(decision == LeechDecision.suspend),
              updatedAt: Value(now),
            ),
          );

      // 2. review_events INSERT
      await _db.into(_db.reviewEvents).insert(ReviewEventsCompanion.insert(
            id: reviewEventId,
            wordId: p.wordId,
            sessionId: p.sessionId,
            targetLang: p.targetLang,
            rating: p.rating.name,
            responseMs: p.responseMs,
            mode: p.mode.key,
            wasCorrect: p.rating != ReviewRating.again,
            stabilityBefore: p.stabilityBefore,
            stabilityAfter: p.updatedFSRS.stability,
            reviewedAt: now,
          ));

      // 3. sync_queue INSERT (progress entity)
      await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
            id: _uuid.v4(),
            entityType: 'progress',
            entityId: '${p.wordId}:${p.targetLang}',
            payloadJson: jsonEncode({
              'word_id': p.wordId,
              'target_lang': p.targetLang,
              'stability': p.updatedFSRS.stability,
              'difficulty': p.updatedFSRS.difficulty,
              'card_state': p.updatedFSRS.cardState.toDbString(),
              'next_review_ms': p.updatedFSRS.nextReview.millisecondsSinceEpoch,
              'last_review_ms': now,
              'repetitions': p.updatedFSRS.repetitions,
              'lapses': p.updatedFSRS.lapses,
              'is_leech': LeechHandler.isLeech(p.updatedFSRS.lapses),
              'is_suspended': decision == LeechDecision.suspend,
              'updated_at': now,
            }),
            createdAt: now,
          ));
    });

    return decision;
  }
}
