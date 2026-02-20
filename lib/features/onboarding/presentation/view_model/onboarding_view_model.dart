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

  // 4 sayfa: dil kaynağı, dil hedefi, seviye, günlük hedef
  static const int totalPages = 4;

  String _uiSourceLang = 'en-US';
  String _uiTargetLang = 'tr-TR';
  String _selectedLevel = 'beginner';
  int _selectedDailyGoal = 20;

  String get uiSourceLang => _uiSourceLang;
  String get uiTargetLang => _uiTargetLang;
  String get selectedLevel => _selectedLevel;
  int get selectedDailyGoal => _selectedDailyGoal;

  // Hata yönetimi
  bool _hasError = false;
  bool get hasError => _hasError;
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<String> get supportedUiLanguages =>
      LanguageManager.instance.supportedLocales
          .map((e) => LanguageManager.instance.getLocaleString(e))
          .toList();

  final List<String> difficultyLevels = [
    'beginner',
    'intermediate',
    'advanced'
  ];

  // Önerilen hedef seçenekleri
  final List<int> dailyGoalOptions = [5, 10, 15, 20, 30, 50];

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

  void setDailyGoal(int goal) {
    _selectedDailyGoal = goal;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < totalPages - 1) {
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

  bool get isLastPage => _currentPage == totalPages - 1;

  Future<bool> completeOnboarding(BuildContext context) async {
    changeLoading();
    _hasError = false;
    _errorMessage = '';

    final dbSource =
        LanguageManager.instance.getShortCodeFromString(_uiSourceLang);
    final dbTarget =
        LanguageManager.instance.getShortCodeFromString(_uiTargetLang);

    await _settingsRepo.saveLanguageSettings(dbSource, dbTarget);
    await _settingsRepo.saveProficiencyLevel(_selectedLevel);
    await _settingsRepo.saveDailyGoal(_selectedDailyGoal);

    // Kelime veritabanını asset'ten yükle
    final downloadResult =
        await _wordRepo.downloadInitialContent(dbSource, dbTarget);

    final success = downloadResult.fold(
      (failure) {
        _hasError = true;
        _errorMessage = failure.message;
        return false;
      },
      (_) => true,
    );

    if (!success) {
      changeLoading();
      notifyListeners();
      return false;
    }

    final parts = _uiSourceLang.split('-');
    final targetLocale = Locale(parts[0], parts.length > 1 ? parts[1] : '');

    if (context.mounted) {
      await context.setLocale(targetLocale);
    }

    await _settingsRepo.completeOnboarding();
    changeLoading();
    return true;
  }
}
