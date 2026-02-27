// lib/features/splash/presentation/state/splash_bloc.dart
//
// REPLACES: lib/features/splash/presentation/viewmodel/splash_view_model.dart
// git rm lib/features/splash/presentation/viewmodel/splash_view_model.dart
//
// Sorumluluk: Uygulama başlangıç akışını yönet.
//   1. İlk açılış → ONBOARDING
//   2. Kelime DB boşsa → seed (DatasetService zaten bunu yapıyor, main'de çağrılıyor)
//   3. Auth kontrol → LOGIN veya MAIN

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/dataset_service.dart';
import '../../../../firebase/auth/firebase_auth_service.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class SplashEvent extends Equatable {
  const SplashEvent();
  @override
  List<Object?> get props => [];
}

class SplashInitialized extends SplashEvent {
  final Locale currentLocale;
  const SplashInitialized({required this.currentLocale});
  @override
  List<Object?> get props => [currentLocale];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class SplashState extends Equatable {
  const SplashState();
  @override
  List<Object?> get props => [];
}

class SplashLoading extends SplashState {
  final bool seedingDatabase;
  const SplashLoading({this.seedingDatabase = false});
  @override
  List<Object?> get props => [seedingDatabase];
}

class SplashNavigateToOnboarding extends SplashState {
  const SplashNavigateToOnboarding();
}

class SplashNavigateToLogin extends SplashState {
  const SplashNavigateToLogin();
}

class SplashNavigateToMain extends SplashState {
  const SplashNavigateToMain();
}

class SplashError extends SplashState {
  final String message;
  const SplashError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({
    required ISettingsRepository settingsRepository,
    required FirebaseAuthService authService,
    required DatasetService datasetService,
  })  : _settingsRepo = settingsRepository,
        _authService = authService,
        _datasetService = datasetService,
        super(const SplashLoading()) {
    on<SplashInitialized>(_onInitialized);
  }

  final ISettingsRepository _settingsRepo;
  final FirebaseAuthService _authService;
  final DatasetService _datasetService;

  Future<void> _onInitialized(
    SplashInitialized event,
    Emitter<SplashState> emit,
  ) async {
    await Future.delayed(const Duration(milliseconds: 1800));

    // 1. İlk açılış kontrolü
    final firstLaunchResult = await _settingsRepo.isFirstLaunch();
    final isFirstLaunch = firstLaunchResult.fold((_) => true, (v) => v);

    if (isFirstLaunch) {
      emit(const SplashNavigateToOnboarding());
      return;
    }

    // 2. Kelime seed (DatasetService idempotent — zaten main'de çağrılıyor,
    //    burada sadece yavaş cihazlar için fallback)
    emit(const SplashLoading(seedingDatabase: true));
    await _datasetService.seedWordsIfNeeded();

    // 3. Auth kontrolü
    final user = _authService.currentUser;
    if (user != null) {
      emit(const SplashNavigateToMain());
    } else {
      emit(const SplashNavigateToLogin());
    }
  }
}
