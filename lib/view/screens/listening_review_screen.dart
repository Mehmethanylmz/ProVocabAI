import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/word_model.dart';
import '../../viewmodel/review_viewmodel.dart';
import 'test_result_screen.dart';

class ListeningReviewScreen extends StatefulWidget {
  const ListeningReviewScreen({super.key});

  @override
  State<ListeningReviewScreen> createState() => _ListeningReviewScreenState();
}

class _ListeningReviewScreenState extends State<ListeningReviewScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isAnswered = false;
  bool _isCorrect = false;
  Word? _currentWord;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadNextWord();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadNextWord() async {
    final viewModel = context.read<ReviewViewModel>();

    if (viewModel.reviewQueue.isEmpty) {
      await _finishTestAndNavigate();
      return;
    }

    final word = viewModel.currentReviewWord;
    if (word == null) return;

    setState(() {
      _currentWord = word;
      _isAnswered = false;
      _controller.clear();
    });

    // Klavye otomatik açılsın
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    // Otomatik okuma
    viewModel.speakCurrentWord();
  }

  void _checkAnswer() {
    if (_isAnswered) return;
    final viewModel = context.read<ReviewViewModel>();
    final isCorrect = viewModel.checkTextAnswer(_controller.text);

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      viewModel.answerCorrectly(_currentWord!);
    } else {
      viewModel.answerIncorrectly(_currentWord!);
    }
  }

  Future<void> _finishTestAndNavigate() async {
    if (!mounted) return;
    final viewModel = context.read<ReviewViewModel>();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TestResultScreen(
          correctCount: viewModel.correctCount,
          incorrectCount: viewModel.incorrectCount,
          wrongWords: List.from(viewModel.wrongAnswersInSession),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReviewViewModel>();
    final size = MediaQuery.of(context).size;

    if (viewModel.isLoading || _currentWord == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final word = _currentWord!;
    final targetContent = word.getLocalizedContent(viewModel.targetLang);
    final sourceContent = word.getLocalizedContent(viewModel.sourceLang);

    return Scaffold(
      appBar: AppBar(
        title: Text("Dinleme Testi",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // İlerleme Çubuğu
            LinearProgressIndicator(
              value: viewModel.totalWordsInReview > 0
                  ? (viewModel.totalWordsInReview -
                          viewModel.reviewQueue.length) /
                      viewModel.totalWordsInReview
                  : 0,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const Spacer(flex: 1),

            // Ses Butonu (Büyük)
            GestureDetector(
              onTap: viewModel.speakCurrentWord,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 20,
                          offset: Offset(0, 10))
                    ]),
                child: Icon(Icons.volume_up_rounded,
                    size: 60, color: Colors.blue.shade700),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.05, duration: 1000.ms),

            const SizedBox(height: 16),
            Text("Kelimeyi duyup aşağıya yazın",
                style: TextStyle(color: Colors.grey[600])),

            const Spacer(flex: 1),

            // Input Alanı
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !_isAnswered,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Buraya yazın...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _checkAnswer(),
            ),

            // Cevap Gösterimi (Cevaplandıktan Sonra)
            if (_isAnswered) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: _isCorrect ? Colors.green : Colors.red),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isCorrect ? Icons.check_circle : Icons.cancel,
                            color: _isCorrect ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Text(_isCorrect ? "Doğru!" : "Yanlış!",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isCorrect
                                    ? Colors.green.shade800
                                    : Colors.red.shade800)),
                      ],
                    ),
                    if (!_isCorrect) ...[
                      const SizedBox(height: 8),
                      Text("Doğrusu: ${targetContent['word']}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 8),
                    Text(
                        "${sourceContent['word']} (${sourceContent['meaning']})",
                        style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.2),
            ],

            const Spacer(flex: 2),

            // Buton
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isAnswered ? _loadNextWord : _checkAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAnswered
                      ? (_isCorrect ? Colors.green : Colors.red)
                      : Colors.blue[700],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _isAnswered ? "Devam Et" : "Kontrol Et",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
