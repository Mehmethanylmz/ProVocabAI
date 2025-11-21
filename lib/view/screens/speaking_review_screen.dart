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
    setState(() => _hasPermission = status.isGranted);
  }

  Future<void> _loadNextWord() async {
    final viewModel = context.read<ReviewViewModel>();

    if (viewModel.reviewQueue.isEmpty) {
      await _finishTestAndNavigate();
      return;
    }

    setState(() {
      _currentWord = viewModel.currentReviewWord;
      _isAnswered = false;
      _isCorrect = false;
    });
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
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    final viewModel = context.read<ReviewViewModel>();
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
    final viewModel = context.read<ReviewViewModel>();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: 600.ms,
        pageBuilder: (_, __, ___) => TestResultScreen(
          correctCount: viewModel.correctCount,
          incorrectCount: viewModel.incorrectCount,
          wrongWords: List.from(viewModel.wrongAnswersInSession),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReviewViewModel>();

    if (viewModel.isLoading || _currentWord == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF0F7FF), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }

    final word = _currentWord!;
    final targetContent = word.getLocalizedContent(viewModel.targetLang);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Konuşma Testi",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.grey[900],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F7FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              children: [
                // KELİME KARTI
                Container(
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        targetContent['word'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey[900],
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().scale(
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => viewModel.speakText(
                          targetContent['word'] ?? '',
                          viewModel.targetLang,
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Colors.indigo.shade500,
                          foregroundColor: Colors.white,
                          elevation: 10,
                        ),
                        child: const Icon(Icons.volume_up, size: 32),
                      ).animate().scale(
                            delay: 200.ms,
                            duration: 800.ms,
                            curve: Curves.elasticOut,
                          ),
                    ],
                  ),
                ).animate().slideY(begin: -0.25, duration: 700.ms).fade(),

                const Spacer(),

                // Algılanan metin balonu
                if (viewModel.spokenText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      "“${viewModel.spokenText}”",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.blue.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),

                const SizedBox(height: 20),

                // DOĞRU/YANLIŞ geri bildirimi
                if (_isAnswered) _buildFeedbackCard(),

                const Spacer(),

                // MİKROFON BUTONU
                if (!_isAnswered)
                  GestureDetector(
                    onLongPressStart: (_) => _handleMicPress(true),
                    onLongPressEnd: (_) => _handleMicPress(false),
                    onTap: () {
                      if (viewModel.isListening) {
                        _handleMicPress(false);
                      } else {
                        _handleMicPress(true);
                      }
                    },
                    child: _buildMicButton(viewModel),
                  ),

                const SizedBox(height: 16),

                if (!_isAnswered)
                  Text(
                    viewModel.isListening
                        ? "Dinleniyor..."
                        : "Basılı Tut ve Konuş",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 15,
                    ),
                  ),

                if (_isAnswered)
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _loadNextWord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 10,
                      ),
                      child: Text(
                        "Devam Et",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ).animate().scale(
                        delay: 200.ms,
                        duration: 700.ms,
                        curve: Curves.elasticOut,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton(ReviewViewModel viewModel) {
    final isListening = viewModel.isListening;

    return AnimatedContainer(
      duration: 300.ms,
      width: isListening ? 110 : 90,
      height: isListening ? 110 : 90,
      decoration: BoxDecoration(
        color: isListening ? Colors.red : Colors.indigo.shade500,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isListening ? Colors.red : Colors.indigo).withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Icon(
        isListening ? Icons.mic : Icons.mic_none,
        color: Colors.white,
        size: isListening ? 46 : 40,
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_isCorrect ? Colors.green : Colors.red).withOpacity(0.18),
            blurRadius: 25,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.cancel,
            size: 32,
            color: _isCorrect ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 12),
          Text(
            _isCorrect ? "Mükemmel Telaffuz!" : "Tekrar Dene",
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: _isCorrect ? Colors.green.shade800 : Colors.red.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.3);
  }
}
