// FIX: drift'teki isNull + isNotNull flutter_test matcher ile çakışıyor → her ikisini hide et
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratikapp/database/app_database.dart';
import 'package:pratikapp/database/daos/sync_queue_dao.dart';

/// T-02 Acceptance Criteria Testleri
///
/// Çalıştırmak için:
///   flutter test test/database/dao_integration_test.dart
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  // ── Test Helpers ──────────────────────────────────────────────────────────

  /// FIX: Companion.insert() kuralı:
  ///   - withDefault() OLMAYAN kolonlar → düz değer (String, int, vb.)
  ///   - withDefault() OLAN kolonlar    → Value<T> (opsiyonel, atlanabilir)
  ///
  /// words tablosu:
  ///   id           → integer()()          → withDefault YOK → düz int
  ///   partOfSpeech → text()()             → withDefault YOK → düz String
  ///   categoriesJson → text().withDefault → withDefault VAR → Value<String> veya atla
  ///   contentJson    → text().withDefault → withDefault VAR → Value<String> veya atla
  ///   sentencesJson  → text().withDefault → withDefault VAR → Value<String> veya atla
  ///   difficultyRank → int().withDefault  → withDefault VAR → Value<int> veya atla
  Future<void> seedWord({
    required int id,
    String categories = '["oxford-american/a1"]',
    int difficultyRank = 1,
  }) =>
      db.wordDao.insertWordRaw(WordsCompanion.insert(
        id: Value(id), // withDefault YOK → düz int
        partOfSpeech: Value('noun'), // withDefault YOK → düz String
        categoriesJson: Value(categories), // withDefault VAR → Value<String>
        contentJson: const Value('{"en":{"word":"test","meaning":"test"}}'),
        sentencesJson: const Value('{}'),
        difficultyRank: Value(difficultyRank),
      ));

  /// progress tablosu:
  ///   wordId       → integer()()  → withDefault YOK → düz int
  ///   targetLang   → text()()     → withDefault YOK → düz String
  ///   nextReviewMs → int().withDefault(0) → withDefault VAR → Value<int>
  ///   updatedAt    → int().withDefault(0) → withDefault VAR → Value<int>
  ///   stability    → real().withDefault(0.5) → atlanabilir
  ///   cardState    → text().withDefault('new') → atlanabilir
  Future<void> seedProgress({
    required int wordId,
    required String targetLang,
    String cardState = 'review',
    int nextReviewMs = 0,
    bool isLeech = false,
    int lapses = 0,
    int repetitions = 1,
    double stability = 5.0,
  }) =>
      db.into(db.progress).insert(ProgressCompanion.insert(
            wordId: wordId, // withDefault YOK → düz int
            targetLang: targetLang, // withDefault YOK → düz String
            cardState: Value(cardState),
            nextReviewMs: Value(nextReviewMs),
            isLeech: Value(isLeech),
            lapses: Value(lapses),
            repetitions: Value(repetitions),
            stability: Value(stability),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ));

  // ── WordDao Tests ─────────────────────────────────────────────────────────

  group('WordDao', () {
    test('AC: getNewCards — progress kaydı olmayan kelimeler döner', () async {
      await seedWord(id: 1);
      await seedWord(id: 2);
      await seedWord(id: 3);

      await seedProgress(wordId: 1, targetLang: 'en');

      final newCards = await db.wordDao.getNewCards(
        targetLang: 'en',
        categories: [],
        limit: 50,
      );

      expect(newCards.length, 2);
      expect(newCards.map((w) => w.id), containsAll([2, 3]));
      expect(newCards.map((w) => w.id), isNot(contains(1)));
    });

    test('AC: getNewCards — difficulty_rank ASC sırası', () async {
      await seedWord(id: 10, difficultyRank: 3);
      await seedWord(id: 11, difficultyRank: 1);
      await seedWord(id: 12, difficultyRank: 2);

      final newCards = await db.wordDao.getNewCards(
        targetLang: 'en',
        categories: [],
        limit: 10,
      );

      expect(newCards[0].difficultyRank, 1);
      expect(newCards[1].difficultyRank, 2);
      expect(newCards[2].difficultyRank, 3);
    });

    test('AC: getNewCards — kategori filtresi çalışıyor', () async {
      await seedWord(id: 20, categories: '["oxford-american/a1"]');
      await seedWord(id: 21, categories: '["b1"]');

      final a1Cards = await db.wordDao.getNewCards(
        targetLang: 'en',
        categories: ['oxford-american/a1'],
        limit: 10,
      );

      expect(a1Cards.length, 1);
      expect(a1Cards.first.id, 20);
    });

    test('AC: insertBatch — idempotent', () async {
      final companions = List.generate(
        5,
        (i) => WordsCompanion.insert(
          id: Value(i + 100), // withDefault YOK → düz int
          partOfSpeech: Value('verb'), // withDefault YOK → düz String
          categoriesJson: const Value('[]'),
          contentJson: const Value('{}'),
          sentencesJson: const Value('{}'),
        ),
      );

      await db.wordDao.insertBatch(companions);
      await expectLater(db.wordDao.insertBatch(companions), completes);

      final count = await db.wordDao.getWordCount();
      expect(count, 5);
    });
  });

  // ── ProgressDao Tests ─────────────────────────────────────────────────────

  group('ProgressDao', () {
    test('AC: getDueCards — boş DB → empty list', () async {
      final result = await db.progressDao.getDueCards(
        targetLang: 'en',
        categories: [],
        beforeMs: DateTime.now().millisecondsSinceEpoch,
      );
      expect(result, isEmpty);
    });

    test('AC: getDueCards — due kart varken filtreli sonuç', () async {
      await seedWord(id: 1);
      await seedWord(id: 2);

      final now = DateTime.now().millisecondsSinceEpoch;
      await seedProgress(
          wordId: 1, targetLang: 'en', nextReviewMs: now - 10000);
      await seedProgress(
          wordId: 2, targetLang: 'en', nextReviewMs: now + 86400000);

      final due = await db.progressDao.getDueCards(
        targetLang: 'en',
        categories: [],
        beforeMs: now,
      );

      expect(due.length, 1);
      expect(due.first.wordId, 1);
    });

    test("AC: getDueCards — card_state='new' dahil edilmez", () async {
      await seedWord(id: 3);
      await seedProgress(
        wordId: 3,
        targetLang: 'en',
        cardState: 'new',
        nextReviewMs: 0,
      );

      final due = await db.progressDao.getDueCards(
        targetLang: 'en',
        categories: [],
        beforeMs: DateTime.now().millisecondsSinceEpoch,
      );
      expect(due, isEmpty);
    });

    test('AC: getDueCards — suspended kartlar atlanır', () async {
      await seedWord(id: 4);
      await db.into(db.progress).insert(ProgressCompanion.insert(
            wordId: 4, // withDefault YOK → düz int
            targetLang: 'en', // withDefault YOK → düz String
            cardState: const Value('review'),
            nextReviewMs: const Value(0),
            isSuspended: const Value(true),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ));

      final due = await db.progressDao.getDueCards(
        targetLang: 'en',
        categories: [],
        beforeMs: DateTime.now().millisecondsSinceEpoch,
      );
      expect(due, isEmpty);
    });

    test('AC: upsertProgress — INSERT sonra UPDATE', () async {
      await seedWord(id: 5);
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.progressDao.upsertProgress(ProgressCompanion.insert(
        wordId: 5, // düz int
        targetLang: 'tr', // düz String
        stability: const Value(2.4),
        cardState: const Value('learning'),
        nextReviewMs: Value(now + 86400000),
        updatedAt: Value(now),
      ));

      var card =
          await db.progressDao.getCardProgress(wordId: 5, targetLang: 'tr');
      expect(card?.stability, 2.4);

      await db.progressDao.upsertProgress(ProgressCompanion.insert(
        wordId: 5,
        targetLang: 'tr',
        stability: const Value(5.0),
        cardState: const Value('review'),
        nextReviewMs: Value(now + 604800000),
        updatedAt: Value(now + 1),
      ));

      card = await db.progressDao.getCardProgress(wordId: 5, targetLang: 'tr');
      expect(card?.stability, 5.0);
      expect(card?.cardState, 'review');
    });

    test('AC: getLeechCards', () async {
      await seedWord(id: 6);
      await seedWord(id: 7);

      await seedProgress(wordId: 6, targetLang: 'en', isLeech: true, lapses: 4);
      await seedProgress(wordId: 7, targetLang: 'en', isLeech: false);

      final leeches = await db.progressDao.getLeechCards(
        targetLang: 'en',
        categories: [],
      );

      expect(leeches.length, 1);
      expect(leeches.first.wordId, 6);
    });

    test('AC: getMasteredCount — stability >= 21', () async {
      await seedWord(id: 8);
      await seedWord(id: 9);

      await seedProgress(wordId: 8, targetLang: 'en', stability: 25.0);
      await seedProgress(wordId: 9, targetLang: 'en', stability: 10.0);

      final mastered = await db.progressDao.getMasteredCount('en');
      expect(mastered, 1);
    });
  });

  // ── ReviewEventDao Tests ──────────────────────────────────────────────────

  group('ReviewEventDao', () {
    test('AC: insertReviewEvent + getSessionEvents', () async {
      await seedWord(id: 1);

      /// review_events tablosu:
      ///   id         → text()()  → withDefault YOK → düz String
      ///   sessionId  → text()()  → withDefault YOK → düz String
      ///   targetLang → text()()  → withDefault YOK → düz String
      ///   rating     → text()()  → withDefault YOK → düz String
      ///   ...
      await db.reviewEventDao.insertReviewEvent(ReviewEventsCompanion.insert(
        id: 'evt-001', // düz String
        wordId: 1, // düz int
        sessionId: 'session-abc', // düz String
        targetLang: 'en', // düz String
        rating: 'good', // düz String
        responseMs: 1200, // düz int
        mode: 'mcq', // düz String
        wasCorrect: true, // düz bool
        stabilityBefore: 0.5, // düz double
        stabilityAfter: 2.4, // düz double
        reviewedAt: DateTime.now().millisecondsSinceEpoch, // düz int
      ));

      final events = await db.reviewEventDao.getSessionEvents('session-abc');
      expect(events.length, 1);
      expect(events.first.rating, 'good');
      expect(events.first.wasCorrect, true);
    });

    test('AC: purgeOldEvents — 90 günden eski siliniyor', () async {
      await seedWord(id: 1);

      final old = DateTime.now()
          .subtract(const Duration(days: 95))
          .millisecondsSinceEpoch;
      final recent = DateTime.now().millisecondsSinceEpoch;

      await db.reviewEventDao.insertReviewEvent(ReviewEventsCompanion.insert(
        id: 'evt-old',
        wordId: 1,
        sessionId: 's1',
        targetLang: 'en',
        rating: 'again',
        responseMs: 500,
        mode: 'mcq',
        wasCorrect: false,
        stabilityBefore: 0.5,
        stabilityAfter: 0.5,
        reviewedAt: old,
      ));

      await db.reviewEventDao.insertReviewEvent(ReviewEventsCompanion.insert(
        id: 'evt-recent',
        wordId: 1,
        sessionId: 's1',
        targetLang: 'en',
        rating: 'good',
        responseMs: 800,
        mode: 'mcq',
        wasCorrect: true,
        stabilityBefore: 2.4,
        stabilityAfter: 5.0,
        reviewedAt: recent,
      ));

      final deleted = await db.reviewEventDao.purgeOldEvents(retentionDays: 90);
      expect(deleted, 1);

      final remaining = await db.reviewEventDao.getSessionEvents('s1');
      expect(remaining.length, 1);
      expect(remaining.first.id, 'evt-recent');
    });
  });

  // ── SessionDao Tests ──────────────────────────────────────────────────────

  group('SessionDao', () {
    test('AC: insertSession + completeSession + markSessionSynced', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      /// sessions tablosu:
      ///   id         → text()()  → withDefault YOK → düz String
      ///   targetLang → text()()  → withDefault YOK → (withDefault VAR → Value)
      ///   startedAt  → integer() → withDefault YOK → düz int
      await db.sessionDao.insertSession(SessionsCompanion.insert(
        id: 'sess-001', // düz String (withDefault YOK)
        targetLang: 'en', // withDefault VAR → Value
        startedAt: now, // withDefault YOK → düz int
        categoriesJson: const Value('["a1"]'),
      ));

      var session = await db.sessionDao.getSessionById('sess-001');
      expect(session?.endedAt, isNull);
      expect(session?.isSynced, false);

      await db.sessionDao.completeSession(
        sessionId: 'sess-001',
        endedAt: now + 300000,
        totalCards: 10,
        correctCards: 8,
        xpEarned: 50,
      );

      session = await db.sessionDao.getSessionById('sess-001');
      expect(session?.endedAt, isNotNull);
      expect(session?.totalCards, 10);
      expect(session?.xpEarned, 50);

      await db.sessionDao.markSessionSynced('sess-001');
      session = await db.sessionDao.getSessionById('sess-001');
      expect(session?.isSynced, true);
    });

    test('AC: getUnsyncedSessions', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.sessionDao.insertSession(SessionsCompanion.insert(
        id: 'sess-unsynced',
        targetLang: 'en',
        startedAt: now,
      ));
      await db.sessionDao.completeSession(
        sessionId: 'sess-unsynced',
        endedAt: now + 1000,
        totalCards: 5,
        correctCards: 5,
        xpEarned: 25,
      );

      await db.sessionDao.insertSession(SessionsCompanion.insert(
        id: 'sess-active',
        targetLang: 'en',
        startedAt: now + 2000,
      ));

      final unsynced = await db.sessionDao.getUnsyncedSessions();
      expect(unsynced.length, 1);
      expect(unsynced.first.id, 'sess-unsynced');
    });
  });

  // ── SyncQueueDao Tests ────────────────────────────────────────────────────

  group('SyncQueueDao', () {
    test('AC: enqueue + getPending + markSynced', () async {
      await db.syncQueueDao.enqueue(
        id: 'sq-001',
        entityType: 'progress',
        entityId: '1:en',
        payloadJson: '{"stability":2.4}',
      );

      var pending = await db.syncQueueDao.getPending(entityType: 'progress');
      expect(pending.length, 1);
      expect(pending.first.entityId, '1:en');

      await db.syncQueueDao.markSynced(['sq-001']);

      pending = await db.syncQueueDao.getPending(entityType: 'progress');
      expect(pending, isEmpty);
    });

    test(
        'AC: incrementRetry + cleanupRetryExceeded — maxRetry=5 sonrası soft-delete',
        () async {
      await db.syncQueueDao.enqueue(
        id: 'sq-fail',
        entityType: 'session',
        entityId: 'sess-999',
        payloadJson: '{}',
      );

      for (int i = 0; i < SyncQueueDao.maxRetry; i++) {
        await db.syncQueueDao.incrementRetry('sq-fail');
      }

      final cleaned = await db.syncQueueDao.cleanupRetryExceeded();
      expect(cleaned, 1);

      final pending = await db.syncQueueDao.getPending(entityType: 'session');
      expect(pending, isEmpty);

      final failedCount = await db.syncQueueDao.getFailedCount();
      expect(failedCount, 1);
    });
  });

  // ── DailyPlanDao Tests ────────────────────────────────────────────────────

  group('DailyPlanDao', () {
    test('AC: upsertPlan + incrementCompleted', () async {
      const today = '2025-02-24';
      final now = DateTime.now().millisecondsSinceEpoch;

      /// daily_plans tablosu:
      ///   planDate   → text()()     → withDefault YOK → düz String
      ///   targetLang → text()()     → withDefault YOK → düz String
      ///   createdAt  → integer()()  → withDefault YOK → düz int
      ///   totalCards → int.withDefault(0) → Value<int>
      await db.dailyPlanDao.upsertPlan(DailyPlansCompanion.insert(
        planDate: today, // withDefault YOK → düz String
        targetLang: 'en', // withDefault YOK → düz String
        createdAt: now, // withDefault YOK → düz int
        cardIdsJson: const Value('[1,2,3]'),
        totalCards: const Value(3),
        dueCount: const Value(2),
        newCount: const Value(1),
        leechCount: const Value(0),
        estimatedMinutes: const Value(5),
      ));

      await db.dailyPlanDao
          .incrementCompleted(planDate: today, targetLang: 'en');
      await db.dailyPlanDao
          .incrementCompleted(planDate: today, targetLang: 'en');

      final plan = await db.dailyPlanDao
          .getTodayPlan(targetLang: 'en', todayDate: today);
      expect(plan?.completedCards, 2);
      expect(plan?.totalCards, 3);

      final isDone = await db.dailyPlanDao
          .isTodayPlanComplete(targetLang: 'en', todayDate: today);
      expect(isDone, false);
    });
  });
}
