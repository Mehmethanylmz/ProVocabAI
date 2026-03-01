// lib/core/di/injection_container.dart
//
// FAZ 3 FIX:
//   F3-01: FirebaseAuthService → AppDatabase injected (signOut Drift temizleme)
//   F3-04: AuthBloc → SyncManager injected (sign-in sonrası syncAll)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pratikapp/ads/ad_service.dart';
import 'package:pratikapp/core/services/dataset_service.dart';
import 'package:pratikapp/core/services/speech_service.dart';
import 'package:pratikapp/core/services/tts_service.dart';
import 'package:pratikapp/database/app_database.dart';
import 'package:pratikapp/database/daos/progress_dao.dart';
import 'package:pratikapp/database/daos/session_dao.dart';
import 'package:pratikapp/database/daos/sync_queue_dao.dart';
import 'package:pratikapp/database/daos/word_dao.dart';
import 'package:pratikapp/features/auth/presentation/state/auth_bloc.dart';
import 'package:pratikapp/features/dashboard/presentation/state/dashboard_bloc.dart';
import 'package:pratikapp/features/onboarding/presentation/state/onboarding_bloc.dart';
import 'package:pratikapp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:pratikapp/features/settings/domain/repositories/i_settings_repository.dart';
import 'package:pratikapp/features/settings/presentation/state/settings_bloc.dart';
import 'package:pratikapp/features/splash/presentation/state/splash_bloc.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/complete_session.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/start_session.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/submit_review.dart';
import 'package:pratikapp/features/study_zone/presentation/state/study_zone_bloc.dart';
import 'package:pratikapp/firebase/auth/firebase_auth_service.dart';
import 'package:pratikapp/firebase/firestore/leaderboard_service.dart';
import 'package:pratikapp/firebase/messaging/fcm_service.dart';
import 'package:pratikapp/firebase/sync/sync_manager.dart';
import 'package:pratikapp/srs/daily_planner.dart';
import 'package:pratikapp/srs/fsrs_engine.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ── Temel servisler ───────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // ── Veritabanı ────────────────────────────────────────────────────────────
  getIt.registerSingleton<AppDatabase>(AppDatabase());
  getIt.registerSingleton<WordDao>(getIt<AppDatabase>().wordDao);
  getIt.registerSingleton<ProgressDao>(getIt<AppDatabase>().progressDao);
  getIt.registerSingleton<SyncQueueDao>(getIt<AppDatabase>().syncQueueDao);
  getIt.registerSingleton<SessionDao>(getIt<AppDatabase>().sessionDao);

  // ── Settings ──────────────────────────────────────────────────────────────
  getIt.registerSingleton<SettingsRepositoryImpl>(
    SettingsRepositoryImpl(getIt<SharedPreferences>()),
  );
  getIt.registerSingleton<ISettingsRepository>(getIt<SettingsRepositoryImpl>());

  // ── Auth (F3-01: AppDatabase injected) ─────────────────────────────────────
  getIt.registerSingleton<FirebaseAuthService>(
    FirebaseAuthService(database: getIt<AppDatabase>()),
  );

  // ── Dataset seeding ───────────────────────────────────────────────────────
  getIt.registerSingleton<DatasetService>(
    DatasetService(
      wordDao: getIt<WordDao>(),
      prefsOverride: getIt<SharedPreferences>(),
    ),
  );

  // ── SRS ───────────────────────────────────────────────────────────────────
  getIt.registerSingleton<FSRSEngine>(FSRSEngine());
  getIt.registerSingleton<DailyPlanner>(
    DailyPlanner(
      progressDao: getIt<ProgressDao>(),
      wordDao: getIt<WordDao>(),
    ),
  );

  // ── Firebase: LeaderboardService (moved before use cases — CompleteSession depends on it) ──
  getIt.registerSingleton<LeaderboardService>(LeaderboardService());

  // ── Use cases ─────────────────────────────────────────────────────────────
  getIt.registerSingleton<StartSession>(StartSession(getIt<AppDatabase>()));
  getIt.registerSingleton<SubmitReview>(SubmitReview(getIt<AppDatabase>()));
  getIt.registerSingleton<CompleteSession>(
      CompleteSession(getIt<AppDatabase>(), getIt<LeaderboardService>()));

  // ── Firebase: SyncManager ─────────────────────────────────────────────────
  getIt.registerSingleton<SyncManager>(
    SyncManager(
      db: getIt<AppDatabase>(),
      firestore: FirebaseFirestore.instance,
      connectivity: Connectivity(),
    ),
  );

  // ── TTS + STT ─────────────────────────────────────────────────────────────
  getIt.registerSingleton<TtsService>(TtsService());
  getIt.registerSingleton<SpeechService>(SpeechService());

  // ── AdMob: AdService ──────────────────────────────────────────────────────
  final adService = AdService();
  adService.preload();
  getIt.registerSingleton<AdService>(adService);

  // ── FCM — async singleton ─────────────────────────────────────────────────
  getIt.registerSingletonAsync<FCMService>(() async {
    final service = FCMService();
    await service.initialize();
    return service;
  });

  // ── BLoC factory'leri ─────────────────────────────────────────────────────

  getIt.registerFactory<StudyZoneBloc>(
    () => StudyZoneBloc(
      dailyPlanner: getIt<DailyPlanner>(),
      startSession: getIt<StartSession>(),
      submitReview: getIt<SubmitReview>(),
      completeSession: getIt<CompleteSession>(),
      wordDao: getIt<WordDao>(),
      progressDao: getIt<ProgressDao>(),
      adService: getIt<AdService>(),
    ),
  );

  // F3-04: AuthBloc → SyncManager injected
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      authService: getIt<FirebaseAuthService>(),
      syncManager: getIt<SyncManager>(),
    ),
  );

  getIt.registerFactory<SplashBloc>(
    () => SplashBloc(
      settingsRepository: getIt<ISettingsRepository>(),
      authService: getIt<FirebaseAuthService>(),
      datasetService: getIt<DatasetService>(),
    ),
  );

  getIt.registerFactory<OnboardingBloc>(
    () => OnboardingBloc(settingsRepository: getIt<ISettingsRepository>()),
  );

  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      sessionDao: getIt<SessionDao>(),
      wordDao: getIt<WordDao>(),
      progressDao: getIt<ProgressDao>(),
    ),
  );

  getIt.registerFactory<SettingsBloc>(
    () => SettingsBloc(settingsRepository: getIt<ISettingsRepository>()),
  );
}

Future<void> resetDependencies() async {
  await getIt.reset();
}
