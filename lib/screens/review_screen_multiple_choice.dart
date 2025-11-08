// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\screens\review_screen_multiple_choice.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/word_provider.dart';
import '../models/word_model.dart';
import '../services/sound_service.dart';

class ReviewScreenMultipleChoice extends StatefulWidget {
  const ReviewScreenMultipleChoice({super.key});

  @override
  State<ReviewScreenMultipleChoice> createState() =>
      _ReviewScreenMultipleChoiceState();
}

class _ReviewScreenMultipleChoiceState
    extends State<ReviewScreenMultipleChoice> {
  final SoundService _soundService = SoundService();
  final FlutterTts flutterTts = FlutterTts();

  bool _showFeedback = false;
  int? _selectedOptionIndex;
  int _correctOptionIndex = 0;
  List<String> _options = [];
  Word? _currentWord;

  @override
  void initState() {
    super.initState();
    _setupTts();
    _loadNextWord();
  }

  void _setupTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadNextWord() async {
    final provider = Provider.of<WordProvider>(context, listen: false);
    if (provider.reviewQueue.isEmpty) {
      _showTestEndDialog();
      return;
    }

    final word = provider.currentReviewWord;
    if (word == null) {
      _showTestEndDialog();
      return;
    }

    final decoys = await provider.getDecoys(word.tr, 3);
    final options = [word.tr, ...decoys];
    options.shuffle(Random());
    final correctIndex = options.indexOf(word.tr);

    setState(() {
      _currentWord = word;
      _options = options;
      _correctOptionIndex = correctIndex;
      _showFeedback = false;
      _selectedOptionIndex = null;
    });

    if (mounted && provider.autoPlaySound) {
      _speak(word.en);
    }
  }

  void _checkAnswer(int selectedIndex) {
    if (_showFeedback) return;

    final provider = Provider.of<WordProvider>(context, listen: false);
    final word = _currentWord!;
    bool isCorrect = (selectedIndex == _correctOptionIndex);

    if (isCorrect) {
      _soundService.playCorrect();
      provider.answerCorrectly(word);
    } else {
      _soundService.playIncorrect();
      provider.answerIncorrectly(word);
    }

    setState(() {
      _showFeedback = true;
      _selectedOptionIndex = selectedIndex;
    });
  }

  void _passQuestion() {
    if (_showFeedback) return;
    _soundService.playIncorrect();

    setState(() {
      _showFeedback = true;
      _selectedOptionIndex = null;
    });

    final provider = Provider.of<WordProvider>(context, listen: false);
    provider.answerIncorrectly(_currentWord!);
  }

  void _nextWord() {
    if (Provider.of<WordProvider>(context, listen: false).reviewQueue.isEmpty) {
      _showTestEndDialog();
    } else {
      _loadNextWord();
    }
  }

  void _showTestEndDialog() {
    final provider = Provider.of<WordProvider>(context, listen: false);
    final int correct = provider.correctCount;
    final int incorrect = provider.incorrectCount;
    final int total = correct + incorrect;
    final double successRateNum = (total == 0) ? 0 : (correct / total) * 100;
    final String successRate = successRateNum.toStringAsFixed(0);
    final String dialogTitle;
    final String buttonText;
    if (successRateNum >= 80) {
      dialogTitle = 'Harika İş!';
      buttonText = 'Süper!';
    } else if (successRateNum >= 50) {
      dialogTitle = 'İyi Gidiyorsun!';
      buttonText = 'Devam Et';
    } else {
      dialogTitle = 'Test Bitti';
      buttonText = 'Tamam';
    }

    provider.saveTestResult(correct, total);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(
          'Bu turu tamamladın.\n\n'
          'Başarı Oranı: %$successRate\n'
          'Doğru: $correct\n'
          'Yanlış: $incorrect\n\n'
          'Skorun kaydedildi.',
        ),
        actions: [
          TextButton(
            child: Text(buttonText),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WordProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading || _currentWord == null) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final currentWord = _currentWord!;
        String progress =
            "${provider.totalWordsInReview - provider.reviewQueue.length + 1} / ${provider.totalWordsInReview}";
        if (provider.totalWordsInReview == 0) progress = "0 / 0";

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
                SizedBox(height: 50),
                ..._options.mapIndexed((index, option) {
                  return _buildOptionButton(context, option, index);
                }).toList(),
                SizedBox(height: 30),
                if (!_showFeedback)
                  TextButton(
                    onPressed: _passQuestion,
                    child: Text(
                      'Pas Geç',
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _nextWord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: Text(
                      'Sonraki Kelime',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton(BuildContext context, String option, int index) {
    Color buttonColor = Colors.white;
    Color textColor = Colors.black;

    if (_showFeedback) {
      if (index == _correctOptionIndex) {
        buttonColor = Colors.green;
        textColor = Colors.white;
      } else if (index == _selectedOptionIndex) {
        buttonColor = Colors.red;
        textColor = Colors.white;
      } else {
        buttonColor = Colors.grey[200]!;
        textColor = Colors.grey[600]!;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          minimumSize: Size(double.infinity, 60),
          elevation: _showFeedback ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _showFeedback ? Colors.transparent : Colors.grey[300]!,
            ),
          ),
        ),
        onPressed: () => _checkAnswer(index),
        child: Text(
          option,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
