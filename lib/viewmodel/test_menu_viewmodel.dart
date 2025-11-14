import 'package:flutter/material.dart';

import '../data/repository/settings_repository.dart';
import '../data/repository/test_repository.dart';
import '../data/repository/word_repository.dart';
import '../models/test_result.dart';
import '../models/word_model.dart';

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
    await _testRepo.deleteOldTestHistory();
    await fetchTestHistory();
    await fetchDailyReviewCount();
    await fetchDifficultWords();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTestHistory() async {
    _testHistory = await _testRepo.getTestHistory();
    notifyListeners();
  }

  Future<void> fetchDailyReviewCount() async {
    final batchSize = await _settingsRepo.getBatchSize();
    _dailyReviewCount = await _wordRepo.getDailyReviewCount(batchSize);
    notifyListeners();
  }

  Future<void> fetchDifficultWords() async {
    _difficultWords = await _wordRepo.getDifficultWords();
    notifyListeners();
  }
}
