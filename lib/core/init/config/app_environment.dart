import '../../constants/enum/app_enums.dart';

/// Uygulama ortamını (Dev/Prod) yöneten sınıf.
class AppEnvironment {
  // Singleton değil, setup ile kurulan bir yapı
  static late AppEnvironmentConfig _config;

  static void setup(AppEnvironmentConfig config) {
    _config = config;
  }

  // Getterlar (Uygulamanın her yerinden erişim için)
  static AppEnvironmentConfig get config => _config;
  static bool get isProduction => _config.type == AppEnvironmentType.PRODUCTION;
  static String get baseUrl => _config.baseUrl;
  static bool get useMockApi => _config.useMockApi;
}

/// Her ortamın sahip olması gereken ayarların şablonu
class AppEnvironmentConfig {
  final AppEnvironmentType type;
  final String baseUrl;
  final String? apiKey;
  final bool useMockApi;

  AppEnvironmentConfig({
    required this.type,
    required this.baseUrl,
    this.apiKey,
    this.useMockApi = false,
  });

  // Hazır Şablonlar

  // 1. Geliştirme Ortamı Ayarları
  static final development = AppEnvironmentConfig(
    type: AppEnvironmentType.DEVELOPMENT,
    baseUrl: 'https://dev-api.seninuygulaman.com', // Veya localhost
    useMockApi: true, // Dev ortamında Mock kullan
  );

  // 2. Canlı Ortam Ayarları
  static final production = AppEnvironmentConfig(
    type: AppEnvironmentType.PRODUCTION,
    baseUrl: 'https://api.seninuygulaman.com',
    useMockApi: false, // Canlıda asla Mock kullanma
  );
}
