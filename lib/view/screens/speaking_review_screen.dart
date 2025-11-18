import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/word_model.dart';
import '../../viewmodel/review_viewmodel.dart';
import 'test_result_screen.dart';

class SpeakingReviewScreen extends StatefulWidget {
  const SpeakingReviewScreen({super.key});

  @override
  State<SpeakingReviewScreen> createState() => _SpeakingReviewScreenState();
}

class _SpeakingReviewScreenState extends State<SpeakingReviewScreen> {
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _hasPermission = false;
  Word? _currentWord;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadNextWord();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
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
      _isCorrect = false;
    });

    // Otomatik okuma (isteğe bağlı, önce kullanıcının duymasını istiyorsak)
    // viewModel.speakCurrentWord();
  }

  void _handleMicPress(bool isDown) async {
    if (_isAnswered) return;
    if (!_hasPermission) {
      _checkPermissions();
      return;
    }

    final viewModel = context.read<ReviewViewModel>();

    if (isDown) {
      await viewModel.startListeningForSpeech();
    } else {
      await viewModel.stopListeningForSpeech();
      // Konuşma bitti, kontrol et
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    final viewModel = context.read<ReviewViewModel>();
    // Kullanıcının söylediği metin ViewModel'de saklanıyor
    final spoken = viewModel.spokenText;

    if (spoken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ses algılanamadı, tekrar deneyin.')),
      );
      return;
    }

    final isCorrect = viewModel.checkTextAnswer(spoken);

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

    if (viewModel.isLoading || _currentWord == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final word = _currentWord!;
    final targetContent = word.getLocalizedContent(viewModel.targetLang);

    return Scaffold(
      appBar: AppBar(
        title: Text("Konuşma Testi",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Kelime Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10))
                  ]),
              child: Column(
                children: [
                  Text(
                    targetContent['word'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 36, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  IconButton(
                    icon: const Icon(Icons.volume_up,
                        size: 30, color: Colors.blue),
                    onPressed: viewModel.speakCurrentWord,
                  )
                ],
              ),
            ),

            const Spacer(),

            // Algılanan Metin
            if (viewModel.spokenText.isNotEmpty)
              Text(
                "Algılanan: \"${viewModel.spokenText}\"",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[800],
                    fontStyle: FontStyle.italic),
              ).animate().fadeIn(),

            const SizedBox(height: 20),

            // Cevap Geri Bildirimi
            if (_isAnswered) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isCorrect ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect ? Colors.green : Colors.red),
                    const SizedBox(width: 8),
                    Text(_isCorrect ? "Mükemmel Telaffuz!" : "Tekrar Dene",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isCorrect
                                ? Colors.green.shade800
                                : Colors.red.shade800)),
                  ],
                ),
              ).animate().scale(),
            ],

            const Spacer(),

            // Mikrofon Butonu
            if (!_isAnswered)
              GestureDetector(
                onLongPressStart: (_) => _handleMicPress(true),
                onLongPressEnd: (_) => _handleMicPress(false),
                // Dokunmatik olmayan cihazlar (simülatör) için onTap
                onTap: () {
                  if (viewModel.isListening) {
                    _handleMicPress(false);
                  } else {
                    _handleMicPress(true);
                  }
                },
                child: AnimatedContainer(
                  duration: 200.ms,
                  width: viewModel.isListening ? 100 : 80,
                  height: viewModel.isListening ? 100 : 80,
                  decoration: BoxDecoration(
                      color: viewModel.isListening ? Colors.red : Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (viewModel.isListening ? Colors.red : Colors.blue)
                                  .withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ]),
                  child: Icon(
                      viewModel.isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 40),
                ),
              ),

            if (!_isAnswered)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  viewModel.isListening
                      ? "Dinleniyor..."
                      : "Basılı Tut ve Konuş",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),

            if (_isAnswered)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loadNextWord,
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: const Text("Devam Et", style: TextStyle(fontSize: 18)),
                ),
              )
          ],
        ),
      ),
    );
  }
}
