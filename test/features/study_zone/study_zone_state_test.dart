// test/features/study_zone/study_zone_state_test.dart
//
// T-09 Acceptance Criteria:
//   AC: Tüm state'ler Equatable (props ile eşitlik)
//   AC: StudyZoneInSession.copyWith() çalışıyor
//   AC: StudyZoneReviewing.toInSession() doğru geçiş yapıyor
//   AC: Tüm event props doğru
//
// Çalıştır: flutter test test/features/study_zone/study_zone_state_test.dart

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';

import 'package:pratikapp/features/study_zone/presentation/state/study_zone_event.dart';
import 'package:pratikapp/features/study_zone/presentation/state/study_zone_state.dart';
import 'package:pratikapp/srs/fsrs_state.dart';
import 'package:pratikapp/srs/mode_selector.dart';
import 'package:pratikapp/srs/plan_models.dart';

void main() {
  // ── State Equatable ───────────────────────────────────────────────────────

  group('StudyZoneState — Equatable', () {
    test('StudyZoneIdle: aynı props → equal', () {
      expect(
        const StudyZoneIdle(emptyReason: EmptyReason.allDone),
        const StudyZoneIdle(emptyReason: EmptyReason.allDone),
      );
    });

    test('StudyZoneIdle: farklı emptyReason → not equal', () {
      expect(
        const StudyZoneIdle(emptyReason: EmptyReason.allDone),
        isNot(const StudyZoneIdle(emptyReason: EmptyReason.noCardsAvailable)),
      );
    });

    test('StudyZonePlanning: her instance equal (prop yok)', () {
      expect(const StudyZonePlanning(), const StudyZonePlanning());
    });

    test('StudyZoneError: aynı message → equal', () {
      expect(
        const StudyZoneError(message: 'err'),
        const StudyZoneError(message: 'err'),
      );
    });

    test('StudyZoneError: farklı message → not equal', () {
      expect(
        const StudyZoneError(message: 'a'),
        isNot(const StudyZoneError(message: 'b')),
      );
    });

    test('StudyZoneReady: aynı plan → equal', () {
      final plan = _plan();
      expect(StudyZoneReady(plan: plan), StudyZoneReady(plan: plan));
    });

    test('StudyZoneCompleted: aynı props → equal', () {
      final s1 = _completed();
      final s2 = _completed();
      expect(s1, s2);
    });

    test('StudyZoneCompleted.accuracy: 8/10 = 0.8', () {
      final s = StudyZoneCompleted(
        totalCards: 10,
        correctCards: 8,
        totalTimeMs: 60000,
        xpEarned: 100,
        wrongWordIds: [1, 2],
        sessionId: 'sid',
      );
      expect(s.accuracy, closeTo(0.8, 0.001));
    });

    test('StudyZoneCompleted.accuracy: 0 kart → 0.0 (division by zero guard)',
        () {
      final s = StudyZoneCompleted(
        totalCards: 0,
        correctCards: 0,
        totalTimeMs: 0,
        xpEarned: 0,
        wrongWordIds: [],
        sessionId: 'sid',
      );
      expect(s.accuracy, 0.0);
    });
  });

  // ── StudyZoneInSession.copyWith ───────────────────────────────────────────

  group('StudyZoneInSession.copyWith', () {
    test('copyWith: sadece sessionStreak değişir', () {
      final base = _inSession();
      final updated = base.copyWith(sessionStreak: 5);
      expect(updated.sessionStreak, 5);
      expect(updated.sessionId, base.sessionId);
      expect(updated.currentCard, base.currentCard);
    });

    test('copyWith: hasRewardedAdBonus değişir', () {
      final base = _inSession();
      final updated = base.copyWith(hasRewardedAdBonus: true);
      expect(updated.hasRewardedAdBonus, isTrue);
      expect(base.hasRewardedAdBonus, isFalse); // immutable
    });

    test('copyWith: currentMode değişir', () {
      final base = _inSession();
      final updated = base.copyWith(currentMode: StudyMode.speaking);
      expect(updated.currentMode, StudyMode.speaking);
    });

    test('copyWith: hiçbir şey değişmeden çağrılırsa props aynı', () {
      final base = _inSession();
      final copy = base.copyWith();
      expect(base, copy);
    });

    test('copyWith: cardIndex + sessionCardCount birlikte güncellenir', () {
      final base = _inSession(cardIndex: 0, cardCount: 1);
      final updated = base.copyWith(cardIndex: 1, sessionCardCount: 2);
      expect(updated.cardIndex, 1);
      expect(updated.sessionCardCount, 2);
    });
  });

  // ── StudyZoneReviewing.toInSession ────────────────────────────────────────

  group('StudyZoneReviewing.toInSession', () {
    test('toInSession: sessionCardCount + 1 artar', () {
      final reviewing = _reviewing(cardCount: 3);
      final next = reviewing.toInSession(
        nextCard: _card(wordId: 99),
        nextCardIndex: 4,
        nextMode: StudyMode.listening,
        newStreak: 2,
        timerStart: DateTime.now(),
      );
      expect(next.sessionCardCount, 4);
    });

    test('toInSession: hasRewardedAdBonus reset → false', () {
      final reviewing = _reviewing();
      final next = reviewing.toInSession(
        nextCard: _card(wordId: 99),
        nextCardIndex: 1,
        nextMode: StudyMode.mcq,
        newStreak: 0,
        timerStart: DateTime.now(),
      );
      expect(next.hasRewardedAdBonus, isFalse);
    });

    test('toInSession: nextCard doğru set edilir', () {
      final reviewing = _reviewing();
      final nextCard = _card(wordId: 42);
      final next = reviewing.toInSession(
        nextCard: nextCard,
        nextCardIndex: 2,
        nextMode: StudyMode.speaking,
        newStreak: 3,
        timerStart: DateTime.now(),
      );
      expect(next.currentCard.wordId, 42);
      expect(next.currentMode, StudyMode.speaking);
      expect(next.sessionStreak, 3);
    });

    test('toInSession: sessionId korunur', () {
      final reviewing = _reviewing();
      final next = reviewing.toInSession(
        nextCard: _card(wordId: 1),
        nextCardIndex: 0,
        nextMode: StudyMode.mcq,
        newStreak: 0,
        timerStart: DateTime.now(),
      );
      expect(next.sessionId, reviewing.sessionId);
    });
  });

  // ── Event Props ───────────────────────────────────────────────────────────

  group('StudyZoneEvent — props', () {
    test('LoadPlanRequested: props [targetLang, categories, newWordsGoal]', () {
      final e = const LoadPlanRequested(
        targetLang: 'en',
        categories: ['a1'],
        newWordsGoal: 10,
      );
      expect(e.props, [
        'en',
        ['a1'],
        10
      ]);
    });

    test('LoadPlanRequested: aynı props → equal', () {
      expect(
        const LoadPlanRequested(
            targetLang: 'en', categories: ['a1'], newWordsGoal: 10),
        const LoadPlanRequested(
            targetLang: 'en', categories: ['a1'], newWordsGoal: 10),
      );
    });

    test('AnswerSubmitted: props [rating, responseMs]', () {
      const e = AnswerSubmitted(rating: ReviewRating.good, responseMs: 1200);
      expect(e.props, [ReviewRating.good, 1200]);
    });

    test('AnswerSubmitted: farklı rating → not equal', () {
      expect(
        const AnswerSubmitted(rating: ReviewRating.good, responseMs: 1000),
        isNot(
            const AnswerSubmitted(rating: ReviewRating.easy, responseMs: 1000)),
      );
    });

    test('SessionStarted: her instance equal', () {
      expect(const SessionStarted(), const SessionStarted());
    });

    test('NextCardRequested: her instance equal', () {
      expect(const NextCardRequested(), const NextCardRequested());
    });

    test('SessionAborted: her instance equal', () {
      expect(const SessionAborted(), const SessionAborted());
    });

    test('AppLifecycleChanged: props [state]', () {
      const e = AppLifecycleChanged(AppLifecycleState.paused);
      expect(e.props, [AppLifecycleState.paused]);
    });

    test('RewardedAdCompleted: props [bonus]', () {
      const e = RewardedAdCompleted(RewardedBonus.doubleXP);
      expect(e.props, [RewardedBonus.doubleXP]);
    });

    test('PlanDateChanged: props [newDate]', () {
      const e = PlanDateChanged('2025-02-25');
      expect(e.props, ['2025-02-25']);
    });
  });

  // ── StudyZonePaused ───────────────────────────────────────────────────────

  group('StudyZonePaused', () {
    test('snapshot korunur', () {
      final snap = _inSession();
      final paused = StudyZonePaused(snapshot: snap);
      expect(paused.snapshot, snap);
    });

    test('aynı snapshot → equal', () {
      final snap = _inSession();
      expect(StudyZonePaused(snapshot: snap), StudyZonePaused(snapshot: snap));
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

PlanCard _card({int wordId = 1, CardSource source = CardSource.due}) =>
    PlanCard(wordId: wordId, source: source);

DailyPlan _plan({int due = 5, int newC = 3}) => DailyPlan(
      targetLang: 'en',
      planDate: '2025-02-24',
      cards: List.generate(due + newC, (i) => _card(wordId: i + 1)),
      dueCount: due,
      newCount: newC,
      leechCount: 0,
      estimatedMinutes: 4,
      createdAt: DateTime.now(),
    );

StudyZoneInSession _inSession({
  int cardIndex = 0,
  int cardCount = 1,
}) =>
    StudyZoneInSession(
      currentCard: _card(),
      sessionId: 'test-session-id',
      sessionStreak: 0,
      sessionCardCount: cardCount,
      hasRewardedAdBonus: false,
      currentMode: StudyMode.mcq,
      timerStart: DateTime.now(),
      cardIndex: cardIndex,
      totalCards: 10,
    );

StudyZoneReviewing _reviewing({int cardCount = 3}) => StudyZoneReviewing(
      currentCard: _card(),
      sessionId: 'test-session-id',
      sessionStreak: 2,
      sessionCardCount: cardCount,
      hasRewardedAdBonus: false,
      currentMode: StudyMode.mcq,
      cardIndex: 0,
      totalCards: 10,
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

StudyZoneCompleted _completed() => const StudyZoneCompleted(
      totalCards: 10,
      correctCards: 8,
      totalTimeMs: 120000,
      xpEarned: 150,
      wrongWordIds: [3, 7],
      sessionId: 'sess-001',
    );
