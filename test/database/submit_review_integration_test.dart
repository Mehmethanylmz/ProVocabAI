// test/database/submit_review_integration_test.dart
//
// F16-01: Integration test — MCQ correct/wrong → wasCorrect correctly stored
//
// Key test: isCorrect and rating are INDEPENDENT (F9-03 pattern).
//   - isCorrect=true, rating=again  → was_correct = 1 (chose right option, rated hard)
//   - isCorrect=false, rating=good  → was_correct = 0 (chose wrong option, rated easy by mistake)
//
// Uses in-memory Drift database (NativeDatabase.memory()).

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savgolearnvocabulary/database/app_database.dart';
import 'package:savgolearnvocabulary/features/study_zone/domain/usecases/submit_review.dart';
import 'package:savgolearnvocabulary/srs/fsrs_engine.dart';
import 'package:savgolearnvocabulary/srs/fsrs_state.dart';
import 'package:savgolearnvocabulary/srs/mode_selector.dart';

AppDatabase _createTestDb() =>
    AppDatabase.forTesting(NativeDatabase.memory());

/// Minimal word companion for tests.
WordsCompanion _word(int id, {int rank = 1}) => WordsCompanion.insert(
      id: Value(id),
      partOfSpeech: const Value('noun'),
      categoriesJson: const Value('["a1"]'),
      contentJson:
          const Value('{"en":{"word":"test","meaning":"deneme"},"tr":{"word":"deneme","meaning":"test"}}'),
      sentencesJson: const Value(
          '{"beginner":{"en":"This is a test.","tr":"Bu bir deneme."}}'),
      difficultyRank: Value(rank),
      sourceLang: const Value('tr'),
      targetLang: const Value('en'),
    );

/// Minimal session companion.
SessionsCompanion _session(String id) => SessionsCompanion.insert(
      id: id,
      targetLang: 'en',
      startedAt: DateTime.now().millisecondsSinceEpoch,
    );

/// Builds a SubmitReviewParams with given isCorrect + rating.
SubmitReviewParams _params({
  required int wordId,
  required String sessionId,
  required bool isCorrect,
  required ReviewRating rating,
}) {
  const engine = FSRSEngine();
  final newState = engine.initNewCard(rating);
  return SubmitReviewParams(
    wordId: wordId,
    targetLang: 'en',
    sessionId: sessionId,
    updatedFSRS: newState,
    stabilityBefore: 0.5,
    rating: rating,
    mode: StudyMode.mcq,
    responseMs: 1500,
    xpEarned: 10,
    isNew: true,
    isCorrect: isCorrect,
  );
}

void main() {
  late AppDatabase db;
  late SubmitReview submitReview;

  setUp(() async {
    db = _createTestDb();
    submitReview = SubmitReview(db);

    // Insert a test word and session
    await db.wordDao.insertWordRaw(_word(1));
    await db.into(db.sessions).insert(_session('session-001'));
  });

  tearDown(() async {
    await db.close();
  });

  group('SubmitReview — wasCorrect mapping (F16-01)', () {
    test('isCorrect:true → was_correct stored as true in review_events', () async {
      await submitReview(_params(
        wordId: 1,
        sessionId: 'session-001',
        isCorrect: true,
        rating: ReviewRating.good,
      ));

      final events =
          await db.reviewEventDao.getSessionEvents('session-001');
      expect(events, hasLength(1));
      expect(events.first.wasCorrect, isTrue);
    });

    test('isCorrect:false → was_correct stored as false in review_events', () async {
      await submitReview(_params(
        wordId: 1,
        sessionId: 'session-001',
        isCorrect: false,
        rating: ReviewRating.again,
      ));

      final events =
          await db.reviewEventDao.getSessionEvents('session-001');
      expect(events, hasLength(1));
      expect(events.first.wasCorrect, isFalse);
    });

    // KEY TEST: F9-03 — isCorrect is separate from rating
    test(
        'isCorrect:true with rating:again → was_correct=true (chose right, rated again)',
        () async {
      // User chose correct MCQ option but then rated the card "again"
      // (e.g., they knew it but want more practice)
      // wasCorrect must reflect the MCQ choice, NOT the rating
      await submitReview(_params(
        wordId: 1,
        sessionId: 'session-001',
        isCorrect: true,
        rating: ReviewRating.again,
      ));

      final events =
          await db.reviewEventDao.getSessionEvents('session-001');
      expect(events.first.wasCorrect, isTrue,
          reason: 'wasCorrect must come from isCorrect param, not rating');
    });

    // KEY TEST: F9-03 — opposite direction
    test(
        'isCorrect:false with rating:good → was_correct=false (chose wrong, rated good)',
        () async {
      await submitReview(_params(
        wordId: 1,
        sessionId: 'session-001',
        isCorrect: false,
        rating: ReviewRating.good,
      ));

      final events =
          await db.reviewEventDao.getSessionEvents('session-001');
      expect(events.first.wasCorrect, isFalse,
          reason: 'wasCorrect must come from isCorrect param, not rating');
    });

    test('rating is stored independently from isCorrect', () async {
      await submitReview(_params(
        wordId: 1,
        sessionId: 'session-001',
        isCorrect: false,
        rating: ReviewRating.easy,
      ));

      final events =
          await db.reviewEventDao.getSessionEvents('session-001');
      expect(events.first.rating, equals('easy'));
      expect(events.first.wasCorrect, isFalse);
    });

    test('multiple reviews in same session all stored', () async {
      await db.wordDao.insertWordRaw(_word(2));

      await submitReview(_params(
        wordId: 1,
        sessionId: 'session-001',
        isCorrect: true,
        rating: ReviewRating.good,
      ));
      await submitReview(_params(
        wordId: 2,
        sessionId: 'session-001',
        isCorrect: false,
        rating: ReviewRating.hard,
      ));

      final events =
          await db.reviewEventDao.getSessionEvents('session-001');
      expect(events, hasLength(2));

      final correctCount = events.where((e) => e.wasCorrect).length;
      final wrongCount = events.where((e) => !e.wasCorrect).length;
      expect(correctCount, equals(1));
      expect(wrongCount, equals(1));
    });

    test('progress UPSERT stores FSRS state after review', () async {
      await submitReview(_params(
        wordId: 1,
        sessionId: 'session-001',
        isCorrect: true,
        rating: ReviewRating.good,
      ));

      final progress = await (db.select(db.progress)
            ..where((p) =>
                p.wordId.equals(1) & p.targetLang.equals('en')))
          .getSingleOrNull();

      expect(progress, isNotNull);
      expect(progress!.stability, greaterThan(0));
      expect(progress.repetitions, equals(1));
    });

    test('getWrongEvents returns only wasCorrect=false events', () async {
      await db.wordDao.insertWordRaw(_word(2));

      await submitReview(_params(
        wordId: 1,
        sessionId: 'session-001',
        isCorrect: true,
        rating: ReviewRating.good,
      ));
      await submitReview(_params(
        wordId: 2,
        sessionId: 'session-001',
        isCorrect: false,
        rating: ReviewRating.hard,
      ));

      final wrongEvents =
          await db.reviewEventDao.getWrongEvents('session-001');
      expect(wrongEvents, hasLength(1));
      expect(wrongEvents.first.wordId, equals(2));
    });
  });
}
