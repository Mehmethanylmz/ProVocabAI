// test/srs/daily_planner_test.dart
//
// T-04 Acceptance Criteria:
//   AC-03: due>0 kart varken plan ASLA boş.
//   BP T-04: 10 due + 5 new → 15 kart | leech başta | boş DB → isEmpty.
//   AC-11: buildPlan() < 500ms.
//
// Çalıştır: flutter test test/srs/daily_planner_test.dart

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pratikapp/database/app_database.dart';
import 'package:pratikapp/srs/daily_planner.dart';
import 'package:pratikapp/srs/plan_models.dart';

void main() {
  // ── _interleave() Unit Testleri ───────────────────────────────────────────
  // DailyPlannerTestable extension ile private metoda erişilir.
  // Bu grup Drift DB gerektirmez — sadece PlanCard listesi işler.

  group('_interleave (unit)', () {
    late AppDatabase db;
    late DailyPlanner planner;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      planner = DailyPlanner(progressDao: db.progressDao, wordDao: db.wordDao);
    });
    tearDown(() async => db.close());

    test('10 due + 5 new → 15 kart', () {
      final r = planner.interleaveForTest(
        leeches: [],
        dueCards: _due(10),
        newCards: _new(5),
      );
      expect(r.length, 15);
    });

    test('3:1 oranı — ilk 4: [due,due,due,new]', () {
      final r = planner.interleaveForTest(
        leeches: [],
        dueCards: _due(10),
        newCards: _new(5),
      );
      expect(r[0].source, CardSource.due);
      expect(r[1].source, CardSource.due);
      expect(r[2].source, CardSource.due);
      expect(r[3].source, CardSource.newCard);
    });

    test('3 leech + 10 due + 5 new → leechler pozisyon 0,1,2', () {
      final r = planner.interleaveForTest(
        leeches: _leech(3),
        dueCards: _due(10),
        newCards: _new(5),
      );
      expect(r.length, 18);
      expect(r[0].source, CardSource.leech);
      expect(r[1].source, CardSource.leech);
      expect(r[2].source, CardSource.leech);
      expect(r[3].source, CardSource.due);
    });

    test('sadece leech → tümü leech, due/new yok', () {
      final r = planner.interleaveForTest(
        leeches: _leech(5),
        dueCards: [],
        newCards: [],
      );
      expect(r.length, 5);
      expect(r.every((c) => c.source == CardSource.leech), isTrue);
    });

    test('sadece new kartlar → tümü eklenir', () {
      final r = planner.interleaveForTest(
        leeches: [],
        dueCards: [],
        newCards: _new(5),
      );
      expect(r.length, 5);
      expect(r.every((c) => c.source == CardSource.newCard), isTrue);
    });

    test('10 due + 1 new → due=10, new=1, toplam=11', () {
      final r = planner.interleaveForTest(
        leeches: [],
        dueCards: _due(10),
        newCards: _new(1),
      );
      expect(r.length, 11);
      expect(r.where((c) => c.source == CardSource.due).length, 10);
      expect(r.where((c) => c.source == CardSource.newCard).length, 1);
    });

    test('due=0, new=0, leech=0 → boş liste', () {
      final r = planner.interleaveForTest(
        leeches: [],
        dueCards: [],
        newCards: [],
      );
      expect(r, isEmpty);
    });
  });

  // ── _estimateMinutes() Unit Testleri ──────────────────────────────────────

  group('_estimateMinutes (unit)', () {
    late AppDatabase db;
    late DailyPlanner planner;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      planner = DailyPlanner(progressDao: db.progressDao, wordDao: db.wordDao);
    });
    tearDown(() async => db.close());

    test('0 kart → 0 dakika',
        () => expect(planner.estimateMinutesForTest(0), 0));
    test('10 kart → 4 dakika (ceil(10*0.4))',
        () => expect(planner.estimateMinutesForTest(10), 4));
    test('1 kart → min 1 dakika',
        () => expect(planner.estimateMinutesForTest(1), 1));
    test('300 kart → max 120 dakika',
        () => expect(planner.estimateMinutesForTest(300), 120));
  });

  // ── buildPlan() Integration Testleri ─────────────────────────────────────

  group('buildPlan() integration (in-memory Drift)', () {
    late AppDatabase db;
    late DailyPlanner planner;

    const lang = 'en';
    const date = '2025-02-24';

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      planner = DailyPlanner(progressDao: db.progressDao, wordDao: db.wordDao);
    });
    tearDown(() async => db.close());

    // ── Seed helpers ──────────────────────────────────────────────────────

    Future<void> seedWord(int id, {int rank = 1}) =>
        db.wordDao.insertWordRaw(WordsCompanion.insert(
          id: Value(id),
          partOfSpeech: Value('noun'),
          categoriesJson: Value('["a1"]'),
          contentJson: Value('{"en":{"word":"w","meaning":"m"}}'),
          sentencesJson: Value('{}'),
          difficultyRank: Value(rank),
        ));

    Future<void> seedProgress({
      required int wordId,
      String state = 'review',
      int nextMs = 0,
      bool leech = false,
      int lapses = 0,
    }) =>
        db.into(db.progress).insert(ProgressCompanion.insert(
              wordId: wordId,
              targetLang: lang,
              cardState: Value(state),
              nextReviewMs: Value(nextMs),
              isLeech: Value(leech),
              lapses: Value(lapses),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ));

    // ── AC-03 ─────────────────────────────────────────────────────────────

    test('AC-03: boş DB → plan.isEmpty == true', () async {
      final plan = await planner.buildPlan(
        targetLang: lang,
        categories: [],
        newWordsGoal: 10,
        planDate: date,
      );
      expect(plan.isEmpty, isTrue);
    });

    test('AC-03: due kart varken plan ASLA boş', () async {
      for (int i = 1; i <= 5; i++) {
        await seedWord(i);
        await seedProgress(wordId: i);
      }
      final plan = await planner.buildPlan(
        targetLang: lang,
        categories: [],
        newWordsGoal: 0,
        planDate: date,
      );
      expect(plan.isEmpty, isFalse);
      expect(plan.dueCount, 5);
    });

    // ── Blueprint: 10 due + 5 new = 15 ───────────────────────────────────

    test('Blueprint: 10 due + 5 new → totalCards=15', () async {
      for (int i = 1; i <= 10; i++) {
        await seedWord(i);
        await seedProgress(wordId: i);
      }
      for (int i = 11; i <= 15; i++) await seedWord(i);

      final plan = await planner.buildPlan(
        targetLang: lang,
        categories: [],
        newWordsGoal: 5,
        planDate: date,
      );
      expect(plan.totalCards, 15);
      expect(plan.dueCount, 10);
      expect(plan.newCount, 5);
      expect(plan.leechCount, 0);
    });

    // ── Leech başta ───────────────────────────────────────────────────────

    test('Blueprint: leech kartlar planın başında', () async {
      // 2 leech
      for (int i = 1; i <= 2; i++) {
        await seedWord(i);
        await seedProgress(wordId: i, leech: true, lapses: 4);
      }
      // 5 normal due
      for (int i = 3; i <= 7; i++) {
        await seedWord(i);
        await seedProgress(wordId: i);
      }

      final plan = await planner.buildPlan(
        targetLang: lang,
        categories: [],
        newWordsGoal: 0,
        planDate: date,
      );
      expect(plan.cards.length, 7);
      expect(plan.leechCount, 2);
      expect(plan.cards[0].source, CardSource.leech, reason: 'pos 0: leech');
      expect(plan.cards[1].source, CardSource.leech, reason: 'pos 1: leech');
      expect(plan.cards[2].source, CardSource.due, reason: 'pos 2: due');
    });

    // ── overdueCapPerDay=50 ───────────────────────────────────────────────

    test('overdueCapPerDay=50: 60 due → max 50', () async {
      for (int i = 1; i <= 60; i++) {
        await seedWord(i);
        await seedProgress(wordId: i);
      }
      final plan = await planner.buildPlan(
        targetLang: lang,
        categories: [],
        newWordsGoal: 0,
        planDate: date,
      );
      expect(plan.dueCount, DailyPlannerConfig.overdueCapPerDay);
    });

    // ── newWordsGoal kota ─────────────────────────────────────────────────

    test('newWordsGoal=5: 20 yeni kart varken 5 alınır', () async {
      for (int i = 1; i <= 20; i++) await seedWord(i);
      final plan = await planner.buildPlan(
        targetLang: lang,
        categories: [],
        newWordsGoal: 5,
        planDate: date,
      );
      expect(plan.newCount, 5);
    });

    // ── Metadata ──────────────────────────────────────────────────────────

    test('plan metadata: targetLang, planDate, estimatedMinutes, cardIds',
        () async {
      await seedWord(1);
      await seedProgress(wordId: 1);

      final plan = await planner.buildPlan(
        targetLang: lang,
        categories: [],
        newWordsGoal: 0,
        planDate: date,
      );
      expect(plan.targetLang, lang);
      expect(plan.planDate, date);
      expect(plan.estimatedMinutes, greaterThan(0));
      expect(plan.cardIds, contains(1));
    });

    // ── AC-11: Performance ────────────────────────────────────────────────

    test('AC-11: buildPlan() < 500ms (50 due + 10 new)', () async {
      for (int i = 1; i <= 50; i++) {
        await seedWord(i, rank: (i % 6) + 1);
        await seedProgress(wordId: i);
      }
      for (int i = 51; i <= 60; i++) await seedWord(i);

      final sw = Stopwatch()..start();
      final plan = await planner.buildPlan(
        targetLang: lang,
        categories: [],
        newWordsGoal: 10,
        planDate: date,
      );
      sw.stop();

      expect(plan.totalCards, 60);
      expect(
        sw.elapsedMilliseconds,
        lessThan(500),
        reason: 'buildPlan() ${sw.elapsedMilliseconds}ms > 500ms (AC-11)',
      );
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

List<PlanCard> _due(int n) =>
    List.generate(n, (i) => PlanCard(wordId: i + 1, source: CardSource.due));

List<PlanCard> _new(int n) => List.generate(
    n, (i) => PlanCard(wordId: i + 100, source: CardSource.newCard));

List<PlanCard> _leech(int n) => List.generate(
    n, (i) => PlanCard(wordId: i + 200, source: CardSource.leech));
