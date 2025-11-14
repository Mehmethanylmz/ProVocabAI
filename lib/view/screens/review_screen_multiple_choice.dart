import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/word_model.dart';
import '../../viewmodel/review_viewmodel.dart';
import 'test_result_screen.dart';

class ReviewScreenMultipleChoice extends StatefulWidget {
  const ReviewScreenMultipleChoice({super.key});

  @override
  State<ReviewScreenMultipleChoice> createState() =>
      _ReviewScreenMultipleChoiceState();
}

class _ReviewScreenMultipleChoiceState
    extends State<ReviewScreenMultipleChoice> {
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
    final viewModel = context.read<ReviewViewModel>();
    if (viewModel.reviewQueue.isEmpty) {
      await _finishTestAndNavigate();
      return;
    }

    final word = viewModel.currentReviewWord;
    if (word == null) {
      await _finishTestAndNavigate();
      return;
    }

    final decoys = await viewModel.getDecoys(word.tr, 3);

    final options = [word.tr, ...decoys];
    options.shuffle(Random());
    final correctIndex = options.indexOf(word.tr);

    if (!mounted) return;

    setState(() {
      _currentWord = word;
      _options = options;
      _correctOptionIndex = correctIndex;
      _showFeedback = false;
      _selectedOptionIndex = null;
    });

    if (mounted && viewModel.autoPlaySound) {
      _speak(word.en);
    }
  }

  void _checkAnswer(int selectedIndex) {
    if (_showFeedback) return;

    final viewModel = context.read<ReviewViewModel>();
    final word = _currentWord!;
    bool isCorrect = (selectedIndex == _correctOptionIndex);

    if (isCorrect) {
      viewModel.answerCorrectly(word);
    } else {
      viewModel.answerIncorrectly(word);
    }

    setState(() {
      _showFeedback = true;
      _selectedOptionIndex = selectedIndex;
    });
  }

  void _passQuestion() {
    if (_showFeedback) return;

    setState(() {
      _showFeedback = true;
      _selectedOptionIndex = null;
    });

    context.read<ReviewViewModel>().answerIncorrectly(_currentWord!);
  }

  void _nextWord() async {
    if (context.read<ReviewViewModel>().reviewQueue.isEmpty) {
      await _finishTestAndNavigate();
    } else {
      _loadNextWord();
    }
  }

  Future<void> _finishTestAndNavigate() async {
    final viewModel = context.read<ReviewViewModel>();

    final int correct = viewModel.correctCount;
    final int incorrect = viewModel.incorrectCount;
    final List<Word> wrongWords = List.from(viewModel.wrongAnswersInSession);

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final fontSizeWord = isSmallScreen ? 28.0 : 36.0;
    final buttonHeight = isSmallScreen ? 50.0 : 60.0;
    final padding = isSmallScreen ? EdgeInsets.all(16.0) : EdgeInsets.all(24.0);

    return Consumer<ReviewViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading || _currentWord == null) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.blue[700]),
            ),
          );
        }

        final currentWord = _currentWord!;
        String progress =
            "${viewModel.totalWordsInReview - viewModel.reviewQueue.length + 1} / ${viewModel.totalWordsInReview}";
        if (viewModel.totalWordsInReview == 0) progress = "0 / 0";

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Test Ekranı ($progress)',
              style: TextStyle(fontSize: isSmallScreen ? 18 : 24),
            ),
            backgroundColor: Colors.blue[700],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(30.0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Kalan: ${viewModel.reviewQueue.length} | Doğru: ${viewModel.correctCount} | Yanlış: ${viewModel.incorrectCount}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: padding,
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
                        style: TextStyle(
                          fontSize: fontSizeWord,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 400.ms),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.volume_up,
                        color: Colors.green[600],
                        size: isSmallScreen ? 28 : 36,
                      ),
                      onPressed: () => _speak(currentWord.en),
                    ),
                  ],
                ),
                SizedBox(height: 50),
                ..._options.mapIndexed((index, option) {
                  return _buildOptionButton(
                        context,
                        option,
                        index,
                        buttonHeight,
                        isSmallScreen,
                      )
                      .animate(delay: (index * 150).ms)
                      .scale(curve: Curves.easeOut);
                }).toList(),
                SizedBox(height: 30),
                if (!_showFeedback)
                  TextButton(
                    onPressed: _passQuestion,
                    child: Text(
                      'Pas Geç',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: isSmallScreen ? 16 : 20,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _nextWord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Sonraki Kelime',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 20,
                        color: Colors.white,
                      ),
                    ),
                  ).animate().shake(duration: 300.ms),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String option,
    int index,
    double buttonHeight,
    bool isSmallScreen,
  ) {
    Color buttonColor = Colors.white;
    Color textColor = Colors.black;

    if (_showFeedback) {
      if (index == _correctOptionIndex) {
        buttonColor = Colors.green[600]!;
        textColor = Colors.white;
      } else if (index == _selectedOptionIndex) {
        buttonColor = Colors.red[600]!;
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
          minimumSize: Size(double.infinity, buttonHeight),
          elevation: _showFeedback ? 0 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: _showFeedback ? Colors.transparent : Colors.grey[300]!,
              width: 2,
            ),
          ),
        ),
        onPressed: () => _checkAnswer(index),
        child: Text(
          option,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
