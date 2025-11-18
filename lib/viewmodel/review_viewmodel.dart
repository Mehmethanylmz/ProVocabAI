import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/models/word_model.dart';
import '../data/models/test_result.dart';
import '../data/repositories/word_repository.dart';
import '../data/repositories/test_repository.dart';
import '../data/repositories/stats_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/speech_service.dart'; // SpeechService eklendi

// İşlemin sonucunu belirten durumlar (SRP için kritik)
enum ReviewStatus { success, empty, error }

class ReviewViewModel with ChangeNotifier {
  final WordRepository _wordRepo = WordRepository();
  final TestRepository _testRepo = TestRepository();
  final StatsRepository _statsRepo = StatsRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  final TtsService _ttsService = TtsService();
  final SpeechService _speechService = SpeechService(); // Yeni servis

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _autoPlaySound = true;
  bool get autoPlaySound => _autoPlaySound;

  String _sourceLang = 'tr';
  String _targetLang = 'en';
  String _proficiencyLevel = 'beginner';

  String get sourceLang => _sourceLang;
  String get targetLang => _targetLang;
  String get proficiencyLevel => _proficiencyLevel;

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
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Speech (Konuşma) State'leri
  bool _isListening = false;
  bool get isListening => _isListening;
  String _spokenText = "";
  String get spokenText => _spokenText;

  Word? get currentReviewWord =>
      _reviewQueue.isNotEmpty ? _reviewQueue.first : null;

  ReviewViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final langs = await _settingsRepo.getLanguageSettings();
    _sourceLang = langs['source']!;
    _targetLang = langs['target']!;
    _proficiencyLevel = langs['level']!;
    _autoPlaySound = await _settingsRepo.getAutoPlaySound();
    notifyListeners();
  }

  // --- TTS (Seslendirme) İşlemleri ---
  Future<void> speakCurrentWord() async {
    final word = currentReviewWord;
    if (word != null) {
      final content = word.getLocalizedContent(_targetLang);
      await _ttsService.speak(content['word'] ?? '', _targetLang);
    }
  }

  Future<void> speakText(String text, String lang) async {
    await _ttsService.speak(text, lang);
  }

  // --- Speech (Konuşma Algılama) İşlemleri ---
  Future<void> startListeningForSpeech() async {
    final word = currentReviewWord;
    if (word == null) return;

    String localeId = _targetLang;
    // Basit locale mapping
    if (_targetLang == 'en') localeId = 'en-US';
    if (_targetLang == 'tr') localeId = 'tr-TR';
    if (_targetLang == 'es') localeId = 'es-ES';
    if (_targetLang == 'de') localeId = 'de-DE';
    if (_targetLang == 'fr') localeId = 'fr-FR';

    _isListening = true;
    _spokenText = "";
    notifyListeners();

    await _speechService.startListening(
      localeId: localeId,
      onResult: (result) {
        _spokenText = result;
        notifyListeners();
      },
    );
  }

  Future<void> stopListeningForSpeech() async {
    await _speechService.stopListening();
    _isListening = false;
    notifyListeners();
  }

  // Metin Cevap Kontrolü (Listening & Speaking Testi İçin)
  bool checkTextAnswer(String userAnswer) {
    final word = currentReviewWord;
    if (word == null) return false;

    final targetContent = word.getLocalizedContent(_targetLang);
    final correctWord = targetContent['word'] ?? '';

    final normalizedUser =
        userAnswer.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final normalizedCorrect =
        correctWord.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    return normalizedUser == normalizedCorrect;
  }

  // --- Test Başlatma Mantığı (GÜNCELLENDİ: ReviewStatus dönüyor) ---
  Future<ReviewStatus> startReview(String testMode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _loadSettings();

    _reviewQueue = [];
    _correctCount = 0;
    _incorrectCount = 0;
    _wrongAnswersInSession.clear();
    _testStartTime = DateTime.now();

    try {
      if (testMode == 'daily') {
        final batchSize = await _settingsRepo.getBatchSize();
        _reviewQueue = await _wordRepo.getDailyReviewWords(
          batchSize,
          _targetLang,
        );
      } else if (testMode == 'difficult') {
        _reviewQueue = await _wordRepo.getDifficultWords(_targetLang);
      }

      _reviewQueue.shuffle(Random());
      _totalReviewCount = _reviewQueue.length;

      _isLoading = false;
      notifyListeners();

      // Logic burada: Veri durumuna göre statü dön
      if (_reviewQueue.isEmpty) {
        return ReviewStatus.empty;
      }
      return ReviewStatus.success;
    } catch (e) {
      _errorMessage = "Test başlatılamadı: $e";
      _isLoading = false;
      notifyListeners();
      return ReviewStatus.error;
    }
  }

  // Hatalı kelimeleri tekrar etme modu
  Future<void> startReviewWithWords(List<Word> words) async {
    _isLoading = true;
    notifyListeners();
    await _loadSettings();

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

  // --- Cevap Yönetimi ---
  void answerCorrectly(Word word) {
    _correctCount++;
    _reviewQueue.remove(word);
    _wordRepo.updateWordProgress(
      word.id,
      _targetLang,
      true,
      word.masteryLevel ?? 0,
      word.streak ?? 0,
    );
    notifyListeners();
  }

  void answerIncorrectly(Word word) {
    _incorrectCount++;
    if (!_wrongAnswersInSession.contains(word)) {
      _wrongAnswersInSession.add(word);
    }
    _reviewQueue.remove(word);
    _wordRepo.updateWordProgress(
      word.id,
      _targetLang,
      false,
      word.masteryLevel ?? 0,
      word.streak ?? 0,
    );
    notifyListeners();
  }

  // Şık Üretme (Çoktan seçmeli için)
  Future<List<String>> getDecoys(Word correctWord) async {
    try {
      final content = correctWord.getLocalizedContent(_sourceLang);
      final correctTranslation = content['word'] ?? "???";
      final rawCandidates = await _wordRepo.getRandomCandidates(50);
      List<String> decoys = [];

      for (var map in rawCandidates) {
        try {
          final contentJson = jsonDecode(map['content'] as String);
          if (contentJson is Map && contentJson.containsKey(_sourceLang)) {
            final word = contentJson[_sourceLang]['word'];
            if (word != null &&
                word.toString().isNotEmpty &&
                word != correctTranslation &&
                !decoys.contains(word)) {
              decoys.add(word.toString());
            }
          }
        } catch (e) {
          continue;
        }
        if (decoys.length >= 3) break;
      }
      while (decoys.length < 3) {
        decoys.add("Seçenek ${decoys.length + 1}");
      }
      return decoys;
    } catch (e) {
      return ["Hata 1", "Hata 2", "Hata 3"];
    }
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
  }
}
