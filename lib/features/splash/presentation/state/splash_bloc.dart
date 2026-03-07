// lib/features/splash/presentation/state/splash_bloc.dart
//
// FAZ 15 — F15-06: İlk indirme progress UI
//
// Değişiklikler:
//   - SplashDownloading state: Firestore indirme ilerlemesi için
//   - _onInitialized: Dil ayarları → WordSyncService.isSynced() → sync
//   - DatasetService.seedWordsIfNeeded() artık sourceLang + targetLang alıyor

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

/// F15-06: Firestore kelime indirme ilerlemesi.
class SplashDownloading extends SplashState {
  final int synced;
  final int total;
  const SplashDownloading({required this.synced, required this.total});
  @override
  List<Object?> get props => [synced, total];

  double get progress => total > 0 ? (synced / total).clamp(0.0, 1.0) : 0.0;
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
    await Future.delayed(const Duration(milliseconds: 1500));

    // 1. İlk açılış kontrolü
    final firstLaunchResult = await _settingsRepo.isFirstLaunch();
    final isFirstLaunch = firstLaunchResult.fold((_) => true, (v) => v);

    if (isFirstLaunch) {
      emit(const SplashNavigateToOnboarding());
      return;
    }

    // 2. Dil ayarlarını al
    final langResult = await _settingsRepo.getLanguageSettings();
    final lang = langResult.fold((_) => <String, String>{}, (v) => v);
    final sourceLang = lang['source'] ?? 'tr';
    final targetLang = lang['target'] ?? 'en';

    // 3. F15-06: Kelime senkronizasyonu (Firestore → Drift)
    final isSeeded = await _datasetService.isSeeded(
      sourceLang: sourceLang,
      targetLang: targetLang,
    );

    if (!isSeeded) {
      // İlk indirme — progress UI göster
      emit(const SplashDownloading(synced: 0, total: 0));
      await _datasetService.seedWordsIfNeeded(
        sourceLang: sourceLang,
        targetLang: targetLang,
        onProgress: (synced, total) {
          emit(SplashDownloading(synced: synced, total: total));
        },
      );
    }

    // 4. Auth kontrolü
    final user = _authService.currentUser;
    if (user != null) {
      emit(const SplashNavigateToMain());
    } else {
      emit(const SplashNavigateToLogin());
    }
  }
}
