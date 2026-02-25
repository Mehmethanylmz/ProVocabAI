// lib/core/di/injection_container.dart
//
// T-14: DI Container Tam Kurulum
// Blueprint: get_it singletons + factories
// REPLACES: lib/core/init/injection_container.dart (legacy Provider DI)
//
// Silme:
//   git rm lib/core/init/injection_container.dart
//
// Kullanım:
//   await configureDependencies();   // main.dart'ta
//   getIt<StudyZoneBloc>()           // herhangi yerden

import 'package:get_it/get_it.dart';

// ── Database ──────────────────────────────────────────────────────────────────
import 'package:pratikapp/database/app_database.dart';

// ── SRS ───────────────────────────────────────────────────────────────────────
import 'package:pratikapp/srs/daily_planner.dart';
import 'package:pratikapp/srs/fsrs_engine.dart';

// ── Use Cases ─────────────────────────────────────────────────────────────────
import 'package:pratikapp/features/study_zone/domain/usecases/start_session.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/submit_review.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/complete_session.dart';

// ── BLoC ──────────────────────────────────────────────────────────────────────
import 'package:pratikapp/features/study_zone/presentation/state/study_zone_bloc.dart';

import '../../database/daos/progress_dao.dart';
import '../../database/daos/session_dao.dart';
import '../../database/daos/sync_queue_dao.dart';
import '../../database/daos/word_dao.dart';
import '../../firebase/messaging/fcm_service.dart';

final GetIt getIt = GetIt.instance;

/// Ana DI kurulum fonksiyonu — main.dart içinde WidgetsFlutterInitialized
/// sonrasında çağrılmalı.
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp(...);
///   await configureDependencies();
///   runApp(const App());
/// }
/// ```
Future<void> configureDependencies() async {
  // ── Singletons ─────────────────────────────────────────────────────────────

  // AppDatabase — tek instance, tüm DAO'lar buradan
  getIt.registerSingleton<AppDatabase>(AppDatabase());

  // DAO'lar — AppDatabase'e bağlı
  getIt.registerSingleton<WordDao>(getIt<AppDatabase>().wordDao);
  getIt.registerSingleton<ProgressDao>(getIt<AppDatabase>().progressDao);
  getIt.registerSingleton<SyncQueueDao>(getIt<AppDatabase>().syncQueueDao);
  getIt.registerSingleton<SessionDao>(getIt<AppDatabase>().sessionDao);
  //getIt.registerSingleton<LeaderboardDao>(getIt<AppDatabase>().leaderboardDao);

  // FSRSEngine — stateless, singleton yeterli
  getIt.registerSingleton<FSRSEngine>(FSRSEngine());

  // DailyPlanner — DAO'lara bağlı singleton
  getIt.registerSingleton<DailyPlanner>(
    DailyPlanner(
      progressDao: getIt<ProgressDao>(),
      wordDao: getIt<WordDao>(),
    ),
  );

  // ── Use Cases (Singleton — stateless) ──────────────────────────────────────

  getIt.registerSingleton<StartSession>(
    StartSession(getIt<AppDatabase>()),
  );
  getIt.registerSingletonAsync<FCMService>(() async {
    final service = FCMService();
    await service.initialize();
    return service;
  });

  getIt.registerSingleton<SubmitReview>(
    SubmitReview(getIt<AppDatabase>()),
  );

  getIt.registerSingleton<CompleteSession>(
    CompleteSession(getIt<AppDatabase>()),
  );

  // ── Factories (her talep yeni instance) ────────────────────────────────────

  // StudyZoneBloc — Factory: her route push'ta yeni BLoC
  getIt.registerFactory<StudyZoneBloc>(
    () => StudyZoneBloc(
      dailyPlanner: getIt<DailyPlanner>(),
      startSession: getIt<StartSession>(),
      submitReview: getIt<SubmitReview>(),
      completeSession: getIt<CompleteSession>(),
    ),
  );
}

/// Test ortamında DI'yi sıfırla
Future<void> resetDependencies() async {
  await getIt.reset();
}
