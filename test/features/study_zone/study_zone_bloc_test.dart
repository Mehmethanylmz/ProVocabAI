// test/features/study_zone/study_zone_bloc_test.dart
//
// T-10 Acceptance Criteria (Blueprint):
//   BP: LoadPlanRequested → [Planning, Ready]
//   BP: AnswerSubmitted(good) → [Reviewing(xpJustEarned>0)]
//   BP: NextCardRequested (son kart) → [Completed]
//
// Çalıştır: flutter test test/features/study_zone/study_zone_bloc_test.dart
//
// pubspec.yaml dev_dependencies'e şunu ekle:
//   bloc_test: ^9.1.7

import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pratikapp/database/app_database.dart' hide DailyPlan;
import 'package:pratikapp/features/study_zone/domain/usecases/complete_session.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/start_session.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/submit_review.dart';
import 'package:pratikapp/features/study_zone/presentation/state/study_zone_bloc.dart';
import 'package:pratikapp/features/study_zone/presentation/state/study_zone_event.dart';
import 'package:pratikapp/features/study_zone/presentation/state/study_zone_state.dart';
import 'package:pratikapp/srs/daily_planner.dart';
import 'package:pratikapp/srs/fsrs_state.dart';
import 'package:pratikapp/srs/plan_models.dart';

