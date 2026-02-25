// test/features/study_zone/quiz_screen_test.dart
//
// T-12 Acceptance Criteria:
//   AC: Cevap seçilince ReviewRatingSheet görünüyor
//   AC: 3 sn sonra GOOD default emit edilir
//   AC: Rating seçilince NextCardRequested Bloc'a gönderilir

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;

import 'package:pratikapp/database/app_database.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/complete_session.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/start_session.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/submit_review.dart';
import 'package:pratikapp/features/study_zone/presentation/state/study_zone_bloc.dart';
import 'package:pratikapp/features/study_zone/presentation/state/study_zone_event.dart';
import 'package:pratikapp/features/study_zone/presentation/state/study_zone_state.dart';
import 'package:pratikapp/features/study_zone/presentation/views/quiz_screen.dart';
import 'package:pratikapp/features/study_zone/presentation/widgets/review_rating_sheet.dart';
import 'package:pratikapp/srs/daily_planner.dart';
import 'package:pratikapp/srs/fsrs_state.dart';
import 'package:pratikapp/srs/mode_selector.dart';
import 'package:pratikapp/srs/plan_models.dart';

// ── Shared DB factory — Drift multiple-DB uyarısını bastır ───────────────────

AppDatabase _newDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase.forTesting(NativeDatabase.memory());
}

// ── _FakeBloc — tek DB, state sabit, add() no-op ─────────────────────────────

class _FakeBloc extends StudyZoneBloc {
  final List<StudyZoneEvent> addedEvents = [];
  final StudyZoneState _fixedState;

  factory _FakeBloc({StudyZoneState? initialState}) {
    final db = _newDb();
    return _FakeBloc._(
      fixedState: initialState ?? const StudyZoneIdle(),
      dailyPlanner:
          DailyPlanner(progressDao: db.progressDao, wordDao: db.wordDao),
      startSession: StartSession(db),
      submitReview: SubmitReview(db),
      completeSession: CompleteSession(db),
    );
  }

  _FakeBloc._({
    required StudyZoneState fixedState,
    required DailyPlanner dailyPlanner,
    required StartSession startSession,
    required SubmitReview submitReview,
    required CompleteSession completeSession,
  })  : _fixedState = fixedState,
        super(
          dailyPlanner: dailyPlanner,
          startSession: startSession,
          submitReview: submitReview,
          completeSession: completeSession,
        );

  @override
  StudyZoneState get state => _fixedState;

  @override
  void add(StudyZoneEvent event) => addedEvents.add(event);
}

// ── TESTS ─────────────────────────────────────────────────────────────────────

