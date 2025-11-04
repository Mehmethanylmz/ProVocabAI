// lib/providers/word_provider.dart
import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/database_helper.dart';
import '../services/settings_service.dart';
import 'dart:math'; // Karıştırma için eklendi

class WordProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SettingsService _settingsService = SettingsService();

  List<Word> _currentBatch = []; // Orijinal öğrenme grubu (50 kelime)
  List<Word> _reviewQueue = []; // Test için kullanılacak, değişen liste

  int _batchSize = 20;
  int _unlearnedCount = 0;
  bool _isLoading = false;

  int _correctCount = 0;
  int _incorrectCount = 0;

  // --- Getters ---
  List<Word> get currentBatch => _currentBatch;
  int get batchSize => _batchSize;
  int get unlearnedCount => _unlearnedCount;
  bool get isLoading => _isLoading;

  // Test ekranı için yeni getter'lar
  List<Word> get reviewQueue => _reviewQueue;
  int get correctCount => _correctCount;
  int get incorrectCount => _incorrectCount;
  int get totalWordsInBatch => _currentBatch.length;
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

    _isLoading = false;
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
    _unlearnedCount = await _dbHelper.getUnlearnedWordCount();
    _currentBatch.shuffle(); // Öğrenme ekranı için karıştır

    _isLoading = false;
    notifyListeners();
  }

  // YENİ: Testi başlatmak için
  void startReview() {
    _reviewQueue = List.from(_currentBatch); // Ana grubu kopyala
    _reviewQueue.shuffle(Random()); // Test listesini karıştır
    _correctCount = 0;
    _incorrectCount = 0;
    notifyListeners();
  }

  // YENİ: Cevap doğruysa
  void answerCorrectly() {
    if (_reviewQueue.isEmpty) return;
    _correctCount++;
    _reviewQueue.removeAt(0); // Kelimeyi listeden çıkar
    notifyListeners();
  }

  // YENİ: Cevap yanlışsa
  void answerIncorrectly() {
    if (_reviewQueue.isEmpty) return;
    _incorrectCount++;
    // Kelimeyi al, listeden çıkar ve SONA EKLE
    Word wrongWord = _reviewQueue.removeAt(0);
    _reviewQueue.add(wrongWord);
    notifyListeners();
  }

  Future<void> completeCurrentBatch() async {
    await _dbHelper.markCurrentBatchAsLearned();
    _currentBatch = [];
    _reviewQueue = [];
    _correctCount = 0;
    _incorrectCount = 0;
    notifyListeners();
  }
}
