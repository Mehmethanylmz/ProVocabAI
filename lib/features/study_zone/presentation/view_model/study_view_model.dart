import 'dart:convert';
import 'dart:math';
import '../../../../core/base/base_view_model.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/entities/test_result_entity.dart';
import '../../domain/repositories/i_word_repository.dart';
import '../../domain/repositories/i_test_repository.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';

enum StudyStatus { initial, loading, success, empty, error, finished }

class StudyViewModel extends BaseViewModel {
  final IWordRepository _wordRepo;
  final ITestRepository _testRepo;
  final ISettingsRepository _settingsRepo;
  final TtsService _ttsService;
  final SpeechService _speechService;

  StudyViewModel(
    this._wordRepo,
    this._testRepo,
    this._settingsRepo,
    this._ttsService,
    this._speechService,
  ) {
    _loadSettings();
  }

  // State
  StudyStatus _status = StudyStatus.initial;
  StudyStatus get status => _status;

  String _sourceLang = 'tr';
  String _targetLang = 'en';
  String _proficiencyLevel = 'beginner';
  bool _autoPlaySound = true;

  String get sourceLang => _sourceLang;
  String get targetLang => _targetLang;
  String get proficiencyLevel => _proficiencyLevel;
  bool get autoPlaySound => _autoPlaySound;

  List<WordEntity> _reviewQueue = [];
  List<WordEntity> get reviewQueue => _reviewQueue;

  final List<WordEntity> _wrongAnswersInSession = [];
  List<WordEntity> get wrongAnswersInSession => _wrongAnswersInSession;

  int _correctCount = 0;
  int get correctCount => _correctCount;
  int _incorrectCount = 0;
  int get incorrectCount => _incorrectCount;
  int _totalReviewCount = 0;
  int get totalWordsInReview => _totalReviewCount;

  DateTime? _testStartTime;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isListening = false;
  bool get isListening => _isListening;
  String _spokenText = "";
  String get spokenText => _spokenText;

  WordEntity? get currentReviewWord =>
      _reviewQueue.isNotEmpty ? _reviewQueue.first : null;

  Future<void> _loadSettings() async {
    final result = await _settingsRepo.getLanguageSettings();
    result.fold((l) {}, (r) {
      _sourceLang = r['source']!;
      _targetLang = r['target']!;
      _proficiencyLevel = r['level']!;
    });

    final soundResult = await _settingsRepo.getAutoPlaySound();
    soundResult.fold((l) {}, (r) => _autoPlaySound = r);
    notifyListeners();
  }

  Future<void> startReview(
    String testMode, {
    List<String>? categoryFilter,
    List<String>? grammarFilter,
  }) async {
    changeLoading(); // BaseViewModel
    _status = StudyStatus.loading;
    _errorMessage = null;
    _reviewQueue = [];
    _correctCount = 0;
    _incorrectCount = 0;
    _wrongAnswersInSession.clear();
    _testStartTime = DateTime.now();

    await _loadSettings();

    final selectedCategories = categoryFilter ?? ['all'];
    final selectedGrammar = grammarFilter ?? ['all'];

    int batchSize = 10;
    final batchResult = await _settingsRepo.getBatchSize();
    batchResult.fold((l) {}, (r) => batchSize = r);

    final result = await _wordRepo.getFilteredWords(
      targetLang: _targetLang,
      categories: selectedCategories,
      grammar: selectedGrammar,
      mode: testMode,
      batchSize: batchSize,
    );

    result.fold(
      (failure) {
        _errorMessage = "Test error: ${failure.message}";
        _status = StudyStatus.error;
      },
      (words) {
        _reviewQueue = List.from(words);
        // Boş içerik temizliği
        _reviewQueue.removeWhere((word) {
          final content = word.getLocalizedContent(_targetLang);
          return (content['word'] ?? '').trim().isEmpty;
        });

        _reviewQueue.shuffle(Random());
        _totalReviewCount = _reviewQueue.length;

        if (_reviewQueue.isEmpty) {
          _status = StudyStatus.empty;
        } else {
          _status = StudyStatus.success;
        }
      },
    );

    changeLoading(); // Loading false
    notifyListeners();
  }

