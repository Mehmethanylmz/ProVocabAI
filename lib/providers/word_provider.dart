// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\providers\word_provider.dart

import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../models/dashboard_stats.dart';
import '../services/database_helper.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import 'dart:math';

class WordProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SettingsService _settingsService = SettingsService();

  List<Word> _currentBatch = [];
  List<Word> _reviewQueue = [];
  List<BatchHistory> _batchHistory = [];
  List<Word> _userWords = [];
  int? _currentTestingBatchId;

  DashboardStats? _stats;
  List<int> _weeklyEffort = [];
  int _difficultWordCount = 0;

  int _batchSize = 20;
  TimeOfDay _notificationTime = TimeOfDay(hour: 20, minute: 0);
  bool _autoPlaySound = true;
  int _unlearnedCount = 0;
  bool _isLoading = false;

  int _correctCount = 0;
  int _incorrectCount = 0;
  int _totalReviewCount = 0;

  List<Word> get currentBatch => _currentBatch;
  int get batchSize => _batchSize;
  TimeOfDay get notificationTime => _notificationTime;
  bool get autoPlaySound => _autoPlaySound;
  int get unlearnedCount => _unlearnedCount;
  bool get isLoading => _isLoading;
  List<Word> get reviewQueue => _reviewQueue;
  List<BatchHistory> get batchHistory => _batchHistory;
  List<Word> get userWords => _userWords;
  int get correctCount => _correctCount;
  int get incorrectCount => _incorrectCount;
  int get totalWordsInReview => _totalReviewCount;
  int? get currentTestingBatchId => _currentTestingBatchId;
  DashboardStats? get stats => _stats;
  List<int> get weeklyEffort => _weeklyEffort;
  int get difficultWordCount => _difficultWordCount;

  Word? get currentReviewWord =>
      _reviewQueue.isNotEmpty ? _reviewQueue.first : null;

  WordProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    _batchSize = await _settingsService.getBatchSize();
    _notificationTime = await _settingsService.getNotificationTime();
    _autoPlaySound = await _settingsService.getAutoPlaySound();
    _unlearnedCount = await _dbHelper.getUnlearnedWordCount();
    await fetchDashboardStats();
    NotificationService.scheduleDailyNotification(
      _batchSize,
      _notificationTime,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDashboardStats() async {
    _stats = await _dbHelper.getDashboardStats();
    _weeklyEffort = await _dbHelper.getWeeklyEffort();
    _difficultWordCount = await _dbHelper.getDifficultWordCount();
    notifyListeners();
  }

  Future<void> updateNotificationTime(TimeOfDay newTime) async {
    _notificationTime = newTime;
    await _settingsService.saveNotificationTime(newTime);
    NotificationService.scheduleDailyNotification(_batchSize, newTime);
    notifyListeners();
  }

  Future<void> updateBatchSize(int newSize) async {
    _batchSize = newSize;
    await _settingsService.saveBatchSize(newSize);
    NotificationService.scheduleDailyNotification(newSize, _notificationTime);
    notifyListeners();
  }

  Future<void> updateAutoPlaySound(bool newValue) async {
    _autoPlaySound = newValue;
    await _settingsService.saveAutoPlaySound(newValue);
    notifyListeners();
  }

  Future<void> addOrUpdateWord(Word word) async {
    await _dbHelper.insertWord(word);
    await fetchUserWords();
    await fetchDashboardStats();
    _unlearnedCount = await _dbHelper.getUnlearnedWordCount();
    notifyListeners();
  }

  Future<void> deleteWord(int id) async {
    await _dbHelper.deleteWord(id);
    await fetchUserWords();
    await fetchDashboardStats();
    _unlearnedCount = await _dbHelper.getUnlearnedWordCount();
    notifyListeners();
  }

  Future<void> fetchUserWords() async {
    _isLoading = true;
    notifyListeners();
    _userWords = await _dbHelper.getUserWords();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDailySession() async {
    _isLoading = true;
    notifyListeners();

    _currentBatch = await _dbHelper.getDailySession(_batchSize);

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

  Future<List<String>> getDecoys(String correctTr, int count) async {
    return await _dbHelper.getDecoyWords(correctTr, count);
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
      case 'difficult':
        _reviewQueue = await _dbHelper.getDifficultWords();
        break;
    }

    _reviewQueue.shuffle(Random());
    _totalReviewCount = _reviewQueue.length;
    _correctCount = 0;
    _incorrectCount = 0;
    _isLoading = false;
    notifyListeners();
  }

  void answerCorrectly(Word word) {
    if (_reviewQueue.isEmpty) return;
    _correctCount++;
    _reviewQueue.removeAt(0);
    _dbHelper.updateWordMastery(word, true);
    notifyListeners();
  }

  void answerIncorrectly(Word word) {
    if (_reviewQueue.isEmpty) return;
    _incorrectCount++;
    _reviewQueue.removeAt(0);
    _dbHelper.updateWordMastery(word, false);
    notifyListeners();
  }

  Future<int> _assignBatchIdToNewSession() async {
    final newBatchId = await _dbHelper.getNewBatchId();
    await _dbHelper.assignBatchIdToNewWords(_currentBatch, newBatchId);

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
    bool isNewSession;

    if (_currentTestingBatchId != null) {
      batchIdToSave = _currentTestingBatchId!;
      isNewSession = false;
    } else {
      batchIdToSave = await _assignBatchIdToNewSession();
      isNewSession = true;
    }

    if (total > 0) {
      await _dbHelper.insertBatchScore(
        batchIdToSave,
        correct,
        total,
        isNewSession,
      );
    }

    await fetchBatchHistory();
    await fetchDashboardStats();
    _unlearnedCount = await _dbHelper.getUnlearnedWordCount();

    notifyListeners();
  }
}
