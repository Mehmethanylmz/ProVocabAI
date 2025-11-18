import 'package:flutter/material.dart';
import '../data/repositories/settings_repository.dart';

class SettingsViewModel with ChangeNotifier {
  final SettingsRepository _settingsRepo = SettingsRepository();

  String _sourceLang = 'tr';
  String _targetLang = 'en';
  String _proficiencyLevel = 'beginner';
  int _batchSize = 10;
  bool _autoPlaySound = true;
  bool _isLoading = true;

  String get sourceLang => _sourceLang;
  String get targetLang => _targetLang;
  String get proficiencyLevel => _proficiencyLevel;
  int get batchSize => _batchSize;
  bool get autoPlaySound => _autoPlaySound;
  bool get isLoading => _isLoading;

  SettingsViewModel() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    final langs = await _settingsRepo.getLanguageSettings();
    _sourceLang = langs['source']!;
    _targetLang = langs['target']!;
    _proficiencyLevel = langs['level']!;

    _batchSize = await _settingsRepo.getBatchSize();
    _autoPlaySound = await _settingsRepo.getAutoPlaySound();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateLanguages(String source, String target) async {
    _sourceLang = source;
    _targetLang = target;
    await _settingsRepo.saveLanguageSettings(source, target);
    notifyListeners();
  }

  Future<void> updateLevel(String level) async {
    _proficiencyLevel = level;
    await _settingsRepo.saveProficiencyLevel(level);
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
