import 'package:flutter/material.dart';
import '../data/repository/settings_repository.dart';

class SettingsViewModel with ChangeNotifier {
  final SettingsRepository _settingsRepo = SettingsRepository();

  int _batchSize = 20;
  int get batchSize => _batchSize;

  bool _autoPlaySound = true;
  bool get autoPlaySound => _autoPlaySound;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SettingsViewModel() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    _batchSize = await _settingsRepo.getBatchSize();
    _autoPlaySound = await _settingsRepo.getAutoPlaySound();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateBatchSize(int newSize) async {
    _batchSize = newSize;
    await _settingsRepo.saveBatchSize(newSize);
    notifyListeners();
  }

  Future<void> updateAutoPlaySound(bool newValue) async {
    _autoPlaySound = newValue;
    await _settingsRepo.saveAutoPlaySound(newValue);
    notifyListeners();
  }
}
