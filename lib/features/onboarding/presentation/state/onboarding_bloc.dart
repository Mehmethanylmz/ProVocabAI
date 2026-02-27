// lib/features/onboarding/presentation/state/onboarding_bloc.dart
//
// REPLACES: lib/features/onboarding/presentation/view_model/onboarding_view_model.dart
// Sorumluluk: Dil/seviye/hedef seçimi ve onboarding kayıt akışı

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../settings/domain/repositories/i_settings_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

class OnboardingSourceLangChanged extends OnboardingEvent {
  final String code;
  const OnboardingSourceLangChanged(this.code);
  @override
  List<Object?> get props => [code];
}

class OnboardingTargetLangChanged extends OnboardingEvent {
  final String code;
  const OnboardingTargetLangChanged(this.code);
  @override
  List<Object?> get props => [code];
}

class OnboardingLevelChanged extends OnboardingEvent {
  final String level;
  const OnboardingLevelChanged(this.level);
  @override
  List<Object?> get props => [level];
}

class OnboardingDailyGoalChanged extends OnboardingEvent {
  final int goal;
  const OnboardingDailyGoalChanged(this.goal);
  @override
  List<Object?> get props => [goal];
}

class OnboardingNextPage extends OnboardingEvent {
  const OnboardingNextPage();
}

class OnboardingPreviousPage extends OnboardingEvent {
  const OnboardingPreviousPage();
}

class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();
}

// ── States ────────────────────────────────────────────────────────────────────

class OnboardingState extends Equatable {
  final int currentPage;
  final String sourceLang;
  final String targetLang;
  final String selectedLevel;
  final int selectedDailyGoal;
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  static const totalPages = 4;

  const OnboardingState({
    this.currentPage = 0,
    this.sourceLang = 'tr',
    this.targetLang = 'en',
    this.selectedLevel = 'beginner',
    this.selectedDailyGoal = 10,
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  bool get isLastPage => currentPage == totalPages - 1;

  OnboardingState copyWith({
    int? currentPage,
    String? sourceLang,
    String? targetLang,
    String? selectedLevel,
    int? selectedDailyGoal,
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) =>
      OnboardingState(
        currentPage: currentPage ?? this.currentPage,
        sourceLang: sourceLang ?? this.sourceLang,
        targetLang: targetLang ?? this.targetLang,
        selectedLevel: selectedLevel ?? this.selectedLevel,
        selectedDailyGoal: selectedDailyGoal ?? this.selectedDailyGoal,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  @override
  List<Object?> get props => [
        currentPage,
        sourceLang,
        targetLang,
        selectedLevel,
        selectedDailyGoal,
        isLoading,
        errorMessage,
        isCompleted,
      ];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({required ISettingsRepository settingsRepository})
      : _settingsRepo = settingsRepository,
        super(const OnboardingState()) {
    on<OnboardingSourceLangChanged>(_onSourceLangChanged);
    on<OnboardingTargetLangChanged>(_onTargetLangChanged);
    on<OnboardingLevelChanged>(_onLevelChanged);
    on<OnboardingDailyGoalChanged>(_onDailyGoalChanged);
    on<OnboardingNextPage>(_onNextPage);
    on<OnboardingPreviousPage>(_onPreviousPage);
    on<OnboardingCompleted>(_onCompleted);
  }

  final ISettingsRepository _settingsRepo;

  static const supportedLanguages = ['tr', 'en', 'es', 'de', 'fr', 'pt'];
  static const difficultyLevels = [
    'beginner',
    'elementary',
    'intermediate',
    'upper_intermediate',
    'advanced',
  ];
  static const dailyGoalOptions = [5, 10, 20, 30, 50, 100];

  void _onSourceLangChanged(
      OnboardingSourceLangChanged event, Emitter<OnboardingState> emit) {
    String target = state.targetLang;
    if (target == event.code) {
      target = event.code == 'en' ? 'tr' : 'en';
    }
    emit(state.copyWith(sourceLang: event.code, targetLang: target));
  }

  void _onTargetLangChanged(
      OnboardingTargetLangChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(targetLang: event.code));
  }

  void _onLevelChanged(
      OnboardingLevelChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(selectedLevel: event.level));
  }

  void _onDailyGoalChanged(
      OnboardingDailyGoalChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(selectedDailyGoal: event.goal));
  }

  void _onNextPage(OnboardingNextPage event, Emitter<OnboardingState> emit) {
    if (state.currentPage < OnboardingState.totalPages - 1) {
      emit(state.copyWith(currentPage: state.currentPage + 1));
    }
  }

  void _onPreviousPage(
      OnboardingPreviousPage event, Emitter<OnboardingState> emit) {
    if (state.currentPage > 0) {
      emit(state.copyWith(currentPage: state.currentPage - 1));
    }
  }

  Future<void> _onCompleted(
      OnboardingCompleted event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _settingsRepo.saveLanguageSettings(
          state.sourceLang, state.targetLang);
      await _settingsRepo.saveProficiencyLevel(state.selectedLevel);
      await _settingsRepo.saveDailyGoal(state.selectedDailyGoal);
      await _settingsRepo.completeOnboarding();
      emit(state.copyWith(isLoading: false, isCompleted: true));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Ayarlar kaydedilemedi: ${e.toString()}',
      ));
    }
  }
}
