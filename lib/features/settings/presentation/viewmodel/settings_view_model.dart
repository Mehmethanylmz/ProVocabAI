import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/base/base_view_model.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../../../study_zone/domain/repositories/i_word_repository.dart';
import '../../../../core/init/lang/language_manager.dart';

class SettingsViewModel extends BaseViewModel {
  final ISettingsRepository _repository;
  final IWordRepository _wordRepo;

  SettingsViewModel(this._repository, this._wordRepo);

  String _sourceLang = 'en-US';
  String _targetLang = 'tr-TR';
  String _proficiencyLevel = 'beginner';
  int _batchSize = 10; // Test soru sayısı
  int _dailyGoal = 20; // Günlük kelime hedefi
  bool _autoPlaySound = true;
  ThemeMode _themeMode = ThemeMode.system;

  String get sourceLang => _sourceLang;
  String get targetLang => _targetLang;
  String get proficiencyLevel => _proficiencyLevel;
  int get batchSize => _batchSize;
  int get dailyGoal => _dailyGoal;
  bool get autoPlaySound => _autoPlaySound;
  ThemeMode get themeMode => _themeMode;

  Future<void> loadSettings() async {
    final langResult = await _repository.getLanguageSettings();

    langResult.fold((failure) {
      _initializeWithDeviceSettings();
    }, (settings) {
      final savedSource = settings['source'];
      final savedTarget = settings['target'];

      if (savedSource == null || savedSource.isEmpty) {
        _initializeWithDeviceSettings();
      } else {
        _sourceLang = _ensureLongLocale(savedSource);
        _targetLang = _ensureLongLocale(savedTarget ?? 'en-US');

        if (_sourceLang == _targetLang) {
          _targetLang = _pickAlternativeLanguage(_sourceLang);
        }
      }

      _proficiencyLevel = settings['level'] ?? 'beginner';
    });

    (await _repository.getBatchSize()).fold((l) {}, (r) => _batchSize = r);
    (await _repository.getDailyGoal()).fold((l) {}, (r) => _dailyGoal = r);
    (await _repository.getAutoPlaySound())
        .fold((l) {}, (r) => _autoPlaySound = r);
    (await _repository.getThemeMode()).fold((l) {}, (r) => _themeMode = r);

    notifyListeners();
  }

  void _initializeWithDeviceSettings() {
    try {
      final deviceLocale = Platform.localeName;
      _sourceLang =
          LanguageManager.instance.normalizeDeviceLocale(deviceLocale);

      if (_sourceLang.startsWith('en')) {
        _targetLang = 'es-ES';
      } else {
        _targetLang = 'en-US';
      }
    } catch (e) {
      _sourceLang = 'en-US';
      _targetLang = 'tr-TR';
    }
  }

  String _pickAlternativeLanguage(String currentSource) {
    final supported = LanguageManager.instance.supportedLocales;
    for (var locale in supported) {
      final localeString = LanguageManager.instance.getLocaleString(locale);
      if (localeString != currentSource) {
        return localeString;
      }
    }
    return 'en-US';
  }

  String _ensureLongLocale(String code) {
    if (code.contains('-') || code.contains('_')) {
      return code.replaceAll('_', '-');
    }
    final supported = LanguageManager.instance.supportedLocales;
    try {
      final match = supported.firstWhere((l) => l.languageCode == code);
      return LanguageManager.instance.getLocaleString(match);
    } catch (e) {
      return 'en-US';
    }
  }

  Future<void> updateLanguages(String source, String target) async {
    if (_sourceLang == source && _targetLang == target) return;

    _sourceLang = source;
    _targetLang = target;

    if (_sourceLang == _targetLang) {
      _targetLang = _pickAlternativeLanguage(_sourceLang);
    }

    notifyListeners();

    if (context != null) {
      final locale = LanguageManager.instance.getLocaleFromString(_sourceLang);
      await context!.setLocale(locale);
    }
    final dbSource =
        LanguageManager.instance.getShortCodeFromString(_sourceLang);
    final dbTarget =
        LanguageManager.instance.getShortCodeFromString(_targetLang);

    await _repository.saveLanguageSettings(dbSource, dbTarget);

    await _wordRepo.downloadInitialContent(dbSource, dbTarget);
  }

  Future<void> updateLevel(String level) async {
    if (_proficiencyLevel == level) return;
    _proficiencyLevel = level;
    notifyListeners();
    await _repository.saveProficiencyLevel(level);
  }

  // Test soru sayısı
  Future<void> updateBatchSize(int newSize) async {
    if (_batchSize == newSize) return;
    _batchSize = newSize;
    notifyListeners();
    await _repository.saveBatchSize(newSize);
  }

  // Günlük kelime hedefi
  Future<void> updateDailyGoal(int newGoal) async {
    if (_dailyGoal == newGoal) return;
    _dailyGoal = newGoal;
    notifyListeners();
    await _repository.saveDailyGoal(newGoal);
  }

  Future<void> updateAutoPlaySound(bool newValue) async {
    if (_autoPlaySound == newValue) return;
    _autoPlaySound = newValue;
    notifyListeners();
    await _repository.saveAutoPlaySound(newValue);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _repository.saveThemeMode(mode);
  }
}
