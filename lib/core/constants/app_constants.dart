class AppConstants {
  // Uygulama Bilgileri
  static const String appName = 'Global Kelime';
  static const String packageName = 'com.seninuygulaman.pratikapp';

  // Network
  static const String baseUrl = 'https://api.seninuygulaman.com';
  static const int connectTimeout = 10000; // 10 sn
  static const int receiveTimeout = 10000;

  // Database
  static const String dbName = 'vocab_app_v2.db';
  static const int dbVersion = 1;

  // Assets & Paths
  static const String langAssetPath = 'assets/lang';

  // Shared Preferences Keys (Cache)
  static const String keySourceLang = 'source_lang';
  static const String keyTargetLang = 'target_lang';
  static const String keyProficiencyLevel = 'proficiency_level';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyBatchSize = 'batchSize';
  static const String keyAutoPlaySound = 'autoPlaySound';
  static const String keyThemeMode = 'theme_mode';
  // AUTH KEYS
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
}
