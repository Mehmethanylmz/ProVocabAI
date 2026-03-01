// lib/features/study_zone/presentation/state/study_zone_event.dart
//
// FAZ 2 FIX:
//   F2-02: StudyModeManuallyChanged event eklendi — kullanıcı mod seçimi.

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;

import '../../../../srs/fsrs_state.dart';
import '../../../../srs/mode_selector.dart';

// ── Base ─────────────────────────────────────────────────────────────────────

abstract class StudyZoneEvent extends Equatable {
  const StudyZoneEvent();

  @override
  List<Object?> get props => [];
}

// ── 1. LoadPlanRequested ──────────────────────────────────────────────────────

class LoadPlanRequested extends StudyZoneEvent {
  final String targetLang;
  final List<String> categories;
  final int newWordsGoal;
  final int sessionCardLimit;

  const LoadPlanRequested({
    required this.targetLang,
    required this.categories,
    required this.newWordsGoal,
    this.sessionCardLimit = 10,
  });

  @override
  List<Object?> get props =>
      [targetLang, categories, newWordsGoal, sessionCardLimit];
}

// ── 2. SessionStarted ─────────────────────────────────────────────────────────

class SessionStarted extends StudyZoneEvent {
  const SessionStarted();
}

// ── 3. AnswerSubmitted ────────────────────────────────────────────────────────

class AnswerSubmitted extends StudyZoneEvent {
  final ReviewRating rating;
  final int responseMs;

  const AnswerSubmitted({
    required this.rating,
    required this.responseMs,
  });

  @override
  List<Object?> get props => [rating, responseMs];
}

// ── 4. NextCardRequested ──────────────────────────────────────────────────────

class NextCardRequested extends StudyZoneEvent {
  const NextCardRequested();
}

// ── 5. SessionAborted ─────────────────────────────────────────────────────────

class SessionAborted extends StudyZoneEvent {
  const SessionAborted();
}

// ── 6. AppLifecycleChanged ────────────────────────────────────────────────────

class AppLifecycleChanged extends StudyZoneEvent {
  final AppLifecycleState state;

  const AppLifecycleChanged(this.state);

  @override
  List<Object?> get props => [state];
}

// ── 7. RewardedAdCompleted ────────────────────────────────────────────────────

class RewardedAdCompleted extends StudyZoneEvent {
  final RewardedBonus bonus;

  const RewardedAdCompleted(this.bonus);

  @override
  List<Object?> get props => [bonus];
}

// ── 8. PlanDateChanged ────────────────────────────────────────────────────────

class PlanDateChanged extends StudyZoneEvent {
  final String newDate;

  const PlanDateChanged(this.newDate);

  @override
  List<Object?> get props => [newDate];
}

// ── 9. StudyModeManuallyChanged (FAZ 2 — F2-02) ──────────────────────────────
/// UI → Bloc: Kullanıcı mod seçici chip bar'dan mod değiştirdi.
///
/// [mode] null → otomatik mod (ModeSelector karar verir).
/// [mode] StudyMode.mcq / listening / speaking → kullanıcı tercihi.
///
/// Handler: _onModeChanged → _userPreferredMode güncellenir.
/// Sonraki kart geçişlerinde bu tercih kullanılır.
/// Yeni kartlar veya uygun olmayan kartlar → MCQ'ya fallback.
class StudyModeManuallyChanged extends StudyZoneEvent {
  /// null → otomatik mod seçimi (varsayılan davranış)
  final StudyMode? mode;

  const StudyModeManuallyChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

// ── RewardedBonus ─────────────────────────────────────────────────────────────

enum RewardedBonus {
  doubleXP,
  skipLeech,
  extraWords,
}
