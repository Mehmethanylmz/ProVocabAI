import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../../features/dashboard/domain/repositories/i_dashboard_repository.dart';
import '../../../features/dashboard/presentation/view_model/dashboard_view_model.dart';
import '../../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../../features/settings/domain/repositories/i_settings_repository.dart';
import '../../../features/settings/presentation/viewmodel/settings_view_model.dart';
import '../../../features/splash/presentation/viewmodel/splash_view_model.dart';
import '../../../features/study_zone/data/repositories/test_repository_impl.dart';
import '../../../features/study_zone/data/repositories/word_repository_impl.dart';
import '../../../features/study_zone/domain/repositories/i_test_repository.dart';
import '../../../features/study_zone/domain/repositories/i_word_repository.dart';
import '../../../features/study_zone/presentation/view_model/menu_view_model.dart';
import '../../../features/study_zone/presentation/view_model/study_view_model.dart';
import '../../../features/main/presentation/view_model/main_view_model.dart';
import '../../../features/onboarding/presentation/view_model/onboarding_view_model.dart';
import '../../../product/init/database/ProductDatabaseManager.dart';
import '../../../product/service/mock_api_service.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';
import '../config/dio_manager.dart';
import '../../../product/service/api_service.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  locator.registerLazySingleton(() => sharedPreferences);
  locator.registerLazySingleton(() => TtsService());
  locator.registerLazySingleton(() => SpeechService());

  locator.registerLazySingleton<Dio>(() => DioManager.instance.dio);

  // --- API SERVICE SEÇİMİ ---
  // Gerçek API hazır olduğunda aşağıdaki Mock satırını yorumlayıp alttakini açman yeterli.

  // 1. MOCK KULLANIMI (Şu an aktif):
  locator.registerLazySingleton<ApiService>(() => MockApiService());

  // 2. GERÇEK API KULLANIMI (İleride açılacak):
  // locator.registerLazySingleton<ApiService>(() => ApiService(locator<Dio>()));

  // -------------------------

  locator.registerLazySingleton(() => ProductDatabaseManager.instance);

  locator.registerLazySingleton<ISettingsRepository>(
      () => SettingsRepositoryImpl(locator<SharedPreferences>()));

  locator.registerLazySingleton<IDashboardRepository>(
      () => DashboardRepositoryImpl(locator<ProductDatabaseManager>()));

  locator.registerLazySingleton<IWordRepository>(() => WordRepositoryImpl(
        locator<ProductDatabaseManager>(),
        locator<ApiService>(), // Buraya artık MockApiService nesnesi gelecek
      ));

  locator.registerLazySingleton<ITestRepository>(
      () => TestRepositoryImpl(locator<ProductDatabaseManager>()));

  // VIEW MODELS
  locator.registerLazySingleton(() => SettingsViewModel(
        locator<ISettingsRepository>(),
        locator<IWordRepository>(),
      ));

  locator.registerFactory(() => SplashViewModel(
        locator<ISettingsRepository>(),
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
