import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _batchSizeKey = 'batchSize';
  static const String _notifyTimeKey = 'notifyTime';
  static const String _autoPlaySoundKey = 'autoPlaySound';

  Future<void> saveBatchSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_batchSizeKey, size);
  }

  Future<int> getBatchSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_batchSizeKey) ?? 20;
  }

  Future<void> saveNotificationTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = '${time.hour}:${time.minute}';
    await prefs.setString(_notifyTimeKey, timeString);
  }

  Future<TimeOfDay> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_notifyTimeKey) ?? '20:00';

    try {
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return TimeOfDay(hour: 20, minute: 0);
    }
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
