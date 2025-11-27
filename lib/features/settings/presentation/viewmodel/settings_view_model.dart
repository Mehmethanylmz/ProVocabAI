import 'package:flutter/material.dart';
import '../../../../../core/base/base_view_model.dart';
import '../../domain/repositories/i_settings_repository.dart';

class SettingsViewModel extends BaseViewModel {
  final ISettingsRepository _repository;

  SettingsViewModel(this._repository) {
    // Constructor'da çağırmak yerine View'dan (onModelReady) çağıracağız.
    // Ancak view yüklenmeden veri olsun istersen burada da kalabilir.
    // loadSettings();
  }

  // State Değişkenleri
  String _sourceLang = 'tr';
  String _targetLang = 'en';
  String _proficiencyLevel = 'beginner';
  int _batchSize = 10;
  bool _autoPlaySound = true;
  ThemeMode _themeMode = ThemeMode.system; // Varsayılan

  // Getterlar
  String get sourceLang => _sourceLang;
  String get targetLang => _targetLang;
  String get proficiencyLevel => _proficiencyLevel;
  int get batchSize => _batchSize;
  bool get autoPlaySound => _autoPlaySound;
  ThemeMode get themeMode => _themeMode;

  // --- METHOT İSMİ DÜZELTİLDİ (loadSettings) ---
  Future<void> loadSettings() async {
    // Loading sadece ilk girişte hoş olabilir ama her seferinde ekrana spinner girmesin diye
    // changeLoading yapmıyorum, sadece notifyListeners yeterli.

    // 1. Dil Ayarları
    final langResult = await _repository.getLanguageSettings();
    langResult.fold((l) {}, (r) {
      _sourceLang = r['source'] ?? 'tr';
      _targetLang = r['target'] ?? 'en';
      _proficiencyLevel = r['level'] ?? 'beginner';
    });

    // 2. Batch Size
    final batchResult = await _repository.getBatchSize();
    batchResult.fold((l) {}, (r) => _batchSize = r);

    // 3. Ses Ayarı
    final soundResult = await _repository.getAutoPlaySound();
    soundResult.fold((l) {}, (r) => _autoPlaySound = r);

    // 4. Tema Ayarı
    final themeResult = await _repository.getThemeMode();
    themeResult.fold((l) {}, (r) => _themeMode = r);

    notifyListeners();
  }

  Future<void> updateLanguages(String source, String target) async {
    if (_sourceLang == source && _targetLang == target) return;
    _sourceLang = source;
    _targetLang = target;
    notifyListeners();
    await _repository.saveLanguageSettings(source, target);
  }

  Future<void> updateLevel(String level) async {
    if (_proficiencyLevel == level) return;
    _proficiencyLevel = level;
    notifyListeners();
    await _repository.saveProficiencyLevel(level);
  }

  Future<void> updateBatchSize(int newSize) async {
    if (_batchSize == newSize) return;
    _batchSize = newSize;
    notifyListeners();
    await _repository.saveBatchSize(newSize);
  }

  Future<void> updateAutoPlaySound(bool newValue) async {
    if (_autoPlaySound == newValue) return;
    _autoPlaySound = newValue;
    notifyListeners();
    await _repository.saveAutoPlaySound(newValue);
  }

  // --- TEMA DEĞİŞTİRME ---
  Future<void> updateThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners(); // App.dart bunu dinleyip temayı güncelleyecek
    await _repository.saveThemeMode(mode);
  }
}
