import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../models/dashboard_stats.dart';
import '../services/database_helper.dart';
import '../services/settings_service.dart';
import 'dart:math';

class WordProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SettingsService _settingsService = SettingsService();

  List<Word> _currentBatch = [];
  List<Word> _reviewQueue = [];
  List<BatchHistory> _batchHistory = [];
  int? _currentTestingBatchId;

  DashboardStats? _stats;
  List<int> _weeklyEffort = [];

  int _batchSize = 20;
  int _unlearnedCount = 0;
  bool _isLoading = false;

  int _correctCount = 0;
  int _incorrectCount = 0;
  int _totalReviewCount = 0;

  List<Word> get currentBatch => _currentBatch;
  int get batchSize => _batchSize;
  int get unlearnedCount => _unlearnedCount;
  bool get isLoading => _isLoading;
  List<Word> get reviewQueue => _reviewQueue;
  List<BatchHistory> get batchHistory => _batchHistory;
  int get correctCount => _correctCount;
  int get incorrectCount => _incorrectCount;
  int get totalWordsInReview => _totalReviewCount;
  int? get currentTestingBatchId => _currentTestingBatchId;
  DashboardStats? get stats => _stats;
  List<int> get weeklyEffort => _weeklyEffort;

  Word? get currentReviewWord =>
      _reviewQueue.isNotEmpty ? _reviewQueue.first : null;

  WordProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    _batchSize = await _settingsService.getBatchSize();
    _unlearnedCount = await _dbHelper.getUnlearnedWordCount();
    await fetchDashboardStats();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDashboardStats() async {
    _stats = await _dbHelper.getDashboardStats();
    _weeklyEffort = await _dbHelper.getWeeklyEffort();
    notifyListeners();
  }

  void updateBatchSizeLocal(int newSize) {
    _batchSize = newSize;
    notifyListeners();
  }

  Future<void> updateBatchSize(int newSize) async {
    _batchSize = newSize;
    await _settingsService.saveBatchSize(newSize);
    notifyListeners();
  }

  Future<void> fetchNewBatch() async {
    _isLoading = true;
    notifyListeners();
    _currentBatch = await _dbHelper.getNewWordBatch(_batchSize);
    _reviewQueue = [];
    _correctCount = 0;
    _incorrectCount = 0;
    _totalReviewCount = 0;
    _currentTestingBatchId = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchBatchHistory() async {
    _isLoading = true;
    notifyListeners();
    _batchHistory = await _dbHelper.getBatchHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> startReview({
    required String testMode,
    int? batchId,
    int? randomCount,
  }) async {
    _isLoading = true;
    notifyListeners();
    _reviewQueue = [];
    _currentTestingBatchId = null;
    switch (testMode) {
      case 'current':
        _reviewQueue = List.from(_currentBatch);
        _currentTestingBatchId = null;
        break;
      case 'all_learned':
        _reviewQueue = await _dbHelper.getAllLearnedWords();
        break;
      case 'specific_batch':
        if (batchId != null) {
          _reviewQueue = await _dbHelper.getBatchByBatchId(batchId);
          _currentTestingBatchId = batchId;
        }
        break;
      case 'random_learned':
        if (randomCount != null) {
          _reviewQueue = await _dbHelper.getRandomLearnedWords(randomCount);
        }
        break;
    }
    _reviewQueue.shuffle(Random());
    _totalReviewCount = _reviewQueue.length;
    _correctCount = 0;
    _incorrectCount = 0;
    _isLoading = false;
    notifyListeners();
  }

  void answerCorrectly() {
    if (_reviewQueue.isEmpty) return;
    _correctCount++;
    _reviewQueue.removeAt(0);
    notifyListeners();
  }

  void answerIncorrectly() {
    if (_reviewQueue.isEmpty) return;
    _incorrectCount++;
    _reviewQueue.removeAt(0);
    notifyListeners();
  }

  Future<int> completeCurrentBatchAndGetId() async {
    final newBatchId = await _dbHelper.markBatchAsLearned(_currentBatch);
    _currentBatch = [];
    _reviewQueue = [];
    _correctCount = 0;
    _incorrectCount = 0;
    _totalReviewCount = 0;
    _unlearnedCount = await _dbHelper.getUnlearnedWordCount();
    return newBatchId;
  }

  Future<void> saveTestResult(int correct, int total) async {
    int batchIdToSave;
    if (_currentTestingBatchId != null) {
      batchIdToSave = _currentTestingBatchId!;
    } else {
      batchIdToSave = await completeCurrentBatchAndGetId();
    }
    if (total > 0) {
      await _dbHelper.insertBatchScore(batchIdToSave, correct, total);
    }
    await fetchBatchHistory();
    await fetchDashboardStats();
    _unlearnedCount = await _dbHelper.getUnlearnedWordCount();
    notifyListeners();
  }
}
