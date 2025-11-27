import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/i_settings_repository.dart';

class SettingsRepositoryImpl implements ISettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepositoryImpl(this._prefs);

  static const String _sourceLangKey = 'source_lang';
  static const String _targetLangKey = 'target_lang';
  static const String _levelKey = 'proficiency_level';
  static const String _isFirstLaunchKey = 'is_first_launch_v2';
  static const String _batchSizeKey = 'batchSize';
  static const String _autoPlaySoundKey = 'autoPlaySound';
  static const String _themeModeKey = 'theme_mode'; // Yeni Key

  // ... Diğer metotlar aynen kalacak (getLanguageSettings vb.) ...
  // ... (Kod tekrarı olmasın diye sadece değişenleri yazıyorum, eskileri silmeyin) ...

  @override
  Future<Either<Failure, Map<String, String>>> getLanguageSettings() async {
    // Mevcut kodunuz...
    try {
      String source =
          _prefs.getString(_sourceLangKey) ?? _detectDeviceLanguage();
      String target = _prefs.getString(_targetLangKey) ?? 'en';
      if (source == target) target = (source == 'en') ? 'tr' : 'en';

      return Right({
        'source': source,
        'target': target,
        'level': _prefs.getString(_levelKey) ?? 'beginner',
      });
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ... Buradaki detectDeviceLanguage ve saveLanguageSettings gibi diğer metotlar aynen kalsın ...
  String _detectDeviceLanguage() {
    try {
      final String deviceLocale = Platform.localeName.split('_')[0];
      const supported = ['tr', 'en', 'es', 'de', 'fr', 'pt'];
      if (supported.contains(deviceLocale)) return deviceLocale;
    } catch (e) {}
    return 'en';
  }

  @override
  Future<Either<Failure, void>> saveLanguageSettings(
      String source, String target) async {
    await _prefs.setString(_sourceLangKey, source);
    await _prefs.setString(_targetLangKey, target);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveProficiencyLevel(String level) async {
    await _prefs.setString(_levelKey, level);
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> isFirstLaunch() async =>
      Right(_prefs.getBool(_isFirstLaunchKey) ?? true);

  @override
  Future<Either<Failure, void>> completeOnboarding() async {
    await _prefs.setBool(_isFirstLaunchKey, false);
    return const Right(null);
  }

  @override
  Future<Either<Failure, int>> getBatchSize() async =>
      Right(_prefs.getInt(_batchSizeKey) ?? 10);

  @override
  Future<Either<Failure, void>> saveBatchSize(int size) async {
    await _prefs.setInt(_batchSizeKey, size);
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> getAutoPlaySound() async =>
      Right(_prefs.getBool(_autoPlaySoundKey) ?? true);

  @override
  Future<Either<Failure, void>> saveAutoPlaySound(bool value) async {
    await _prefs.setBool(_autoPlaySoundKey, value);
    return const Right(null);
  }

  // --- TEMA METOTLARI ---
  @override
  Future<Either<Failure, ThemeMode>> getThemeMode() async {
    try {
      final String? themeStr = _prefs.getString(_themeModeKey);
      if (themeStr == 'light') return const Right(ThemeMode.light);
      if (themeStr == 'dark') return const Right(ThemeMode.dark);
      return const Right(ThemeMode.system);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode) async {
    try {
      String val = 'system';
      if (mode == ThemeMode.light) val = 'light';
      if (mode == ThemeMode.dark) val = 'dark';
      await _prefs.setString(_themeModeKey, val);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
