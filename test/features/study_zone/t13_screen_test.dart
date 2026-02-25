// test/features/study_zone/t13_screen_test.dart
//
// T-13 Acceptance Criteria:
//   AC: StudyZoneCompleted state'den tüm istatistikler doğru gösterilir
//   AC: plan.isEmpty → "Bugünlük tamamladın" gösterir
//   AC: leechCount > 0 → LeechWarningBanner görünür
//   AC: Tekrar Çalış + Ana Sayfa butonları render oluyor
//
// Çalıştır: flutter test test/features/study_zone/t13_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pratikapp/database/app_database.dart' hide DailyPlan;
import 'package:pratikapp/features/study_zone/domain/usecases/complete_session.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/start_session.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/submit_review.dart';
import 'package:pratikapp/features/study_zone/presentation/state/study_zone_bloc.dart';
import 'package:pratikapp/features/study_zone/presentation/state/study_zone_event.dart';
import 'package:pratikapp/features/study_zone/presentation/state/study_zone_state.dart';
import 'package:pratikapp/features/study_zone/presentation/views/session_result_screen.dart';
import 'package:pratikapp/features/study_zone/presentation/views/study_zone_screen.dart';
import 'package:pratikapp/srs/daily_planner.dart';
import 'package:pratikapp/srs/plan_models.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;

