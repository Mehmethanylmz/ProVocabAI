// lib/features/study_zone/presentation/state/study_zone_state.dart
//
// FAZ 2 FIX:
//   StudyZoneInSession'a userPreferredMode alanı eklendi.
//   UI'da mod seçici chip bar'ın seçili durumunu göstermek için kullanılır.

import 'package:equatable/equatable.dart';

import '../../../../database/app_database.dart' hide DailyPlan;
import '../../../../srs/fsrs_state.dart';
import '../../../../srs/plan_models.dart';
import '../../../../srs/mode_selector.dart';

// ── Base ─────────────────────────────────────────────────────────────────────

abstract class StudyZoneState extends Equatable {
  const StudyZoneState();

  @override
  List<Object?> get props => [];
}

// ── 1. StudyZoneIdle ────────────────────────────────────────────────────────

class StudyZoneIdle extends StudyZoneState {
  final EmptyReason? emptyReason;

  const StudyZoneIdle({this.emptyReason});

  @override
  List<Object?> get props => [emptyReason];
}

// ── 2. StudyZonePlanning ──────────────────────────────────────────────────────

class StudyZonePlanning extends StudyZoneState {
  const StudyZonePlanning();
}

// ── 3. StudyZoneReady ─────────────────────────────────────────────────────────

class StudyZoneReady extends StudyZoneState {
  final DailyPlan plan;

  const StudyZoneReady({required this.plan});

  @override
  List<Object?> get props => [plan];
}

// ── 4. StudyZoneInSession ─────────────────────────────────────────────────────

class StudyZoneInSession extends StudyZoneState {
  final PlanCard currentCard;
  final String sessionId;
  final int sessionStreak;
  final int sessionCardCount;
  final bool hasRewardedAdBonus;
  final StudyMode currentMode;
  final DateTime timerStart;
  final int cardIndex;
  final int totalCards;
  final int completedCount;
  final String targetLang;
  final String? currentWordText;
  final String? currentWordMeaning;
  final Word? currentWord;
  final List<Word> decoys;

  /// F2-03: Kullanıcının seçtiği tercih edilen mod.
  /// null → otomatik mod (ModeSelector karar verir)
  /// UI'da chip bar'ın seçili durumunu göstermek için kullanılır.
  final StudyMode? userPreferredMode;

  const StudyZoneInSession({
    required this.currentCard,
    required this.sessionId,
    required this.sessionStreak,
    required this.sessionCardCount,
    required this.hasRewardedAdBonus,
    required this.currentMode,
    required this.timerStart,
    required this.cardIndex,
    required this.totalCards,
    this.completedCount = 0,
    this.targetLang = 'en',
    this.currentWordText,
    this.currentWordMeaning,
    this.currentWord,
    this.decoys = const [],
    this.userPreferredMode,
  });

  @override
  List<Object?> get props => [
        currentCard,
        sessionId,
        sessionStreak,
        sessionCardCount,
        hasRewardedAdBonus,
        currentMode,
        timerStart,
        cardIndex,
        totalCards,
        completedCount,
        targetLang,
        currentWordText,
        currentWordMeaning,
        currentWord,
        decoys,
        userPreferredMode,
      ];

