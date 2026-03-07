// lib/features/settings/domain/repositories/i_settings_repository.dart
//
// FAZ 6 FIX: getNotificationsEnabled + saveNotificationsEnabled eklendi

import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class ISettingsRepository {
  Future<Either<Failure, Map<String, String>>> getLanguageSettings();
  Future<Either<Failure, void>> saveLanguageSettings(
      String source, String target);

  Future<Either<Failure, void>> saveProficiencyLevel(String level);

  Future<Either<Failure, int>> getBatchSize();
  Future<Either<Failure, void>> saveBatchSize(int size);

  Future<Either<Failure, int>> getDailyGoal();
  Future<Either<Failure, void>> saveDailyGoal(int goal);

  Future<Either<Failure, bool>> getAutoPlaySound();
  Future<Either<Failure, void>> saveAutoPlaySound(bool value);

  Future<Either<Failure, bool>> isFirstLaunch();
  Future<Either<Failure, void>> completeOnboarding();

  Future<Either<Failure, ThemeMode>> getThemeMode();
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode);

  Future<Either<Failure, bool>> getNotificationsEnabled();
  Future<Either<Failure, void>> saveNotificationsEnabled(bool enabled);

  /// F10-07: Üst üste günlük hedef tutturma serisi.
  Future<Either<Failure, int>> getDailyGoalStreak();
  Future<Either<Failure, void>> saveDailyGoalStreak(int streak);

  /// F10-07: En son hedef tutturulan gün ('YYYY-MM-DD').
  Future<Either<Failure, String?>> getLastGoalMetDate();
  Future<Either<Failure, void>> saveLastGoalMetDate(String date);

  /// F14-03: Bildirim saati (saat, 0-23).
  Future<Either<Failure, int>> getNotificationHour();
  Future<Either<Failure, void>> saveNotificationHour(int hour);
}
