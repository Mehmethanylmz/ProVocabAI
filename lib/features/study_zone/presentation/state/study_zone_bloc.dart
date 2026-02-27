// lib/features/study_zone/presentation/state/study_zone_bloc.dart
//
// Blueprint T-10: StudyZoneBloc — tüm handler'lar.
// Blueprint E.2 Event→Handler tablosuna birebir uyumlu.

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../srs/daily_planner.dart';
import '../../../../srs/fsrs_engine.dart';
import '../../../../srs/fsrs_state.dart';
import '../../../../srs/leech_handler.dart';
import '../../../../srs/mode_selector.dart';
import '../../../../srs/plan_models.dart';
import '../../../../srs/xp_calculator.dart';
import '../../domain/usecases/complete_session.dart';
import '../../domain/usecases/start_session.dart';
import '../../domain/usecases/submit_review.dart';
import 'study_zone_event.dart';
import 'study_zone_state.dart';

// ── AdService (abstract — Sprint 4'te implement edilir) ──────────────────────

abstract class AdService {
  bool get isInterstitialReady;
  Future<void> showInterstitialIfReady();
}

class NoOpAdService implements AdService {
  const NoOpAdService();
  @override
  bool get isInterstitialReady => false;
  @override
  Future<void> showInterstitialIfReady() async {}
}

// ── StudyZoneBloc ─────────────────────────────────────────────────────────────

class StudyZoneBloc extends Bloc<StudyZoneEvent, StudyZoneState> {
  final DailyPlanner _dailyPlanner;
  final StartSession _startSession;
  final SubmitReview _submitReview;
  final CompleteSession _completeSession;
  final FSRSEngine _fsrs;
  final AdService _adService;

  /// Interstitial trigger — her N cevaptan sonra.
  static const int _interstitialTriggerCount = 15;

  // ── Session-scoped mutable state ──────────────────────────────────────────
  // Bloc dışına çıkmaz, her session başında sıfırlanır.

  final Map<String, int> _modeHistory = {};
  List<PlanCard> _planCards = [];
  DateTime? _sessionStartTime;
  int _sessionXP = 0;
  final List<int> _wrongWordIds = [];
  int _correctCards = 0;
  int _answerCount = 0;

  /// Plan yüklenirken kullanılan targetLang (submitReview'a geçmek için).
  String _targetLang = 'en';

  StudyZoneBloc({
    required DailyPlanner dailyPlanner,
    required StartSession startSession,
    required SubmitReview submitReview,
    required CompleteSession completeSession,
    FSRSEngine fsrs = const FSRSEngine(),
    AdService adService = const NoOpAdService(),
  })  : _dailyPlanner = dailyPlanner,
        _startSession = startSession,
        _submitReview = submitReview,
        _completeSession = completeSession,
        _fsrs = fsrs,
        _adService = adService,
        super(const StudyZoneIdle()) {
    on<LoadPlanRequested>(_onLoadPlan);
    on<SessionStarted>(_onSessionStarted);
    on<AnswerSubmitted>(_onAnswerSubmitted);
    on<NextCardRequested>(_onNextCard);
    on<SessionAborted>(_onSessionAborted);
    on<AppLifecycleChanged>(_onLifecycleChange);
    on<RewardedAdCompleted>(_onRewardedAdCompleted);
    on<PlanDateChanged>(_onPlanDateChanged);
  }

  // ── Handler: _onLoadPlan ──────────────────────────────────────────────────
  // Idle → Planning → Ready | Idle(empty) | Error

  Future<void> _onLoadPlan(
    LoadPlanRequested event,
    Emitter<StudyZoneState> emit,
  ) async {
    _targetLang = event.targetLang;
    emit(const StudyZonePlanning());

    try {
      final plan = await _dailyPlanner.buildPlan(
        targetLang: event.targetLang,
        categories: event.categories,
        newWordsGoal: event.newWordsGoal,
        planDate: _todayDate(),
      );

      if (plan.isEmpty) {
        emit(const StudyZoneIdle(emptyReason: EmptyReason.noCardsAvailable));
      } else {
        emit(StudyZoneReady(plan: plan));
      }
    } catch (e, st) {
      addError(e, st);
      emit(StudyZoneError(message: e.toString()));
    }
  }

  // ── Handler: _onSessionStarted ────────────────────────────────────────────
  // Ready → InSession

