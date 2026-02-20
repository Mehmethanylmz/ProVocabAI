import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- CORE SERVICES ---
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';

// --- DATABASE ---
import '../../../product/init/database/ProductDatabaseManager.dart';

// --- DASHBOARD FEATURE ---
import '../../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../../features/dashboard/domain/repositories/i_dashboard_repository.dart';
import '../../../features/dashboard/presentation/view_model/dashboard_view_model.dart';

// --- SETTINGS FEATURE ---
import '../../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../../features/settings/domain/repositories/i_settings_repository.dart';
import '../../../features/settings/presentation/viewmodel/settings_view_model.dart';

// --- SPLASH FEATURE ---
import '../../../features/splash/presentation/viewmodel/splash_view_model.dart';

// --- STUDY ZONE FEATURE ---
import '../../../features/study_zone/data/repositories/test_repository_impl.dart';
import '../../../features/study_zone/data/repositories/word_repository_impl.dart';
import '../../../features/study_zone/domain/repositories/i_test_repository.dart';
import '../../../features/study_zone/domain/repositories/i_word_repository.dart';
import '../../../features/study_zone/presentation/view_model/menu_view_model.dart';
import '../../../features/study_zone/presentation/view_model/study_view_model.dart';

// --- OTHER FEATURES ---
import '../../../features/main/presentation/view_model/main_view_model.dart';
import '../../../features/onboarding/presentation/view_model/onboarding_view_model.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  // --- EXTERNAL SERVICES ---
  final sharedPreferences = await SharedPreferences.getInstance();
  locator.registerLazySingleton(() => sharedPreferences);
  locator.registerLazySingleton(() => TtsService());
  locator.registerLazySingleton(() => SpeechService());

  // Database Manager
  locator.registerLazySingleton(() => ProductDatabaseManager.instance);

  // --- REPOSITORIES ---
  locator.registerLazySingleton<ISettingsRepository>(
      () => SettingsRepositoryImpl(locator<SharedPreferences>()));

  locator.registerLazySingleton<IDashboardRepository>(
      () => DashboardRepositoryImpl(locator<ProductDatabaseManager>()));

  locator.registerLazySingleton<IWordRepository>(
      () => WordRepositoryImpl(locator<ProductDatabaseManager>()));

  locator.registerLazySingleton<ITestRepository>(
      () => TestRepositoryImpl(locator<ProductDatabaseManager>()));

  // --- VIEW MODELS ---
  locator.registerLazySingleton(() => SettingsViewModel(
        locator<ISettingsRepository>(),
        locator<IWordRepository>(),
      ));

  locator.registerFactory(() => SplashViewModel(
        locator<ISettingsRepository>(),
        locator<IWordRepository>(),
      ));

  locator.registerFactory(() => DashboardViewModel(
        locator<IDashboardRepository>(),
        locator<ISettingsRepository>(),
      ));

  locator.registerFactory(() => StudyViewModel(
        locator<IWordRepository>(),
        locator<ITestRepository>(),
        locator<ISettingsRepository>(),
        locator<TtsService>(),
        locator<SpeechService>(),
      ));

  locator.registerFactory(() => OnboardingViewModel(
        locator<ISettingsRepository>(),
        locator<IWordRepository>(),
      ));

  locator.registerFactory(() => MainViewModel());

  locator.registerFactory(() => MenuViewModel(
        locator<IWordRepository>(),
        locator<ITestRepository>(),
        locator<ISettingsRepository>(),
      ));
}
