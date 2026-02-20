class AppConstants {
  // Uygulama Bilgileri
  static const String appName = 'Global Kelime';
  static const String packageName = 'com.seninuygulaman.pratikapp';

  // Database
  static const String dbName = 'vocab_app_v2.db';
  static const int dbVersion = 2;

  // Assets & Paths
  static const String langAssetPath = 'assets/lang';
  static const String wordsDatasetPath = 'assets/dataset/words.json';

  // Shared Preferences Keys (Cache)
  static const String keySourceLang = 'source_lang';
  static const String keyTargetLang = 'target_lang';
  static const String keyProficiencyLevel = 'proficiency_level';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyBatchSize = 'batchSize'; // Test soru sayısı
  static const String keyDailyGoal = 'dailyGoal'; // Günlük kelime hedefi

  static const String keyAutoPlaySound = 'autoPlaySound';
  static const String keyThemeMode = 'theme_mode';
}
