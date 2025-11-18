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

  List<Word> _difficultWords = [];
  List<Word> get difficultWords => _difficultWords;

  int _dailyReviewCount = 0;
  int get dailyReviewCount => _dailyReviewCount;

  TestMenuViewModel() {
    loadTestData();
  }

  Future<void> loadTestData() async {
    _isLoading = true;
    notifyListeners();

    final settings = await _settingsRepo.getLanguageSettings();
    final targetLang = settings['target']!;
    final batchSize = await _settingsRepo.getBatchSize();

    await _testRepo.deleteOldTestHistory();
    await fetchTestHistory();

    _dailyReviewCount = await _wordRepo.getDailyReviewCount(
      batchSize,
      targetLang,
    );
    _difficultWords = await _wordRepo.getDifficultWords(targetLang);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTestHistory() async {
    _testHistory = await _testRepo.getTestHistory();
    notifyListeners();
  }
}