  Future<void> startReviewWithWords(List<WordEntity> words) async {
    changeLoading();
    await _loadSettings();

    _reviewQueue = List.from(words);
    _reviewQueue.removeWhere((word) {
      final content = word.getLocalizedContent(_targetLang);
      return (content['word'] ?? '').trim().isEmpty;
    });

    _reviewQueue.shuffle(Random());
    _wrongAnswersInSession.clear();
    _totalReviewCount = _reviewQueue.length;
    _correctCount = 0;
    _incorrectCount = 0;
    _testStartTime = DateTime.now();

    _status = StudyStatus.success;

    changeLoading();
    notifyListeners();
  }

  void answerCorrectly(WordEntity word) {
    _correctCount++;
    _reviewQueue.remove(word);
    _wordRepo.updateWordProgress(
      word.id,
      _targetLang,
      true,
      word.masteryLevel ?? 0,
      word.streak ?? 0,
    );

    if (_reviewQueue.isEmpty) {
      _status = StudyStatus.finished;
    }
    notifyListeners();
  }

  void answerIncorrectly(WordEntity word) {
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

    if (_reviewQueue.isEmpty) {
      _status = StudyStatus.finished;
    }
    notifyListeners();
  }

  Future<void> saveTestResult() async {
    final duration =
        DateTime.now().difference(_testStartTime ?? DateTime.now());
    final total = _correctCount + _incorrectCount;
    final successRate = total > 0 ? (_correctCount / total) * 100 : 0.0;

    final result = TestResultEntity(
      date: DateTime.now(),
      questions: total,
      correct: _correctCount,
      wrong: _incorrectCount,
      duration: duration,
      successRate: successRate,
    );

    await _testRepo.saveTestResult(result);
  }

  // --- TTS & Speech Helpers ---
  Future<void> speakCurrentWord() async {
    final word = currentReviewWord;
    if (word != null) {
      final content = word.getLocalizedContent(_targetLang);
      if ((content['word'] ?? '').isNotEmpty) {
        await _ttsService.speak(content['word']!, _targetLang);
      }
    }
  }

  Future<void> speakText(String text, String lang) async {
    if (text.isNotEmpty) {
      await _ttsService.speak(text, lang);
    }
  }

  Future<void> startListeningForSpeech() async {
    final word = currentReviewWord;
    if (word == null) return;
    final content = word.getLocalizedContent(_targetLang);

    if ((content['word'] ?? '').isEmpty) {
      _errorMessage = "Empty word data!";
      notifyListeners();
      return;
    }

    // Locale mapping
    String localeId = _targetLang;
    switch (_targetLang) {
      case 'en':
        localeId = 'en-US';
        break;
      case 'tr':
        localeId = 'tr-TR';
        break;
      case 'es':
        localeId = 'es-ES';
        break;
      case 'de':
        localeId = 'de-DE';
        break;
      case 'fr':
        localeId = 'fr-FR';
        break;
      case 'pt':
        localeId = 'pt-BR';
        break;
    }

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

  Future<List<String>> getDecoys(WordEntity correctWord) async {
    try {
      final content = correctWord.getLocalizedContent(_sourceLang);
      final correctTranslation = content['word'] ?? "???";

      final result = await _wordRepo.getRandomCandidates(50);
      List<String> decoys = [];

      result.fold((l) {}, (rawCandidates) {
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
      });

      while (decoys.length < 3) {
        decoys.add("Seçenek ${decoys.length + 1}");
      }
      return decoys;
    } catch (e) {
      return ["Hata 1", "Hata 2", "Hata 3"];
    }
  }
}
