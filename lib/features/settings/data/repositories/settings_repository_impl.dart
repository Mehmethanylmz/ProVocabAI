// lib/features/settings/data/repositories/settings_repository_impl.dart
//
// FIX: themeStream eklendi — app.dart anlık theme değişimini dinleyebilir

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../../../../core/constants/app_constants.dart';

class SettingsRepositoryImpl implements ISettingsRepository {
  final SharedPreferences _prefs;
  final _themeController = StreamController<ThemeMode>.broadcast();

  SettingsRepositoryImpl(this._prefs);

  /// app.dart bu stream'i dinleyerek anlık theme güncellemesi yapar.
  Stream<ThemeMode> get themeStream => _themeController.stream;

  void dispose() => _themeController.close();

  @override
  Future<Either<Failure, Map<String, String>>> getLanguageSettings() async {
    try {
      String source = _prefs.getString(AppConstants.keySourceLang) ??
          _detectDeviceLanguage();
      String target = _prefs.getString(AppConstants.keyTargetLang) ?? 'en';
      if (source == target) target = (source == 'en') ? 'tr' : 'en';
      return Right({
        'source': source,
        'target': target,
        'level':
            _prefs.getString(AppConstants.keyProficiencyLevel) ?? 'beginner',
      });
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  String _detectDeviceLanguage() {
    try {
      final String deviceLocale = Platform.localeName.split('_')[0];
      const supported = ['tr', 'en', 'es', 'de', 'fr', 'pt'];
      if (supported.contains(deviceLocale)) return deviceLocale;
    } catch (_) {}
    return 'en';
  }

  @override
  Future<Either<Failure, void>> saveLanguageSettings(
      String source, String target) async {
    await _prefs.setString(AppConstants.keySourceLang, source);
    await _prefs.setString(AppConstants.keyTargetLang, target);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveProficiencyLevel(String level) async {
    await _prefs.setString(AppConstants.keyProficiencyLevel, level);
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> isFirstLaunch() async =>
      Right(_prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true);

  @override
  Future<Either<Failure, void>> completeOnboarding() async {
    await _prefs.setBool(AppConstants.keyIsFirstLaunch, false);
    return const Right(null);
  }

  @override
  Future<Either<Failure, int>> getBatchSize() async =>
      Right(_prefs.getInt(AppConstants.keyBatchSize) ?? 10);

  @override
  Future<Either<Failure, void>> saveBatchSize(int size) async {
    await _prefs.setInt(AppConstants.keyBatchSize, size);
    return const Right(null);
  }

  @override
  Future<Either<Failure, int>> getDailyGoal() async =>
      Right(_prefs.getInt(AppConstants.keyDailyGoal) ?? 20);

  @override
  Future<Either<Failure, void>> saveDailyGoal(int goal) async {
    await _prefs.setInt(AppConstants.keyDailyGoal, goal);
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> getAutoPlaySound() async =>
      Right(_prefs.getBool(AppConstants.keyAutoPlaySound) ?? true);

  @override
  Future<Either<Failure, void>> saveAutoPlaySound(bool value) async {
    await _prefs.setBool(AppConstants.keyAutoPlaySound, value);
    return const Right(null);
  }

  @override
  Future<Either<Failure, ThemeMode>> getThemeMode() async {
    try {
      final String? themeStr = _prefs.getString(AppConstants.keyThemeMode);
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
      await _prefs.setString(AppConstants.keyThemeMode, val);

      // Stream'e yay — app.dart anlık günceller
      _themeController.add(mode);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
