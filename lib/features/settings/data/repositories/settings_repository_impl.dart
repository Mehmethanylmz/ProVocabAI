// lib/features/settings/data/repositories/settings_repository_impl.dart
//
// FAZ 6 FIX:
//   - getNotificationsEnabled / saveNotificationsEnabled eklendi
//   - Bildirim kapatınca Firestore'dan fcmToken silinir (push gelmez)
//   - Bildirim açınca FCM token yeniden alınır ve Firestore'a yazılır

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  Stream<ThemeMode> get themeStream => _themeController.stream;

  void dispose() => _themeController.close();

  // ── Bildirim (FAZ 6) ────────────────────────────────────────────────────

  static const _keyNotificationsEnabled = 'notifications_enabled';

  @override
  Future<Either<Failure, bool>> getNotificationsEnabled() async {
    try {
      return Right(_prefs.getBool(_keyNotificationsEnabled) ?? true);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveNotificationsEnabled(bool enabled) async {
    try {
      await _prefs.setBool(_keyNotificationsEnabled, enabled);

      // Firestore'da fcmToken güncelle
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        if (enabled) {
          // Token yeniden al ve yaz
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            final batch = FirebaseFirestore.instance.batch();
            batch.set(
              FirebaseFirestore.instance.doc('users/$uid'),
              {'fcmToken': token},
              SetOptions(merge: true),
            );
            batch.set(
              FirebaseFirestore.instance.doc('users/$uid/profile/main'),
              {'fcmToken': token},
              SetOptions(merge: true),
            );
            await batch.commit();
          }
        } else {
          // Token sil → Cloud Function bildirim göndermez
          final batch = FirebaseFirestore.instance.batch();
          batch.update(
            FirebaseFirestore.instance.doc('users/$uid'),
            {'fcmToken': FieldValue.delete()},
          );
          batch.update(
            FirebaseFirestore.instance.doc('users/$uid/profile/main'),
            {'fcmToken': FieldValue.delete()},
          );
          await batch.commit();
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ── Mevcut methodlar (değişiklik yok) ──────────────────────────────────

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
      _themeController.add(mode);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
