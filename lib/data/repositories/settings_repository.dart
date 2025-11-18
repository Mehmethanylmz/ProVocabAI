import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class SettingsRepository {
  static const String _sourceLangKey = 'source_lang';
  static const String _targetLangKey = 'target_lang';
  static const String _levelKey = 'proficiency_level';
  static const String _isFirstLaunchKey = 'is_first_launch_v2';
  static const String _batchSizeKey = 'batchSize';
  static const String _autoPlaySoundKey = 'autoPlaySound';

  Future<void> saveLanguageSettings(String source, String target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sourceLangKey, source);
    await prefs.setString(_targetLangKey, target);
  }

  Future<void> saveProficiencyLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_levelKey, level);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  Future<Map<String, String>> getLanguageSettings() async {
    final prefs = await SharedPreferences.getInstance();

    String source = prefs.getString(_sourceLangKey) ?? _detectDeviceLanguage();
    String target = prefs.getString(_targetLangKey) ?? 'en';

    if (source == target) {
      target = (source == 'en') ? 'tr' : 'en';
    }

    return {
      'source': source,
      'target': target,
      'level': prefs.getString(_levelKey) ?? 'beginner',
    };
  }

  String _detectDeviceLanguage() {
    try {
      final String deviceLocale = Platform.localeName.split('_')[0];
      const supported = ['tr', 'en', 'es', 'de', 'fr', 'pt'];
      if (supported.contains(deviceLocale)) {
        return deviceLocale;
      }
    } catch (e) {}
    return 'en';
  }

  Future<void> saveBatchSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_batchSizeKey, size);
  }

  Future<int> getBatchSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_batchSizeKey) ?? 10;
  }

  Future<void> saveAutoPlaySound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPlaySoundKey, value);
  }

  Future<bool> getAutoPlaySound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoPlaySoundKey) ?? true;
  }
}
