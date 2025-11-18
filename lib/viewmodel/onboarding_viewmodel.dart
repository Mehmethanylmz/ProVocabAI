import 'package:flutter/material.dart';
import '../data/repositories/settings_repository.dart';

class OnboardingViewModel with ChangeNotifier {
  final SettingsRepository _settingsRepo = SettingsRepository();

  int _currentPage = 0;
  String _selectedSourceLang = 'en';
  String _selectedTargetLang = 'tr';
  String _selectedLevel = 'beginner';

  final Map<String, String> languages = {
    'tr': 'Türkçe',
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
    'fr': 'Français',
    'pt': 'Português',
  };

  final Map<String, String> levels = {
    'beginner': 'Başlangıç (A1-A2)',
    'intermediate': 'Orta (B1-B2)',
    'advanced': 'İleri (C1-C2)',
  };

  OnboardingViewModel() {
    _init();
  }

  int get currentPage => _currentPage;
  String get selectedSourceLang => _selectedSourceLang;
  String get selectedTargetLang => _selectedTargetLang;
  String get selectedLevel => _selectedLevel;

  Future<void> _init() async {
    final currentSettings = await _settingsRepo.getLanguageSettings();
    _selectedSourceLang = currentSettings['source']!;
    // Hedef dil kaynak dille aynı olmasın diye basit kontrol
    if (_selectedSourceLang == 'en') {
      _selectedTargetLang = 'es';
    } else {
      _selectedTargetLang = 'en';
    }
    notifyListeners();
  }

  void setSourceLang(String code) {
    _selectedSourceLang = code;
    if (_selectedTargetLang == code) {
      // Çakışmayı önle
      _selectedTargetLang = code == 'en' ? 'tr' : 'en';
    }
    notifyListeners();
  }

  void setTargetLang(String code) {
    if (code == _selectedSourceLang) return;
    _selectedTargetLang = code;
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

  Future<void> completeOnboarding() async {
    await _settingsRepo.saveLanguageSettings(
      _selectedSourceLang,
      _selectedTargetLang,
    );
    await _settingsRepo.saveProficiencyLevel(_selectedLevel);
    await _settingsRepo.completeOnboarding();
  }
}
