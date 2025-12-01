import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/base/base_view_model.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';
import '../../../study_zone/domain/repositories/i_word_repository.dart';
import '../../../../core/init/lang/language_manager.dart';

class OnboardingViewModel extends BaseViewModel {
  final ISettingsRepository _settingsRepo;
  final IWordRepository _wordRepo;

  OnboardingViewModel(this._settingsRepo, this._wordRepo) {
    _init();
  }

  int _currentPage = 0;
  int get currentPage => _currentPage;

  String _uiSourceLang = 'en-US';
  String _uiTargetLang = 'tr-TR';
  String _selectedLevel = 'beginner';

  String get uiSourceLang => _uiSourceLang;
  String get uiTargetLang => _uiTargetLang;
  String get selectedLevel => _selectedLevel;

  List<String> get supportedUiLanguages =>
      LanguageManager.instance.supportedLocales
          .map((e) => LanguageManager.instance.getLocaleString(e))
          .toList();

  final List<String> difficultyLevels = [
    'beginner',
    'intermediate',
    'advanced'
  ];

  Future<void> _init() async {
    try {
      final String systemLocale = Platform.localeName;
      final String normalizedLocale =
          LanguageManager.instance.normalizeDeviceLocale(systemLocale);

      _uiSourceLang = normalizedLocale;

      if (_uiSourceLang.startsWith('en')) {
        _uiTargetLang = 'es-ES';
      } else {
        _uiTargetLang = 'en-US';
      }

      notifyListeners();
    } catch (e) {
      _uiSourceLang = 'en-US';
      _uiTargetLang = 'tr-TR';
    }
  }

  void setSourceLang(String longCode) {
    if (_uiSourceLang == longCode) return;
    _uiSourceLang = longCode;

    if (_uiTargetLang == longCode) {
      _uiTargetLang = supportedUiLanguages.firstWhere(
        (lang) => lang != longCode,
        orElse: () => 'en-US',
      );
    }
    notifyListeners();
  }

  void setTargetLang(String longCode) {
    if (longCode == _uiSourceLang) return;
    _uiTargetLang = longCode;
    notifyListeners();
  }

  void setLevel(String level) {
    _selectedLevel = level;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < 2) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding(BuildContext context) async {
    changeLoading();

    final dbSource =
        LanguageManager.instance.getShortCodeFromString(_uiSourceLang);
    final dbTarget =
        LanguageManager.instance.getShortCodeFromString(_uiTargetLang);

    await _settingsRepo.saveLanguageSettings(dbSource, dbTarget);
    await _settingsRepo.saveProficiencyLevel(_selectedLevel);

    await _wordRepo.downloadInitialContent(dbSource, dbTarget);

    final parts = _uiSourceLang.split('-');
    final targetLocale = Locale(parts[0], parts.length > 1 ? parts[1] : '');

    if (context.mounted) {
      await context.setLocale(targetLocale);
    }

    await _settingsRepo.completeOnboarding();
    changeLoading();
  }
}