void main() {
  // ── ReviewRatingSheet ─────────────────────────────────────────────────────

  group('ReviewRatingSheet', () {
    // Sheet doğrudan body'de render — LinearProgressIndicator erişilebilir
    testWidgets('AC: 4 rating butonu görünüyor', (tester) async {
      await tester.pumpWidget(_wrapSheetDirect(_FakeBloc()));
      await tester.pump();

      expect(find.text('Çok Zor'), findsOneWidget);
      expect(find.text('Zor'), findsOneWidget);
      expect(find.text('İyi'), findsOneWidget);
      expect(find.text('Kolay'), findsOneWidget);
    });

    testWidgets('AC: "İyi" butonu isDefault (key rating_good)', (tester) async {
      await tester.pumpWidget(_wrapSheetDirect(_FakeBloc()));
      await tester.pump();

      expect(find.byKey(const ValueKey('rating_good')), findsOneWidget);
    });

    testWidgets('AC: Rating seçilince AnswerSubmitted event emit edilir',
        (tester) async {
      final bloc = _FakeBloc();
      await tester.pumpWidget(_wrapSheetDirect(bloc));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('rating_easy')));
      await tester.pump();

      expect(bloc.addedEvents, contains(isA<AnswerSubmitted>()));
      expect(
        bloc.addedEvents.whereType<AnswerSubmitted>().first.rating,
        ReviewRating.easy,
      );
    });

    testWidgets('AC: 3 sn sonra GOOD default emit edilir', (tester) async {
      final bloc = _FakeBloc();
      await tester.pumpWidget(_wrapSheetDirect(bloc));
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));

      expect(bloc.addedEvents, contains(isA<AnswerSubmitted>()));
      expect(
        bloc.addedEvents.whereType<AnswerSubmitted>().first.rating,
        ReviewRating.good,
        reason: '3sn sonra GOOD default seçilmeli',
      );
    });

    testWidgets('Countdown bar görünüyor', (tester) async {
      await tester.pumpWidget(_wrapSheetDirect(_FakeBloc()));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });
  });

  // ── QuizScreen ────────────────────────────────────────────────────────────

  group('QuizScreen', () {
    testWidgets('AC: InSession → progress bar + 4 seçenek', (tester) async {
      await tester.pumpWidget(_wrapQuiz(_FakeBloc(initialState: _inSession())));
      await tester.pump();

      expect(find.byKey(const Key('quiz_progress_bar')), findsOneWidget);
      expect(find.byKey(const Key('option_0')), findsOneWidget);
      expect(find.byKey(const Key('option_1')), findsOneWidget);
      expect(find.byKey(const Key('option_2')), findsOneWidget);
      expect(find.byKey(const Key('option_3')), findsOneWidget);
    });

    testWidgets('AC: Hint butonu başta görünür', (tester) async {
      await tester.pumpWidget(_wrapQuiz(_FakeBloc(initialState: _inSession())));
      await tester.pump();

      expect(find.byKey(const Key('hint_button')), findsOneWidget);
    });

    testWidgets('AC: Hint butonuna tıklayınca hint gösterilir', (tester) async {
      await tester.pumpWidget(_wrapQuiz(_FakeBloc(initialState: _inSession())));
      await tester.pump();

      await tester.tap(find.byKey(const Key('hint_button')));
      await tester.pump();

      expect(find.byKey(const Key('hint_button')), findsNothing);
      expect(find.text('💡 İpucu: anlamla ilgili bir bağlam'), findsOneWidget);
    });

    testWidgets('AC: Cevap seçilince ReviewRatingSheet açılır', (tester) async {
      await tester.pumpWidget(_wrapQuiz(_FakeBloc(initialState: _inSession())));
      await tester.pump();

      await tester.tap(find.byKey(const Key('option_0')));
      // pumpAndSettle() kullanma — FakeBloc.add() no-op, sheet pop olmaz
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text('Bu kelimeyi ne kadar iyi hatırladın?'),
        findsOneWidget,
      );
    });

    testWidgets('AC: Reviewing → Devam butonu görünür', (tester) async {
      await tester.pumpWidget(_wrapQuiz(_FakeBloc(initialState: _reviewing())));
      await tester.pump();

      expect(find.byKey(const Key('next_card_button')), findsOneWidget);
    });

    testWidgets('AC: Devam butonuna tıklayınca NextCardRequested emit',
        (tester) async {
      final bloc = _FakeBloc(initialState: _reviewing());
      await tester.pumpWidget(_wrapQuiz(bloc));
      await tester.pump();

      await tester.tap(find.byKey(const Key('next_card_button')));
      await tester.pump();

      expect(bloc.addedEvents, contains(isA<NextCardRequested>()));
    });

    testWidgets('X butonu → SessionAborted emit', (tester) async {
      final bloc = _FakeBloc(initialState: _inSession());
      await tester.pumpWidget(_wrapQuiz(bloc));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(bloc.addedEvents, contains(isA<SessionAborted>()));
    });

    testWidgets('Streak > 0 → ateş ikonu görünür', (tester) async {
      await tester.pumpWidget(
          _wrapQuiz(_FakeBloc(initialState: _inSession(streak: 3))));
      await tester.pump();

      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('hasRewardedAdBonus → 2x XP badge görünür', (tester) async {
      await tester.pumpWidget(
          _wrapQuiz(_FakeBloc(initialState: _inSession(hasBonus: true))));
      await tester.pump();

      expect(find.text('2x XP'), findsOneWidget);
    });
  });
}

// ── Widget wrappers ───────────────────────────────────────────────────────────

Widget _wrapSheetDirect(StudyZoneBloc bloc) => MaterialApp(
      home: BlocProvider<StudyZoneBloc>.value(
        value: bloc,
        child: const Scaffold(body: ReviewRatingSheet(responseMs: 1000)),
      ),
    );

Widget _wrapQuiz(StudyZoneBloc bloc) => MaterialApp(
      home: BlocProvider<StudyZoneBloc>.value(
        value: bloc,
        child: const QuizScreen(),
      ),
    );

// ── State builders ────────────────────────────────────────────────────────────

StudyZoneInSession _inSession({int streak = 0, bool hasBonus = false}) =>
    StudyZoneInSession(
      currentCard: const PlanCard(wordId: 1, source: CardSource.due),
      sessionId: 'sess-test',
      sessionStreak: streak,
      sessionCardCount: 1,
      hasRewardedAdBonus: hasBonus,
      currentMode: StudyMode.mcq,
      timerStart: DateTime.now(),
      cardIndex: 0,
      totalCards: 5,
    );

StudyZoneReviewing _reviewing() => StudyZoneReviewing(
      currentCard: const PlanCard(wordId: 1, source: CardSource.due),
      sessionId: 'sess-test',
      sessionStreak: 1,
      sessionCardCount: 1,
      hasRewardedAdBonus: false,
      currentMode: StudyMode.mcq,
      cardIndex: 0,
      totalCards: 5,
      lastRating: ReviewRating.good,
      updatedFSRS: FSRSState(
        stability: 5.0,
        difficulty: 5.0,
        retrievability: 0.9,
        cardState: CardState.review,
        nextReview: DateTime.now().add(const Duration(days: 5)),
        lastReview: DateTime.now(),
        repetitions: 3,
        lapses: 0,
      ),
      xpJustEarned: 10,
    );