  Future<void> _onSessionStarted(
    SessionStarted event,
    Emitter<StudyZoneState> emit,
  ) async {
    final ready = state;
    if (ready is! StudyZoneReady) return;

    // Session state sıfırla
    _planCards = List.of(ready.plan.cards);
    _modeHistory.clear();
    _sessionXP = 0;
    _wrongWordIds.clear();
    _correctCards = 0;
    _answerCount = 0;
    _sessionStartTime = DateTime.now();

    final firstCard = _planCards.first;
    final mode = _selectMode(firstCard, isMiniSession: false);

    final sessionId = await _startSession(
      targetLang: ready.plan.targetLang,
      categories: [],
      mode: mode,
    );
    _incrementMode(mode);

    emit(StudyZoneInSession(
      currentCard: firstCard,
      sessionId: sessionId,
      sessionStreak: 0,
      sessionCardCount: 1,
      hasRewardedAdBonus: false,
      currentMode: mode,
      timerStart: DateTime.now(),
      cardIndex: 0,
      totalCards: _planCards.length,
    ));
  }

  // ── Handler: _onAnswerSubmitted ───────────────────────────────────────────
  // InSession → Reviewing

  Future<void> _onAnswerSubmitted(
    AnswerSubmitted event,
    Emitter<StudyZoneState> emit,
  ) async {
    final inSession = state;
    if (inSession is! StudyZoneInSession) return;

    final card = inSession.currentCard;
    final rating = event.rating;

    // 1. FSRS güncelle
    final updatedFSRS = _computeFSRS(
      card: card,
      rating: rating,
      mode: inSession.currentMode,
    );

    // 2. XP
    final xp = XPCalculator.calculateReviewXP(
      mode: inSession.currentMode,
      rating: rating,
      isNew: card.source == CardSource.newCard,
      streak: inSession.sessionStreak,
      hasBonus: inSession.hasRewardedAdBonus,
    );

    // 3. Streak
    final newStreak =
        rating != ReviewRating.again ? inSession.sessionStreak + 1 : 0;

    // 4. SubmitReview (Drift transaction)
    // stabilityBefore: FSRS hesaplanmadan önce mevcut değer.
    // initNewCard kullanıldığından cold-start stability = 0.5 (w[2] default).
    const stabilityBefore =
        0.5; // TODO T-Sprint3: ProgressDao'dan mevcut state çek
    await _submitReview(SubmitReviewParams(
      wordId: card.wordId,
      targetLang: _targetLang,
      sessionId: inSession.sessionId,
      updatedFSRS: updatedFSRS,
      stabilityBefore: stabilityBefore,
      rating: rating,
      mode: inSession.currentMode,
      responseMs: event.responseMs,
      xpEarned: xp,
      isNew: card.source == CardSource.newCard,
    ));

    // 5. Session istatistikleri
    _sessionXP += xp;
    _answerCount++;
    if (rating == ReviewRating.again) {
      _wrongWordIds.add(card.wordId);
    } else {
      _correctCards++;
    }

    // 6. Interstitial kontrolü (fire-and-forget)
    _checkInterstitialAd();

    emit(StudyZoneReviewing(
      currentCard: card,
      sessionId: inSession.sessionId,
      sessionStreak: newStreak,
      sessionCardCount: inSession.sessionCardCount,
      hasRewardedAdBonus: inSession.hasRewardedAdBonus,
      currentMode: inSession.currentMode,
      cardIndex: inSession.cardIndex,
      totalCards: inSession.totalCards,
      lastRating: rating,
      updatedFSRS: updatedFSRS,
      xpJustEarned: xp,
    ));
  }

  // ── Handler: _onNextCard ──────────────────────────────────────────────────
  // Reviewing → InSession | Completed

  Future<void> _onNextCard(
    NextCardRequested event,
    Emitter<StudyZoneState> emit,
  ) async {
    final reviewing = state;
    if (reviewing is! StudyZoneReviewing) return;

    final nextIndex = reviewing.cardIndex + 1;

    if (nextIndex >= _planCards.length) {
      await _finishSession(reviewing, emit);
      return;
    }

    final nextCard = _planCards[nextIndex];
    final nextMode = _selectMode(nextCard, isMiniSession: false);
    _incrementMode(nextMode);

    emit(reviewing.toInSession(
      nextCard: nextCard,
      nextCardIndex: nextIndex,
      nextMode: nextMode,
      newStreak: reviewing.sessionStreak,
      timerStart: DateTime.now(),
    ));
  }

  // ── Handler: _onSessionAborted ────────────────────────────────────────────

