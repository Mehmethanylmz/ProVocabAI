import 'package:flutter/material.dart';
import '../data/models/test_result.dart';
import '../data/models/word_model.dart';
import '../data/repositories/test_repository.dart';
import '../data/repositories/word_repository.dart';
import '../data/repositories/settings_repository.dart';

class TestMenuViewModel with ChangeNotifier {
  final TestRepository _testRepo = TestRepository();
  final WordRepository _wordRepo = WordRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<TestResult> _testHistory = [];
  List<TestResult> get testHistory => _testHistory;

  int _dailyReviewCount = 0;
  int get dailyReviewCount => _dailyReviewCount;

  int _dailyTarget = 10;
  int get dailyTarget => _dailyTarget;

  int _filteredWordCount = 0;
  int get filteredWordCount => _filteredWordCount;

  bool get canStartTest => _filteredWordCount > 0;

  List<Word> _difficultWords = [];
  List<Word> get difficultWords => _difficultWords;

  List<String> _allCategories = [];
  List<String> get allCategories => _allCategories;

  List<String> _allPartsOfSpeech = [];
  List<String> get allPartsOfSpeech => _allPartsOfSpeech;

  List<String> _selectedCategories = ['all'];
  List<String> get selectedCategories => _selectedCategories;

  List<String> _selectedGrammar = ['all'];
  List<String> get selectedGrammar => _selectedGrammar;

  Map<String, double> _skillStats = {
    'reading': 50,
    'listening': 50,
    'speaking': 50,
    'grammar': 50,
  };
  Map<String, double> get skillStats => _skillStats;

  String _coachMessage = "coach_msg_general";
  String get coachMessage => _coachMessage;

  TestMenuViewModel() {
    loadTestData();
  }

  Future<void> loadTestData() async {
    _isLoading = true;
    notifyListeners();

    final settings = await _settingsRepo.getLanguageSettings();
    final targetLang = settings['target']!;
    _dailyTarget = await _settingsRepo.getBatchSize();

    await _testRepo.deleteOldTestHistory();
    await fetchTestHistory();

    _dailyReviewCount =
        await _wordRepo.getDailyReviewCount(_dailyTarget, targetLang);
    _difficultWords = await _wordRepo.getDifficultWords(targetLang);

    _allCategories = await _wordRepo.getAllUniqueCategories();
    _allPartsOfSpeech = await _wordRepo.getUniquePartsOfSpeech();

    calculateSkillStats();
    await refreshFilteredCount();

    _isLoading = false;
    notifyListeners();
  }

  void calculateSkillStats() {
    _skillStats = {
      'reading': 75,
      'listening': 40,
      'speaking': 25,
      'grammar': 60,
    };

    final lowest =
        _skillStats.entries.reduce((a, b) => a.value < b.value ? a : b);

    if (lowest.key == 'speaking') {
      _coachMessage = "coach_msg_speaking";
    } else if (lowest.key == 'listening') {
      _coachMessage = "coach_msg_listening";
    } else {
      _coachMessage = "coach_msg_general";
    }
  }

  Future<void> refreshFilteredCount() async {
    final settings = await _settingsRepo.getLanguageSettings();
    final targetLang = settings['target']!;

    _filteredWordCount = await _wordRepo.getFilteredReviewCount(
        targetLang: targetLang,
        categories: _selectedCategories,
        grammar: _selectedGrammar);
    notifyListeners();
  }

  Future<void> fetchTestHistory() async {
    _testHistory = await _testRepo.getTestHistory();
    notifyListeners();
  }

  void toggleCategory(String category) {
    if (category == 'all') {
      _selectedCategories = ['all'];
    } else {
      if (_selectedCategories.contains('all'))
        _selectedCategories.remove('all');

      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }

      if (_selectedCategories.isEmpty) _selectedCategories = ['all'];
    }
    refreshFilteredCount();
  }

  void toggleGrammar(String grammar) {
    if (grammar == 'all') {
      _selectedGrammar = ['all'];
    } else {
      if (_selectedGrammar.contains('all')) _selectedGrammar.remove('all');

      if (_selectedGrammar.contains(grammar)) {
        _selectedGrammar.remove(grammar);
      } else {
        _selectedGrammar.add(grammar);
      }

      if (_selectedGrammar.isEmpty) _selectedGrammar = ['all'];
    }
    refreshFilteredCount();
  }
}