  StudyZoneInSession copyWith({
    PlanCard? currentCard,
    String? sessionId,
    int? sessionStreak,
    int? sessionCardCount,
    int? completedCount,
    String? targetLang,
    String? currentWordText,
    String? currentWordMeaning,
    bool? hasRewardedAdBonus,
    StudyMode? currentMode,
    DateTime? timerStart,
    int? cardIndex,
    int? totalCards,
    Word? currentWord,
    List<Word>? decoys,
    StudyMode? userPreferredMode,
  }) =>
      StudyZoneInSession(
        currentCard: currentCard ?? this.currentCard,
        sessionId: sessionId ?? this.sessionId,
        sessionStreak: sessionStreak ?? this.sessionStreak,
        sessionCardCount: sessionCardCount ?? this.sessionCardCount,
        hasRewardedAdBonus: hasRewardedAdBonus ?? this.hasRewardedAdBonus,
        currentMode: currentMode ?? this.currentMode,
        timerStart: timerStart ?? this.timerStart,
        cardIndex: cardIndex ?? this.cardIndex,
        totalCards: totalCards ?? this.totalCards,
        completedCount: completedCount ?? this.completedCount,
        targetLang: targetLang ?? this.targetLang,
        currentWordText: currentWordText ?? this.currentWordText,
        currentWordMeaning: currentWordMeaning ?? this.currentWordMeaning,
        currentWord: currentWord ?? this.currentWord,
        decoys: decoys ?? this.decoys,
        userPreferredMode: userPreferredMode ?? this.userPreferredMode,
      );
}

// ── 5. StudyZoneReviewing ─────────────────────────────────────────────────────

class StudyZoneReviewing extends StudyZoneState {
  final PlanCard currentCard;
  final String sessionId;
  final int sessionStreak;
  final int sessionCardCount;
  final bool hasRewardedAdBonus;
  final StudyMode currentMode;
  final int cardIndex;
  final int totalCards;

  final ReviewRating lastRating;
  final FSRSState updatedFSRS;
  final int xpJustEarned;

  const StudyZoneReviewing({
    required this.currentCard,
    required this.sessionId,
    required this.sessionStreak,
    required this.sessionCardCount,
    required this.hasRewardedAdBonus,
    required this.currentMode,
    required this.cardIndex,
    required this.totalCards,
    required this.lastRating,
    required this.updatedFSRS,
    required this.xpJustEarned,
  });

  @override
  List<Object?> get props => [
        currentCard,
        sessionId,
        sessionStreak,
        sessionCardCount,
        hasRewardedAdBonus,
        currentMode,
        cardIndex,
        totalCards,
        lastRating,
        updatedFSRS,
        xpJustEarned,
      ];

  StudyZoneInSession toInSession({
    required PlanCard nextCard,
    required int nextCardIndex,
    required StudyMode nextMode,
    required int newStreak,
    required DateTime timerStart,
    Word? nextWord,
    List<Word> nextDecoys = const [],
    String targetLang = 'en',
  }) =>
      StudyZoneInSession(
        currentCard: nextCard,
        sessionId: sessionId,
        sessionStreak: newStreak,
        sessionCardCount: sessionCardCount + 1,
        hasRewardedAdBonus: false,
        currentMode: nextMode,
        timerStart: timerStart,
        cardIndex: nextCardIndex,
        totalCards: totalCards,
        targetLang: targetLang,
        currentWord: nextWord,
        decoys: nextDecoys,
      );
}

// ── 6. StudyZonePaused ────────────────────────────────────────────────────────

class StudyZonePaused extends StudyZoneState {
  final StudyZoneInSession snapshot;

  const StudyZonePaused({required this.snapshot});

  @override
  List<Object?> get props => [snapshot];
}

// ── 7. StudyZoneCompleted ─────────────────────────────────────────────────────

class StudyZoneCompleted extends StudyZoneState {
  final int totalCards;
  final int correctCards;
  final int totalTimeMs;
  final int xpEarned;
  final List<int> wrongWordIds;
  final String sessionId;

  const StudyZoneCompleted({
    required this.totalCards,
    required this.correctCards,
    required this.totalTimeMs,
    required this.xpEarned,
    required this.wrongWordIds,
    required this.sessionId,
  });

  double get accuracy => totalCards == 0 ? 0.0 : correctCards / totalCards;

  @override
  List<Object?> get props => [
        totalCards,
        correctCards,
        totalTimeMs,
        xpEarned,
        wrongWordIds,
        sessionId,
      ];
}

// ── 8. StudyZoneError ─────────────────────────────────────────────────────────

class StudyZoneError extends StudyZoneState {
  final String message;

  const StudyZoneError({required this.message});

  @override
  List<Object?> get props => [message];
}