  Future<void> _onSessionAborted(
    SessionAborted event,
    Emitter<StudyZoneState> emit,
  ) async {
    final sessionId = _extractSessionId(state);
    if (sessionId != null) {
      await _completeSession(CompleteSessionParams(
        sessionId: sessionId,
        totalCards: _answerCount,
        correctCards: _correctCards,
        xpEarned: _sessionXP,
      ));
    }
    emit(const StudyZoneIdle());
  }

  // ── Handler: _onLifecycleChange ───────────────────────────────────────────

  void _onLifecycleChange(
    AppLifecycleChanged event,
    Emitter<StudyZoneState> emit,
  ) {
    if (event.state == AppLifecycleState.paused &&
        state is StudyZoneInSession) {
      emit(StudyZonePaused(snapshot: state as StudyZoneInSession));
    } else if (event.state == AppLifecycleState.resumed &&
        state is StudyZonePaused) {
      emit((state as StudyZonePaused).snapshot);
    }
  }

  // ── Handler: _onRewardedAdCompleted ──────────────────────────────────────

  void _onRewardedAdCompleted(
    RewardedAdCompleted event,
    Emitter<StudyZoneState> emit,
  ) {
    if (state is! StudyZoneInSession) return;
    final s = state as StudyZoneInSession;

    switch (event.bonus) {
      case RewardedBonus.doubleXP:
        emit(s.copyWith(hasRewardedAdBonus: true));
      case RewardedBonus.skipLeech:
        if (s.currentCard.source == CardSource.leech &&
            s.cardIndex < _planCards.length) {
          final leech = _planCards[s.cardIndex];
          _planCards = [
            ..._planCards.sublist(0, s.cardIndex),
            ..._planCards.sublist(s.cardIndex + 1),
            leech,
          ];
          add(const NextCardRequested());
        }
      case RewardedBonus.extraWords:
        // Sprint 3'te DailyPlanner extend ile implement edilecek
        break;
    }
  }

  // ── Handler: _onPlanDateChanged ───────────────────────────────────────────

  void _onPlanDateChanged(
    PlanDateChanged event,
    Emitter<StudyZoneState> emit,
  ) {
    emit(const StudyZoneIdle());
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  /// FSRS hesaplama — yeni kart: initNewCard, mevcut: updateCard.
  FSRSState _computeFSRS({
    required PlanCard card,
    required ReviewRating rating,
    required StudyMode mode,
  }) {
    if (card.source == CardState.newCard as dynamic ||
        card.source == CardSource.newCard) {
      return _fsrs.initNewCard(rating, mode: mode.key);
    }
    // Due/leech: mevcut FSRSState gerekir — ProgressDao'dan alınmalı.
    // T-10 scope: Bloc progress state'i cache etmez, SubmitReview sonrası
    // Drift'te güncellenir. Bu path ProgressDao fetch ile genişletilecek (T-11+).
    // Şimdilik initNewCard kullanarak ilk güvenli state üret.
    return _fsrs.initNewCard(rating, mode: mode.key);
  }

  Future<void> _finishSession(
    StudyZoneReviewing reviewing,
    Emitter<StudyZoneState> emit,
  ) async {
    final totalTimeMs = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inMilliseconds
        : 0;

    await _completeSession(CompleteSessionParams(
      sessionId: reviewing.sessionId,
      totalCards: _answerCount,
      correctCards: _correctCards,
      xpEarned: _sessionXP,
    ));

    emit(StudyZoneCompleted(
      totalCards: _answerCount,
      correctCards: _correctCards,
      totalTimeMs: totalTimeMs,
      xpEarned: _sessionXP,
      wrongWordIds: List.unmodifiable(_wrongWordIds),
      sessionId: reviewing.sessionId,
    ));
  }

  StudyMode _selectMode(PlanCard card, {required bool isMiniSession}) {
    return ModeSelector.selectMode(
      modeHistory: _modeHistory,
      cardState: card.source == CardSource.newCard
          ? CardState.newCard
          : CardState.review,
      isMiniSession: isMiniSession,
    );
  }

  void _incrementMode(StudyMode mode) {
    _modeHistory[mode.key] = (_modeHistory[mode.key] ?? 0) + 1;
  }

  void _checkInterstitialAd() {
    if (_answerCount % _interstitialTriggerCount == 0 &&
        _answerCount > 0 &&
        _adService.isInterstitialReady) {
      _adService.showInterstitialIfReady();
    }
  }

  String? _extractSessionId(StudyZoneState s) {
    if (s is StudyZoneInSession) return s.sessionId;
    if (s is StudyZoneReviewing) return s.sessionId;
    return null;
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