void main() {
  late AppDatabase db;
  late StudyZoneBloc bloc;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    // Seed: 3 due kelime
    for (int i = 1; i <= 3; i++) {
      await db.wordDao.insertWordRaw(WordsCompanion.insert(
        id: Value(i),
        partOfSpeech: const Value('noun'),
        categoriesJson: const Value('["a1"]'),
        contentJson: Value('{"en":{"word":"w$i","meaning":"m$i"}}'),
        sentencesJson: const Value('{}'),
        difficultyRank: const Value(1),
      ));
      await db.into(db.progress).insert(ProgressCompanion.insert(
            wordId: i,
            targetLang: 'en',
            cardState: const Value('review'),
            nextReviewMs: const Value(0),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ));
    }

    bloc = _makeBloc(db);
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  // ── BP: LoadPlanRequested → [Planning, Ready] ─────────────────────────────

  blocTest<StudyZoneBloc, StudyZoneState>(
    'BP: LoadPlanRequested → [StudyZonePlanning, StudyZoneReady]',
    build: () => bloc,
    act: (b) => b.add(const LoadPlanRequested(
      targetLang: 'en',
      categories: [],
      newWordsGoal: 5,
    )),
    expect: () => [
      isA<StudyZonePlanning>(),
      isA<StudyZoneReady>(),
    ],
  );

  blocTest<StudyZoneBloc, StudyZoneState>(
    'LoadPlanRequested: Ready.plan.totalCards == 3',
    build: () => bloc,
    act: (b) => b.add(const LoadPlanRequested(
      targetLang: 'en',
      categories: [],
      newWordsGoal: 0,
    )),
    expect: () => [
      isA<StudyZonePlanning>(),
      isA<StudyZoneReady>().having((s) => s.plan.totalCards, 'totalCards', 3),
    ],
  );

  blocTest<StudyZoneBloc, StudyZoneState>(
    'LoadPlanRequested: boş DB → [Planning, Idle(noCardsAvailable)]',
    build: () {
      final emptyDb = AppDatabase.forTesting(NativeDatabase.memory());
      final b = _makeBloc(emptyDb);
      addTearDown(() async {
        await b.close();
        await emptyDb.close();
      });
      return b;
    },
    act: (b) => b.add(const LoadPlanRequested(
      targetLang: 'en',
      categories: [],
      newWordsGoal: 5,
    )),
    expect: () => [
      isA<StudyZonePlanning>(),
      isA<StudyZoneIdle>().having(
        (s) => s.emptyReason,
        'emptyReason',
        EmptyReason.noCardsAvailable,
      ),
    ],
  );

  // ── BP: AnswerSubmitted(good) → [Reviewing(xpJustEarned>0)] ──────────────

  blocTest<StudyZoneBloc, StudyZoneState>(
    'BP: AnswerSubmitted(good) → [InSession, Reviewing(xpJustEarned>0)]',
    build: () => bloc,
    seed: () => StudyZoneReady(plan: _plan3()),
    act: (b) async {
      b.add(const SessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const AnswerSubmitted(rating: ReviewRating.good, responseMs: 1200));
    },
    expect: () => [
      isA<StudyZoneInSession>(),
      isA<StudyZoneReviewing>().having(
        (s) => s.xpJustEarned,
        'xpJustEarned',
        greaterThan(0),
      ),
    ],
  );

  blocTest<StudyZoneBloc, StudyZoneState>(
    'AnswerSubmitted(again) → Reviewing(xpJustEarned==0)',
    build: () => bloc,
    seed: () => StudyZoneReady(plan: _plan3()),
    act: (b) async {
      b.add(const SessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const AnswerSubmitted(rating: ReviewRating.again, responseMs: 800));
    },
    expect: () => [
      isA<StudyZoneInSession>(),
      isA<StudyZoneReviewing>()
          .having((s) => s.xpJustEarned, 'xpJustEarned', 0),
    ],
  );

  blocTest<StudyZoneBloc, StudyZoneState>(
    'AnswerSubmitted(easy) → Reviewing.lastRating == easy',
    build: () => bloc,
    seed: () => StudyZoneReady(plan: _plan3()),
    act: (b) async {
      b.add(const SessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const AnswerSubmitted(rating: ReviewRating.easy, responseMs: 500));
    },
    expect: () => [
      isA<StudyZoneInSession>(),
      isA<StudyZoneReviewing>().having(
        (s) => s.lastRating,
        'lastRating',
        ReviewRating.easy,
      ),
    ],
  );

  // ── BP: NextCardRequested (son kart) → [Completed] ───────────────────────

  blocTest<StudyZoneBloc, StudyZoneState>(
    'BP: NextCardRequested (son kart) → [InSession, Reviewing, Completed]',
    build: () => bloc,
    seed: () => StudyZoneReady(plan: _plan1()),
    act: (b) async {
      b.add(const SessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const AnswerSubmitted(rating: ReviewRating.good, responseMs: 1000));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const NextCardRequested());
    },
    expect: () => [
      isA<StudyZoneInSession>(),
      isA<StudyZoneReviewing>(),
      isA<StudyZoneCompleted>(),
    ],
  );

  blocTest<StudyZoneBloc, StudyZoneState>(
    'NextCardRequested (son değil) → InSession.cardIndex == 1',
    build: () => bloc,
    seed: () => StudyZoneReady(plan: _plan3()),
    act: (b) async {
      b.add(const SessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const AnswerSubmitted(rating: ReviewRating.good, responseMs: 1000));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const NextCardRequested());
    },
    expect: () => [
      isA<StudyZoneInSession>(),
      isA<StudyZoneReviewing>(),
      isA<StudyZoneInSession>().having((s) => s.cardIndex, 'cardIndex', 1),
    ],
  );

  // ── SessionAborted ────────────────────────────────────────────────────────

  blocTest<StudyZoneBloc, StudyZoneState>(
    'SessionAborted → Idle',
    build: () => bloc,
    seed: () => StudyZoneReady(plan: _plan3()),
    act: (b) async {
      b.add(const SessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const SessionAborted());
    },
    expect: () => [
      isA<StudyZoneInSession>(),
      isA<StudyZoneIdle>(),
    ],
  );

  // ── AppLifecycleChanged ───────────────────────────────────────────────────

  blocTest<StudyZoneBloc, StudyZoneState>(
    'AppLifecycleChanged(paused) → Paused; resumed → InSession',
    build: () => bloc,
    seed: () => StudyZoneReady(plan: _plan3()),
    act: (b) async {
      b.add(const SessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const AppLifecycleChanged(AppLifecycleState.paused));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      b.add(const AppLifecycleChanged(AppLifecycleState.resumed));
    },
    expect: () => [
      isA<StudyZoneInSession>(),
      isA<StudyZonePaused>(),
      isA<StudyZoneInSession>(),
    ],
  );

  // ── RewardedAdCompleted ───────────────────────────────────────────────────

  blocTest<StudyZoneBloc, StudyZoneState>(
    'RewardedAdCompleted(doubleXP) → hasRewardedAdBonus == true',
    build: () => bloc,
    seed: () => StudyZoneReady(plan: _plan3()),
    act: (b) async {
      b.add(const SessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const RewardedAdCompleted(RewardedBonus.doubleXP));
    },
    expect: () => [
      isA<StudyZoneInSession>(),
      isA<StudyZoneInSession>().having(
        (s) => s.hasRewardedAdBonus,
        'hasRewardedAdBonus',
        true,
      ),
    ],
  );

  // ── Completed istatistikler ───────────────────────────────────────────────

  blocTest<StudyZoneBloc, StudyZoneState>(
    'Completed: 2 good + 1 again → correctCards=2, wrongWordIds.length=1',
    build: () => bloc,
    seed: () => StudyZoneReady(plan: _plan3()),
    act: (b) async {
      b.add(const SessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      // Kart 1: good
      b.add(const AnswerSubmitted(rating: ReviewRating.good, responseMs: 500));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const NextCardRequested());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      // Kart 2: again
      b.add(const AnswerSubmitted(rating: ReviewRating.again, responseMs: 500));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const NextCardRequested());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      // Kart 3: good
      b.add(const AnswerSubmitted(rating: ReviewRating.good, responseMs: 500));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const NextCardRequested()); // son kart → Completed
    },
    verify: (b) {
      final s = b.state as StudyZoneCompleted;
      expect(s.correctCards, 2);
      expect(s.totalCards, 3);
      expect(s.wrongWordIds.length, 1);
      expect(s.xpEarned, greaterThan(0));
    },
  );

  // ── Streak ────────────────────────────────────────────────────────────────

  blocTest<StudyZoneBloc, StudyZoneState>(
    'Streak: again sonrası streak sıfırlanır',
    build: () => bloc,
    seed: () => StudyZoneReady(plan: _plan3()),
    act: (b) async {
      b.add(const SessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const AnswerSubmitted(rating: ReviewRating.again, responseMs: 500));
    },
    expect: () => [
      isA<StudyZoneInSession>(),
      isA<StudyZoneReviewing>()
          .having((s) => s.sessionStreak, 'sessionStreak', 0),
    ],
  );

  blocTest<StudyZoneBloc, StudyZoneState>(
    'Streak: good sonrası streak artar',
    build: () => bloc,
    seed: () => StudyZoneReady(plan: _plan3()),
    act: (b) async {
      b.add(const SessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      b.add(const AnswerSubmitted(rating: ReviewRating.good, responseMs: 500));
    },
    expect: () => [
      isA<StudyZoneInSession>(),
      isA<StudyZoneReviewing>()
          .having((s) => s.sessionStreak, 'sessionStreak', 1),
    ],
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

StudyZoneBloc _makeBloc(AppDatabase db) => StudyZoneBloc(
      dailyPlanner:
          DailyPlanner(progressDao: db.progressDao, wordDao: db.wordDao),
      startSession: StartSession(db),
      submitReview: SubmitReview(db),
      completeSession: CompleteSession(db),
    );

DailyPlan _plan3() => DailyPlan(
      targetLang: 'en',
      planDate: _today(),
      cards: [
        const PlanCard(wordId: 1, source: CardSource.due),
        const PlanCard(wordId: 2, source: CardSource.due),
        const PlanCard(wordId: 3, source: CardSource.due),
      ],
      dueCount: 3,
      newCount: 0,
      leechCount: 0,
      estimatedMinutes: 2,
      createdAt: DateTime.now(),
    );

DailyPlan _plan1() => DailyPlan(
      targetLang: 'en',
      planDate: _today(),
      cards: [const PlanCard(wordId: 1, source: CardSource.due)],
      dueCount: 1,
      newCount: 0,
      leechCount: 0,
      estimatedMinutes: 1,
      createdAt: DateTime.now(),
    );

String _today() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
