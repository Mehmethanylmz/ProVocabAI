// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\screens\review_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/string_helper.dart';
import '../providers/word_provider.dart';
import '../models/word_model.dart';
import '../services/sound_service.dart';
import 'test_result_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final TextEditingController _textController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  final SoundService _soundService = SoundService();

  bool _showFeedback = false;
  bool _isCorrect = false;
  bool _isPerfect = false;
  String _userInput = "";
  Word? _wordBeingAnswered;
  bool _isPassed = false;

  @override
  void initState() {
    super.initState();
    _setupTts();
    final provider = Provider.of<WordProvider>(context, listen: false);
    _wordBeingAnswered = provider.currentReviewWord;
    _autoPlaySound(provider.autoPlaySound);
  }

  void _setupTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _autoPlaySound(bool autoPlay) {
    if (autoPlay && _wordBeingAnswered != null) {
      _speak(_wordBeingAnswered!.en);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _checkAnswer() {
    if (_wordBeingAnswered == null) return;

    final String userInput = _textController.text.trim().toLowerCase();
    final String correctAnswer = _wordBeingAnswered!.tr.toLowerCase();

    if (userInput.isEmpty) return;

    final String normalizedInput = normalizeTurkish(userInput);
    final String normalizedCorrect = normalizeTurkish(correctAnswer);

    bool isPerfect = (userInput == correctAnswer);
    bool isNormalizedCorrect = (normalizedInput == normalizedCorrect);

    bool isTypoCorrect = false;
    if (!isPerfect && !isNormalizedCorrect) {
      int distance = levenshtein(normalizedInput, normalizedCorrect);

      int threshold = 0;
      if (normalizedCorrect.length > 3) {
        threshold = 1;
      }

      isTypoCorrect = (distance <= threshold);
    }

    bool finalCorrectness = isPerfect || isNormalizedCorrect || isTypoCorrect;

    if (finalCorrectness) {
      _soundService.playCorrect();
    } else {
      _soundService.playIncorrect();
    }

    setState(() {
      _showFeedback = true;
      _userInput = _textController.text.trim();
      _isPerfect = isPerfect;
      _isCorrect = finalCorrectness;
      _isPassed = false;
    });
  }

  void _passQuestion() {
    if (_wordBeingAnswered == null) return;
    _textController.clear();
    _soundService.playIncorrect();
    setState(() {
      _showFeedback = true;
      _isCorrect = false;
      _isPerfect = false;
      _isPassed = true;
      _userInput = "";
    });
  }

  Future<void> _finishTestAndNavigate() async {
    final provider = Provider.of<WordProvider>(context, listen: false);

    final int correct = provider.correctCount;
    final int incorrect = provider.incorrectCount;
    final int total = correct + incorrect;
    final List<Word> wrongWords = List.from(provider.wrongAnswersInSession);

    await provider.saveTestResult(correct, total);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TestResultScreen(
          correctCount: correct,
          incorrectCount: incorrect,
          wrongWords: wrongWords,
        ),
      ),
    );
  }

  void _nextWord() async {
    final provider = Provider.of<WordProvider>(context, listen: false);
    final word = _wordBeingAnswered!;

    if (_isCorrect) {
      provider.answerCorrectly(word);
    } else {
      provider.answerIncorrectly(word);
    }

    if (provider.reviewQueue.isEmpty) {
      await _finishTestAndNavigate();
    } else {
      setState(() {
        _textController.clear();
        _showFeedback = false;
        _isCorrect = false;
        _isPerfect = false;
        _userInput = "";
        _isPassed = false;
        _wordBeingAnswered = provider.currentReviewWord;
      });
      _autoPlaySound(provider.autoPlaySound);
    }
  }

  @override
  Widget build(BuildContext buildContext) {
    return Consumer<WordProvider>(
      builder: (context, provider, child) {
        final currentWord = provider.currentReviewWord;

        if (provider.isLoading) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (currentWord == null) {
          return Scaffold(
            appBar: AppBar(title: Text("Test Bitti")),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Tebrikler, test tamamlandı!'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    child: Text('Ana Ekrana Dön'),
                  ),
                ],
              ),
            ),
          );
        }
        String progress =
            "${provider.totalWordsInReview - provider.reviewQueue.length + 1} / ${provider.totalWordsInReview}";
        if (provider.totalWordsInReview == 0) {
          progress = "0 / 0";
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Test Ekranı ($progress)'),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(30.0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Kalan: ${provider.reviewQueue.length} | Doğru: ${provider.correctCount} | Yanlış: ${provider.incorrectCount}',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        currentWord.en,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.volume_up,
                        color: Colors.blueAccent,
                        size: 30,
                      ),
                      onPressed: () => _speak(currentWord.en),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                TextField(
                  controller: _textController,
                  readOnly: _showFeedback,
                  decoration: InputDecoration(
                    labelText: 'Türkçe karşılığını yaz...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {
                    if (!_showFeedback) _checkAnswer();
                  },
                ),
                SizedBox(height: 20),
                if (!_showFeedback)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: _passQuestion,
                        child: Text(
                          'Pas Geç',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _checkAnswer,
                        child: Text(
                          'Kontrol Et',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: _nextWord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCorrect
                          ? (_isPerfect ? Colors.green : Colors.orange)
                          : Colors.red,
                    ),
                    child: Text(
                      'Sonraki Kelime',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                SizedBox(height: 30),
                if (_showFeedback)
                  Container(
                    padding: EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isCorrect
                          ? (_isPerfect
                                ? Colors.green.shade50
                                : Colors.orange.shade50)
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isCorrect
                            ? (_isPerfect ? Colors.green : Colors.orange)
                            : Colors.red,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isCorrect
                              ? 'Doğru!'
                              : (_isPassed ? 'Pas Geçildi' : 'Yanlış!'),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: _isCorrect
                                    ? (_isPerfect
                                          ? Colors.green[800]
                                          : Colors.orange[800])
                                    : Colors.red[800],
                              ),
                        ),
                        SizedBox(height: 10),
                        if (!_isPerfect && !_isPassed && _userInput.isNotEmpty)
                          Text(
                            'Yazdığın: $_userInput',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: _isCorrect
                                      ? Colors.orange[800]
                                      : Colors.red[800],
                                  decoration: _isCorrect
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                          ),
                        Text(
                          'Doğru Cevap: ${currentWord.tr}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: _isPerfect
                                    ? Colors.black87
                                    : Colors.green[800],
                                fontWeight: _isPerfect
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                        ),
                        if (_isCorrect && !_isPerfect)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '(Yazım hatası kabul edildi)',
                              style: TextStyle(color: Colors.orange[800]),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
