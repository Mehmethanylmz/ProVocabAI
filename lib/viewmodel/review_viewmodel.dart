import 'dart:math';
import 'package:flutter/material.dart';
import '../data/repository/settings_repository.dart';
import '../data/repository/stats_repository.dart';
import '../data/repository/test_repository.dart';
import '../data/repository/word_repository.dart';
import '../models/test_result.dart';
import '../models/word_model.dart';

class ReviewViewModel with ChangeNotifier {
  final WordRepository _wordRepo = WordRepository();
  final TestRepository _testRepo = TestRepository();
  final StatsRepository _statsRepo = StatsRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _autoPlaySound = true;
  bool get autoPlaySound => _autoPlaySound;

  List<Word> _reviewQueue = [];
  List<Word> get reviewQueue => _reviewQueue;

  List<Word> _wrongAnswersInSession = [];
  List<Word> get wrongAnswersInSession => _wrongAnswersInSession;

  int _correctCount = 0;
  int get correctCount => _correctCount;

  int _incorrectCount = 0;
  int get incorrectCount => _incorrectCount;

  int _totalReviewCount = 0;
  int get totalWordsInReview => _totalReviewCount;

  DateTime? _testStartTime;

  Word? get currentReviewWord =>
      _reviewQueue.isNotEmpty ? _reviewQueue.first : null;

  ReviewViewModel() {
    _loadSettings();
  }

  void _loadSettings() async {
    _autoPlaySound = await _settingsRepo.getAutoPlaySound();
    notifyListeners();
  }

  Future<List<String>> getDecoys(String correctTr, int count) async {
    return await _wordRepo.getDecoyWords(correctTr, count);
  }

  Future<void> startReview(String testMode) async {
    _isLoading = true;
    notifyListeners();
    _reviewQueue = [];
    _correctCount = 0;
    _incorrectCount = 0;
    _wrongAnswersInSession.clear();
    _testStartTime = DateTime.now();

    if (testMode == 'daily') {
      final batchSize = await _settingsRepo.getBatchSize();
      _reviewQueue = await _wordRepo.getDailyReviewWords(batchSize);
    } else if (testMode == 'difficult') {
      _reviewQueue = await _wordRepo.getDifficultWords();
    }

    _reviewQueue.shuffle(Random());
    _totalReviewCount = _reviewQueue.length;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> startReviewWithWords(List<Word> words) async {
    _isLoading = true;
    notifyListeners();

    _reviewQueue = List.from(words);
    _reviewQueue.shuffle(Random());

    _wrongAnswersInSession.clear();
    _totalReviewCount = _reviewQueue.length;
    _correctCount = 0;
    _incorrectCount = 0;
    _testStartTime = DateTime.now();
    _isLoading = false;
    notifyListeners();
  }

  void answerCorrectly(Word word) {
    _correctCount++;
    _reviewQueue.remove(word);
    _wordRepo.updateWordMastery(word, true);
    notifyListeners();
  }

  void answerIncorrectly(Word word) {
    _incorrectCount++;
    if (!_wrongAnswersInSession.contains(word)) {
      _wrongAnswersInSession.add(word);
    }
    _reviewQueue.remove(word);
    _wordRepo.updateWordMastery(word, false);
    notifyListeners();
  }

  Future<void> saveTestResult() async {
    final duration = DateTime.now().difference(
      _testStartTime ?? DateTime.now(),
    );
    final total = _correctCount + _incorrectCount;
    final successRate = total > 0 ? (_correctCount / total) * 100 : 0.0;

    final result = TestResult(
      date: DateTime.now(),
      questions: total,
      correct: _correctCount,
      wrong: _incorrectCount,
      duration: duration,
      successRate: successRate,
    );

    await _testRepo.insertTestResult(result);
    await _statsRepo.takeProgressSnapshot();
  }
}
