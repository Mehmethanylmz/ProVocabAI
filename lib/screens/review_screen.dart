// lib/screens/review_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/word_provider.dart';
import '../models/word_model.dart';

class ReviewScreen extends StatefulWidget {
  // Artık parametre almıyor
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final TextEditingController _textController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();

  bool _showFeedback = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _setupTts();
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

  // Cevabı kontrol et ve provider'ı güncelle
  void _checkAnswer(WordProvider provider, Word currentWord) {
    setState(() {
      _showFeedback = true;
      _isCorrect =
          _textController.text.trim().toLowerCase() ==
          currentWord.tr.toLowerCase();
    });

    if (_isCorrect) {
      provider.answerCorrectly();
    } else {
      provider.answerIncorrectly();
    }
  }

  // Sonraki kelimeye geç
  void _nextWord() {
    // Provider'ı 'dinlemeden' alıyoruz, çünkü sadece state'i sıfırlayacağız
    final provider = Provider.of<WordProvider>(context, listen: false);

    // Test bittiyse (Test listesi boşaldıysa)
    if (provider.currentReviewWord == null) {
      showDialog(
        context: context,
        barrierDismissible: false, // Dışarı tıklayarak kapatmayı engelle
        builder: (ctx) => AlertDialog(
          title: Text('Test Bitti! Mükemmel!'),
          content: Text(
            'Bu gruptaki tüm kelimeleri doğru bildin. Artık bu grubu bitirebilir veya tekrar test edebilirsin.',
          ),
          actions: [
            TextButton(
              child: Text('Tamam'),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Test ekranını kapat
              },
            ),
          ],
        ),
      );
    } else {
      // Test devam ediyorsa, arayüzü sıfırla
      setState(() {
        _textController.clear();
        _showFeedback = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekranın tamamı artık Provider'a bağlı
    return Consumer<WordProvider>(
      builder: (context, provider, child) {
        final currentWord = provider.currentReviewWord;

        // currentWord null ise (yani _reviewQueue boşsa) test bitmiştir.
        // Bu durum _nextWord içinde yakalanır, ancak build anında da olabilir.
        if (currentWord == null) {
          // Normalde _nextWord içinde yakalanır, ama güvenlik için burada
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Test Tamamlandı!')),
          );
        }

        // Kalan kelime / Toplam kelime (örn: 5/50)
        String progress =
            "${provider.totalWordsInBatch - provider.reviewQueue.length + 1} / ${provider.totalWordsInBatch}";

        return Scaffold(
          appBar: AppBar(
            title: Text('Test Ekranı ($progress)'),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(30.0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Doğru: ${provider.correctCount} | Yanlış: ${provider.incorrectCount}',
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
                    if (!_showFeedback) _checkAnswer(provider, currentWord);
                  },
                ),
                SizedBox(height: 20),

                if (!_showFeedback)
                  ElevatedButton(
                    onPressed: () => _checkAnswer(provider, currentWord),
                    child: Text('Kontrol Et'),
                  )
                else
                  ElevatedButton(
                    onPressed: _nextWord,
                    child: Text('Sonraki Kelime'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCorrect ? Colors.green : Colors.red,
                    ),
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
                              '(Bu kelime tekrar sorulacak)',
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
