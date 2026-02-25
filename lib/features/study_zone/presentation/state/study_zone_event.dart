// lib/features/study_zone/presentation/state/study_zone_event.dart
//
// Blueprint T-09: StudyZone BLoC Events (8 sınıf).
// Bağımlılıklar: equatable, fsrs_state.dart (T-03), plan_models.dart (T-04).

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;

import '../../../../srs/fsrs_state.dart';

// ── Base ─────────────────────────────────────────────────────────────────────

abstract class StudyZoneEvent extends Equatable {
  const StudyZoneEvent();

  @override
  List<Object?> get props => [];
}

// ── 1. LoadPlanRequested ──────────────────────────────────────────────────────
/// UI → Bloc: Günlük plan yükle.
/// Handler: _onLoadPlan → Planning → Ready | Idle(empty) | Error
class LoadPlanRequested extends StudyZoneEvent {
  final String targetLang;
  final List<String> categories;
  final int newWordsGoal;

  const LoadPlanRequested({
    required this.targetLang,
    required this.categories,
    required this.newWordsGoal,
  });

  @override
  List<Object?> get props => [targetLang, categories, newWordsGoal];
}

// ── 2. SessionStarted ─────────────────────────────────────────────────────────
/// UI → Bloc: Kullanıcı "Başla" butonuna bastı.
/// Handler: _onSessionStarted → InSession
class SessionStarted extends StudyZoneEvent {
  const SessionStarted();
}

// ── 3. AnswerSubmitted ────────────────────────────────────────────────────────
/// UI → Bloc: Kullanıcı 4-lü rating seçti (Again/Hard/Good/Easy).
/// Handler: _onAnswerSubmitted → Reviewing
class AnswerSubmitted extends StudyZoneEvent {
  final ReviewRating rating;

  /// Kartın gösterilmesinden cevaba kadar geçen süre (ms).
  /// XP ve analytics için kullanılır.
  final int responseMs;

  const AnswerSubmitted({
    required this.rating,
    required this.responseMs,
  });

  @override
  List<Object?> get props => [rating, responseMs];
}

// ── 4. NextCardRequested ──────────────────────────────────────────────────────
/// UI → Bloc: Kullanıcı "Devam" butonuna bastı (Reviewing → InSession).
/// Handler: _onNextCard → InSession | Completed
class NextCardRequested extends StudyZoneEvent {
  const NextCardRequested();
}

// ── 5. SessionAborted ─────────────────────────────────────────────────────────
/// UI → Bloc: Kullanıcı session'ı yarıda bıraktı.
/// Handler: _onSessionAborted → Idle
class SessionAborted extends StudyZoneEvent {
  const SessionAborted();
}

// ── 6. AppLifecycleChanged ────────────────────────────────────────────────────
/// System → Bloc: Uygulama arka plana/öne geçti.
/// Handler: _onLifecycleChange → Paused | InSession (restored)
class AppLifecycleChanged extends StudyZoneEvent {
  final AppLifecycleState state;

  const AppLifecycleChanged(this.state);

  @override
  List<Object?> get props => [state];
}

// ── 7. RewardedAdCompleted ────────────────────────────────────────────────────
/// AdService → Bloc: Rewarded ad izlendi, ödül uygula.
/// Handler: _onRewardedAdCompleted
class RewardedAdCompleted extends StudyZoneEvent {
  final RewardedBonus bonus;

  const RewardedAdCompleted(this.bonus);

  @override
  List<Object?> get props => [bonus];
}

// ── 8. PlanDateChanged ────────────────────────────────────────────────────────
/// System → Bloc: Gece yarısı gün değişti → plan sıfırla.
/// Handler: _onPlanDateChanged → Idle
class PlanDateChanged extends StudyZoneEvent {
  final String newDate; // 'YYYY-MM-DD'

  const PlanDateChanged(this.newDate);

  @override
  List<Object?> get props => [newDate];
}

// ── RewardedBonus ─────────────────────────────────────────────────────────────
/// Blueprint G.4: Rewarded ad ödül tipleri.
enum RewardedBonus {
  /// XP 2x (mevcut review için).
  doubleXP,

  /// Leech kartı planın sonuna at, şimdi skip et.
  skipLeech,

  /// +5 yeni kart plan'a ekle.
  extraWords,
}
