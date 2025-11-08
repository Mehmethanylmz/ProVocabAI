import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/word_provider.dart';
import '../models/word_model.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final TextEditingController _textController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();

  bool _showFeedback = false;
  bool _isCorrect = false;

  Word? _wordBeingAnswered;

  @override
  void initState() {
    super.initState();
    _setupTts();
    _wordBeingAnswered = Provider.of<WordProvider>(
      context,
      listen: false,
    ).currentReviewWord;
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
    _textController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _checkAnswer() {
    if (_wordBeingAnswered == null) return;

    setState(() {
      _showFeedback = true;
      _isCorrect =
          _textController.text.trim().toLowerCase() ==
          _wordBeingAnswered!.tr.toLowerCase();
    });
  }

  void _nextWord() async {
    final provider = Provider.of<WordProvider>(context, listen: false);
    if (_isCorrect) {
      provider.answerCorrectly();
    } else {
      provider.answerIncorrectly();
    }
    if (provider.reviewQueue.isEmpty) {
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

      await provider.saveTestResult(correct, total);

      if (!context.mounted) return;

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
    } else {
      setState(() {
        _textController.clear();
        _showFeedback = false;
        _isCorrect = false;
        _wordBeingAnswered = provider.currentReviewWord;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      currentWord.en,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
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
                  ElevatedButton(
                    onPressed: _checkAnswer,
                    child: Text('Kontrol Et'),
                  )
                else
                  ElevatedButton(
                    onPressed: _nextWord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCorrect ? Colors.green : Colors.red,
                    ),
                    child: Text('Sonraki Kelime'),
                  ),
                SizedBox(height: 30),
                if (_showFeedback)
                  Container(
                    padding: EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isCorrect
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isCorrect ? 'Doğru!' : 'Yanlış!',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: _isCorrect
                                    ? Colors.green[800]
                                    : Colors.red[800],
                              ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Doğru Cevap: ${currentWord.tr}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (!_isCorrect)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Cevabın: ${_textController.text.trim()}',
                              style: TextStyle(color: Colors.red[800]),
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
