// lib/features/study_zone/presentation/state/study_zone_bloc.dart
//
// FAZ 2 FIX:
//   F2-03: _userPreferredMode alanı + StudyModeManuallyChanged handler
//          selectModeWithValidation() kullanımı — kart uygunluğuna göre fallback

import 'dart:convert';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../database/app_database.dart';
import '../../../../database/daos/progress_dao.dart';
import '../../../../database/daos/word_dao.dart';
import '../../../../srs/daily_planner.dart';
import '../../../../srs/fsrs_engine.dart';
import '../../../../srs/fsrs_state.dart';
import '../../../../srs/mode_selector.dart';
import '../../../../srs/plan_models.dart';
import '../../../../ads/ad_service.dart';
import '../../../../srs/xp_calculator.dart';
import '../../domain/usecases/complete_session.dart';
import '../../domain/usecases/start_session.dart';
import '../../domain/usecases/submit_review.dart';
import 'study_zone_event.dart';
import 'study_zone_state.dart';

// ── StudyZoneBloc ─────────────────────────────────────────────────────────────

class StudyZoneBloc extends Bloc<StudyZoneEvent, StudyZoneState> {
  final DailyPlanner _dailyPlanner;
  final StartSession _startSession;
  final SubmitReview _submitReview;
  final CompleteSession _completeSession;
  final FSRSEngine _fsrs;
  final AdService? _adService;
  final WordDao _wordDao;
  final ProgressDao _progressDao;

  static const int _interstitialTriggerCount = 15;

  // ── Session-scoped mutable state ──────────────────────────────────────────

  final Map<String, int> _modeHistory = {};
  List<PlanCard> _planCards = [];
  DateTime? _sessionStartTime;
  int _sessionXP = 0;
  final List<int> _wrongWordIds = [];
  int _correctCards = 0;
  int _answerCount = 0;

  String _targetLang = 'en';
  int _sessionCardLimit = 10;

  /// F2-03: Kullanıcının seçtiği tercih edilen mod.
  /// null → otomatik (ModeSelector.selectMode kendi karar verir)
  /// StudyMode.xxx → kullanıcı tercihi (uygun değilse MCQ'ya fallback)
  StudyMode? _userPreferredMode;

  StudyZoneBloc({
    required DailyPlanner dailyPlanner,
    required StartSession startSession,
    required SubmitReview submitReview,
    required CompleteSession completeSession,
    required WordDao wordDao,
    required ProgressDao progressDao,
    FSRSEngine fsrs = const FSRSEngine(),
    AdService? adService,
  })  : _dailyPlanner = dailyPlanner,
        _startSession = startSession,
        _submitReview = submitReview,
        _completeSession = completeSession,
        _fsrs = fsrs,
        _adService = adService,
        _wordDao = wordDao,
        _progressDao = progressDao,
        super(const StudyZoneIdle()) {
    on<LoadPlanRequested>(_onLoadPlan);
    on<SessionStarted>(_onSessionStarted);
    on<AnswerSubmitted>(_onAnswerSubmitted);
    on<NextCardRequested>(_onNextCard);
    on<SessionAborted>(_onSessionAborted);
    on<AppLifecycleChanged>(_onLifecycleChange);
    on<RewardedAdCompleted>(_onRewardedAdCompleted);
    on<PlanDateChanged>(_onPlanDateChanged);
    on<StudyModeManuallyChanged>(_onModeChanged); // F2-03
  }

  /// F2-03: Dışarıdan kullanıcının tercih ettiği modu okuma (UI chip bar için).
  StudyMode? get userPreferredMode => _userPreferredMode;

  // ── Handler: _onLoadPlan ──────────────────────────────────────────────────