void main() {
  // ── SessionResultScreen ───────────────────────────────────────────────────

  group('SessionResultScreen', () {
    testWidgets('AC: totalCards doğru gösterilir', (tester) async {
      final bloc = _blocWithState(_completedState(total: 10, correct: 8));
      await tester.pumpWidget(_wrapResult(bloc));
      await tester.pump();

      expect(find.byKey(const Key('stat_total')), findsOneWidget);
      expect(find.text('10'), findsWidgets); // stat_total value
    });

    testWidgets('AC: correctCards doğru gösterilir', (tester) async {
      final bloc = _blocWithState(_completedState(total: 10, correct: 8));
      await tester.pumpWidget(_wrapResult(bloc));
      await tester.pump();

      expect(find.byKey(const Key('stat_correct')), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('AC: yanlış kart sayısı hesaplanır (10-8=2)', (tester) async {
      final bloc = _blocWithState(_completedState(total: 10, correct: 8));
      await tester.pumpWidget(_wrapResult(bloc));
      await tester.pump();

      expect(find.byKey(const Key('stat_wrong')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('AC: xpEarned gösterilir (+150 XP)', (tester) async {
      final bloc =
          _blocWithState(_completedState(total: 10, correct: 8, xp: 150));
      await tester.pumpWidget(_wrapResult(bloc));
      await tester.pump();

      expect(find.text('+150 XP'), findsOneWidget);
    });

    testWidgets('AC: accuracy % header\'da gösterilir', (tester) async {
      final bloc = _blocWithState(_completedState(total: 10, correct: 8));
      await tester.pumpWidget(_wrapResult(bloc));
      await tester.pump();

      expect(find.text('%80 doğruluk'), findsOneWidget);
    });

    testWidgets('AC: wrongWordIds > 0 → accordion görünür', (tester) async {
      final bloc = _blocWithState(
          _completedState(total: 5, correct: 3, wrongIds: [1, 2]));
      await tester.pumpWidget(_wrapResult(bloc));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.byKey(const Key('wrong_words_accordion')),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(const Key('wrong_words_accordion')), findsOneWidget);
      expect(find.text('Tekrar Edilecekler (2)'), findsOneWidget);
    });

    testWidgets('AC: wrongWordIds boşsa accordion görünmez', (tester) async {
      final bloc =
          _blocWithState(_completedState(total: 5, correct: 5, wrongIds: []));
      await tester.pumpWidget(_wrapResult(bloc));
      await tester.pump();

      expect(find.byKey(const Key('wrong_words_accordion')), findsNothing);
    });

    testWidgets('AC: 2x XP banner görünüyor', (tester) async {
      final bloc = _blocWithState(_completedState());
      await tester.pumpWidget(_wrapResult(bloc));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.byKey(const Key('rewarded_xp_banner')),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(const Key('rewarded_xp_banner')), findsOneWidget);
      expect(find.text('2x XP Kazan!'), findsOneWidget);
    });

    testWidgets('AC: Tekrar Çalış butonu görünür', (tester) async {
      final bloc = _blocWithState(_completedState());
      await tester.pumpWidget(_wrapResult(bloc));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.byKey(const Key('retry_button')),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
    });

    testWidgets('AC: Ana Sayfa butonu görünür', (tester) async {
      final bloc = _blocWithState(_completedState());
      await tester.pumpWidget(_wrapResult(bloc));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.byKey(const Key('home_button')),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(const Key('home_button')), findsOneWidget);
    });

    testWidgets('Oturum Tamamlandı başlığı görünür', (tester) async {
      final bloc = _blocWithState(_completedState());
      await tester.pumpWidget(_wrapResult(bloc));
      await tester.pump();

      expect(find.text('Oturum Tamamlandı!'), findsOneWidget);
    });

    testWidgets('Accordion expand → wrong word id\'ler listelenir',
        (tester) async {
      final bloc = _blocWithState(
          _completedState(total: 3, correct: 1, wrongIds: [42, 99]));
      await tester.pumpWidget(_wrapResult(bloc));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.byKey(const Key('wrong_words_accordion')),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('wrong_words_accordion')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wrong_word_42')), findsOneWidget);
      expect(find.byKey(const Key('wrong_word_99')), findsOneWidget);
    });

    testWidgets('accuracy 0/0 → %0 doğruluk (division guard)', (tester) async {
      final bloc = _blocWithState(_completedState(total: 0, correct: 0));
      await tester.pumpWidget(_wrapResult(bloc));
      await tester.pump();

      expect(find.text('%0 doğruluk'), findsOneWidget);
    });
  });

  // ── StudyZoneScreen ───────────────────────────────────────────────────────

  group('StudyZoneScreen', () {
    testWidgets('AC: Planning state → skeleton gösterilir', (tester) async {
      final bloc = _blocWithState(const StudyZonePlanning());
      await tester.pumpWidget(_wrapStudyZone(bloc));
      await tester.pump();

      expect(find.byKey(const Key('plan_skeleton')), findsOneWidget);
    });

    testWidgets('AC: Ready state → DailyProgressCard görünür', (tester) async {
      final bloc = _blocWithState(StudyZoneReady(plan: _plan()));
      await tester.pumpWidget(_wrapStudyZone(bloc));
      await tester.pump();

      expect(find.byKey(const Key('daily_progress_card')), findsOneWidget);
      expect(find.byKey(const Key('start_session_button')), findsOneWidget);
    });

    testWidgets('AC: Empty → "Bugünlük tamamladın" gösterir', (tester) async {
      final bloc =
          _blocWithState(const StudyZoneIdle(emptyReason: EmptyReason.allDone));
      await tester.pumpWidget(_wrapStudyZone(bloc));
      await tester.pump();

      expect(find.byKey(const Key('all_done_card')), findsOneWidget);
      expect(find.text('Bugünlük tamamladın!'), findsOneWidget);
    });

    testWidgets('AC: noCardsAvailable → empty card gösterilir', (tester) async {
      final bloc = _blocWithState(
          const StudyZoneIdle(emptyReason: EmptyReason.noCardsAvailable));
      await tester.pumpWidget(_wrapStudyZone(bloc));
      await tester.pump();

      expect(find.byKey(const Key('empty_card')), findsOneWidget);
    });

    testWidgets('AC: leechCount > 0 → LeechWarningBanner görünür',
        (tester) async {
      final bloc = _blocWithState(StudyZoneReady(plan: _plan(leech: 2)));
      await tester.pumpWidget(_wrapStudyZone(bloc));
      await tester.pump();

      expect(find.byKey(const Key('leech_warning_banner')), findsOneWidget);
      expect(find.textContaining('2 zor kart'), findsOneWidget);
    });

    testWidgets('leechCount == 0 → banner görünmez', (tester) async {
      final bloc = _blocWithState(StudyZoneReady(plan: _plan(leech: 0)));
      await tester.pumpWidget(_wrapStudyZone(bloc));
      await tester.pump();

      expect(find.byKey(const Key('leech_warning_banner')), findsNothing);
    });

    testWidgets('Hızlı 5 dk butonu render oluyor', (tester) async {
      final bloc = _blocWithState(StudyZoneReady(plan: _plan()));
      await tester.pumpWidget(_wrapStudyZone(bloc));
      await tester.pump();

      expect(find.byKey(const Key('mini_session_button')), findsOneWidget);
    });

    testWidgets('CategoryFilterChips render oluyor', (tester) async {
      final bloc = _blocWithState(StudyZoneReady(plan: _plan()));
      await tester.pumpWidget(_wrapStudyZone(bloc));
      await tester.pump();

      expect(find.byKey(const Key('category_a1')), findsOneWidget);
    });

    testWidgets('Plan progress bar render oluyor', (tester) async {
      final bloc = _blocWithState(StudyZoneReady(plan: _plan()));
      await tester.pumpWidget(_wrapStudyZone(bloc));
      await tester.pump();

      expect(find.byKey(const Key('plan_progress_bar')), findsOneWidget);
    });

    testWidgets('estimatedMinutes chip render oluyor', (tester) async {
      final bloc = _blocWithState(StudyZoneReady(plan: _plan(minutes: 7)));
      await tester.pumpWidget(_wrapStudyZone(bloc));
      await tester.pump();

      expect(find.text('~7 dk'), findsOneWidget);
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

AppDatabase _newDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase.forTesting(NativeDatabase.memory());
}

/// State'i mock eden Bloc — add() no-op, state sabittir.
/// Factory constructor: tek DB tüm use case'lere paylaşılır → Drift warning yok.
class _MockBloc extends StudyZoneBloc {
  final StudyZoneState _fixedState;
  final List<StudyZoneEvent> addedEvents = [];

  factory _MockBloc(StudyZoneState fixedState) {
    final db = _newDb(); // tek instance
    return _MockBloc._(
      fixedState: fixedState,
      dailyPlanner:
          DailyPlanner(progressDao: db.progressDao, wordDao: db.wordDao),
      startSession: StartSession(db),
      submitReview: SubmitReview(db),
      completeSession: CompleteSession(db),
    );
  }

  _MockBloc._({
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

StudyZoneBloc _blocWithState(StudyZoneState s) => _MockBloc(s);

Widget _wrapResult(StudyZoneBloc bloc) => MaterialApp(
      home: BlocProvider<StudyZoneBloc>.value(
        value: bloc,
        child: const SessionResultScreen(),
      ),
    );

Widget _wrapStudyZone(StudyZoneBloc bloc) => MaterialApp(
      home: BlocProvider<StudyZoneBloc>.value(
        value: bloc,
        child: const StudyZoneScreen(),
      ),
    );

StudyZoneCompleted _completedState({
  int total = 10,
  int correct = 8,
  int xp = 150,
  List<int> wrongIds = const [1, 2],
}) =>
    StudyZoneCompleted(
      totalCards: total,
      correctCards: correct,
      totalTimeMs: 120000,
      xpEarned: xp,
      wrongWordIds: wrongIds,
      sessionId: 'sess-test',
    );

DailyPlan _plan({int leech = 0, int minutes = 4}) => DailyPlan(
      targetLang: 'en',
      planDate: _today(),
      cards: [
        const PlanCard(wordId: 1, source: CardSource.due),
        const PlanCard(wordId: 2, source: CardSource.due),
      ],
      dueCount: 2,
      newCount: 0,
      leechCount: leech,
      estimatedMinutes: minutes,
      createdAt: DateTime.now(),
    );

String _today() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
