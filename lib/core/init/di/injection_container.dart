import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- CORE / NETWORK ---
import '../../../../core/init/network/network_manager.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';

// --- DATABASE ---
import '../../../product/init/database/ProductDatabaseManager.dart';

// --- AUTH FEATURE ---
import '../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../../features/auth/domain/repositories/i_auth_repository.dart';
import '../../../features/auth/presentation/view_model/auth_view_model.dart';

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
  // --- CORE & EXTERNAL SERVICES ---
  final sharedPreferences = await SharedPreferences.getInstance();
  locator.registerLazySingleton(() => sharedPreferences);
  locator.registerLazySingleton(() => TtsService());
  locator.registerLazySingleton(() => SpeechService());

  // Network Manager (Tüm API trafiğini yöneten merkez)
  locator.registerLazySingleton<NetworkManager>(() => NetworkManager.instance);

  // Database Manager
  locator.registerLazySingleton(() => ProductDatabaseManager.instance);

  // --- DATA SOURCES ---

  // Auth Local (Token ve kullanıcı bilgilerini yerel hafızada tutar)
  locator.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(locator<SharedPreferences>()));

  // --- REPOSITORIES ---

  // Settings Repository
  locator.registerLazySingleton<ISettingsRepository>(
      () => SettingsRepositoryImpl(locator<SharedPreferences>()));

  // Dashboard Repository
  locator.registerLazySingleton<IDashboardRepository>(
      () => DashboardRepositoryImpl(locator<ProductDatabaseManager>()));

  // Word Repository (NetworkManager dahili kullanılıyor, sadece DB veriyoruz)
  locator.registerLazySingleton<IWordRepository>(
      () => WordRepositoryImpl(locator<ProductDatabaseManager>()));

  // Test Repository
  locator.registerLazySingleton<ITestRepository>(
      () => TestRepositoryImpl(locator<ProductDatabaseManager>()));

  // Auth Repository (RemoteDataSource kalktı, direkt NetworkManager kullanıyor)
  locator.registerLazySingleton<IAuthRepository>(
      () => AuthRepositoryImpl(locator<AuthLocalDataSource>()));

  // --- VIEW MODELS ---

  locator.registerLazySingleton(() => SettingsViewModel(
        locator<ISettingsRepository>(),
        locator<IWordRepository>(),
      ));

  locator.registerFactory(() => SplashViewModel(
        locator<ISettingsRepository>(),
        locator<IAuthRepository>(),
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

  locator.registerFactory(() => AuthViewModel(locator<IAuthRepository>()));
}