  Future<void> _onLoadPlan(
    LoadPlanRequested event,
    Emitter<StudyZoneState> emit,
  ) async {
    _targetLang = event.targetLang;
    _sessionCardLimit = event.sessionCardLimit;
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

  Future<void> _onSessionStarted(
    SessionStarted event,
    Emitter<StudyZoneState> emit,
  ) async {
    final ready = state;
    if (ready is! StudyZoneReady) return;

    _planCards = List.of(ready.plan.cards).take(_sessionCardLimit).toList();
    _modeHistory.clear();
    _sessionXP = 0;
    _wrongWordIds.clear();
    _correctCards = 0;
    _answerCount = 0;
    _sessionStartTime = DateTime.now();

    final firstCard = _planCards.first;

    // F2-03: Kullanıcı tercihi + kart uygunluğu birlikte kontrol
    final mode = await _selectModeValidated(firstCard, isMiniSession: false);

    final word = await _wordDao.getWordById(firstCard.wordId);
    if (word == null) {
      emit(StudyZoneError(message: 'Kelime bulunamadı: ${firstCard.wordId}'));
      return;
    }

    final decoys = await _buildDecoys(word);

    final sessionId = await _startSession(
      targetLang: ready.plan.targetLang,
      categories: [],
      mode: mode,
    );
    _incrementMode(mode);

    final wordText = _parseWordText(word, ready.plan.targetLang);
    final wordMeaning = _parseWordMeaning(word, ready.plan.targetLang);

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
      targetLang: ready.plan.targetLang,
      currentWord: word,
      decoys: decoys,
      currentWordText: wordText,
      currentWordMeaning: wordMeaning,
    ));
  }

  // ── Handler: _onAnswerSubmitted ───────────────────────────────────────────

  Future<void> _onAnswerSubmitted(
    AnswerSubmitted event,
    Emitter<StudyZoneState> emit,
  ) async {
    final inSession = state;
    if (inSession is! StudyZoneInSession) return;

    final card = inSession.currentCard;
    final rating = event.rating;

    final existingProgress = await _progressDao.getCardProgress(
      wordId: card.wordId,
      targetLang: _targetLang,
    );
    final updatedFSRS = _computeFSRS(
      card: card,
      rating: rating,
      mode: inSession.currentMode,
      existingProgress: existingProgress,
    );

    final xp = XPCalculator.calculateReviewXP(
      mode: inSession.currentMode,
      rating: rating,
      isNew: card.source == CardSource.newCard,
      streak: inSession.sessionStreak,
      hasBonus: inSession.hasRewardedAdBonus,
    );

    final newStreak =
        rating != ReviewRating.again ? inSession.sessionStreak + 1 : 0;

    final stabilityBefore = existingProgress?.stability ?? 0.5;
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

    _sessionXP += xp;
    _answerCount++;
    if (rating == ReviewRating.again) {
      _wrongWordIds.add(card.wordId);
    } else {
      _correctCards++;
    }

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

    // F2-03: Kart başına mod validasyonu
    final nextMode = await _selectModeValidated(nextCard, isMiniSession: false);
    _incrementMode(nextMode);

    final nextWord = await _wordDao.getWordById(nextCard.wordId);
    if (nextWord == null) {
      emit(StudyZoneError(message: 'Kelime bulunamadı: ${nextCard.wordId}'));
      return;
    }
    final nextDecoys = await _buildDecoys(nextWord);
    final wordText = _parseWordText(nextWord, _targetLang);
    final wordMeaning = _parseWordMeaning(nextWord, _targetLang);

    emit(reviewing
        .toInSession(
          nextCard: nextCard,
          nextCardIndex: nextIndex,
          nextMode: nextMode,
          newStreak: reviewing.sessionStreak,
          timerStart: DateTime.now(),
          nextWord: nextWord,
          nextDecoys: nextDecoys,
          targetLang: _targetLang,
        )
        .copyWith(
          currentWordText: wordText,
          currentWordMeaning: wordMeaning,
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

  // ── Handler: _onModeChanged (F2-03) ───────────────────────────────────────

  /// Kullanıcı mod seçici chip bar'dan mod değiştirdi.
  ///
  /// Session dışında: _userPreferredMode güncellenir, sonraki session'da kullanılır.
  /// Session içinde: Mevcut kart değişmez ama sonraki karttan itibaren
  ///                 yeni tercih uygulanır. InSession state'inde
  ///                 userPreferredMode güncellenir (UI chip'in seçili göstermesi için).
  void _onModeChanged(
    StudyModeManuallyChanged event,
    Emitter<StudyZoneState> emit,
  ) {
    _userPreferredMode = event.mode;

    // Session içindeyse state'i güncelle (sonraki kart tercihli mod kullanacak)
    if (state is StudyZoneInSession) {
      final s = state as StudyZoneInSession;
      emit(s.copyWith(userPreferredMode: event.mode));
    }
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  FSRSState _computeFSRS({
    required PlanCard card,
    required ReviewRating rating,
    required StudyMode mode,
    ProgressData? existingProgress,
  }) {
    if (existingProgress == null || card.source == CardSource.newCard) {
      return _fsrs.initNewCard(rating, mode: mode.key);
    }
    final currentState = FSRSState.fromProgressData(
      stability: existingProgress.stability,
      difficulty: existingProgress.difficulty,
      cardStateStr: existingProgress.cardState,
      nextReviewMs: existingProgress.nextReviewMs,
      lastReviewMs: existingProgress.lastReviewMs,
      repetitions: existingProgress.repetitions,
      lapses: existingProgress.lapses,
    );
    return _fsrs.updateCard(currentState, rating, mode: mode.key);
  }

  Future<List<Word>> _buildDecoys(Word correct) async {
    final candidates = await _wordDao.getRandomCandidates(limit: 50);
    final filtered = candidates.where((w) => w.id != correct.id).toList();
    filtered.shuffle();
    return filtered.take(3).toList();
  }

  String _parseWordText(Word word, String targetLang) {
    try {
      final Map<String, dynamic> content = jsonDecode(word.contentJson);
      final langData = content[targetLang] as Map<String, dynamic>?;
      return (langData?['word'] as String?) ??
          (langData?['term'] as String?) ??
          '';
    } catch (_) {
      return '';
    }
  }

  String _parseWordMeaning(Word word, String targetLang) {
    try {
      final Map<String, dynamic> content = jsonDecode(word.contentJson);
      final langData = content[targetLang] as Map<String, dynamic>?;
      return (langData?['meaning'] as String?) ?? '';
    } catch (_) {
      return '';
    }
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

  /// F2-03: Kart için mod seç — kullanıcı tercihi + kart uygunluğu validasyonu.
  ///
  /// 1. Kullanıcı tercihi var mı? → ModeSelector'a userPreferredMode olarak geçir
  /// 2. Kart advanced mode'a uygun mu? → canUseAdvancedMode kontrol et
  /// 3. Uygun değilse → MCQ'ya fallback
  Future<StudyMode> _selectModeValidated(
    PlanCard card, {
    required bool isMiniSession,
  }) async {
    final isNewCard = card.source == CardSource.newCard;

    // Progress bilgisini al (kart durumu kontrolü için)
    String? progressCardState;
    int repetitions = 0;

    if (!isNewCard) {
      final progress = await _progressDao.getCardProgress(
        wordId: card.wordId,
        targetLang: _targetLang,
      );
      if (progress != null) {
        progressCardState = progress.cardState;
        repetitions = progress.repetitions;
      }
    }

    return ModeSelector.selectModeWithValidation(
      modeHistory: _modeHistory,
      cardState: isNewCard ? CardState.newCard : CardState.review,
      isMiniSession: isMiniSession,
      userPreferredMode: _userPreferredMode,
      isNewCard: isNewCard,
      progressCardState: progressCardState,
      repetitions: repetitions,
    );
  }

  void _incrementMode(StudyMode mode) {
    _modeHistory[mode.key] = (_modeHistory[mode.key] ?? 0) + 1;
  }

  void _checkInterstitialAd() {
    if (_answerCount % _interstitialTriggerCount == 0 &&
        _answerCount > 0 &&
        (_adService?.isInterstitialReady() ?? false)) {
      _adService?.showInterstitialIfReady();
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
