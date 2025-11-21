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
    _focus_nodeDispose();
    super.dispose();
  }

  // small helper because some codebases prefer explicit null-safety handling
  void _focus_nodeDispose() {
    try {
      _focusNode.dispose();
    } catch (_) {}
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
    final userInput = _controller.text.trim();
    final isCorrect = viewModel.checkTextAnswer(userInput);

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
      PageRouteBuilder(
        transitionDuration: 500.ms,
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
          child: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
        ),
      );
    }

    final word = _currentWord!;
    final targetContent = word.getLocalizedContent(viewModel.targetLang);
    final sourceContent = word.getLocalizedContent(viewModel.sourceLang);

    final progress = viewModel.totalWordsInReview > 0
        ? (viewModel.totalWordsInReview - viewModel.reviewQueue.length) /
            viewModel.totalWordsInReview
        : 0.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Dinleme Testi',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * viewModel.totalWordsInReview).toInt()}/${viewModel.totalWordsInReview}',
                      style: GoogleFonts.poppins(color: Colors.black54),
                    ),
                    IconButton(
                      onPressed: () => viewModel.speakCurrentWord(),
                      icon: Icon(Icons.volume_up_rounded,
                          color: Colors.indigo.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(Colors.indigo.shade400),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Big Card with instruction
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Duy ve Yaz',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aşağıdaki butona dokun, kelimeyi dinle ve kutuya yaz.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Big speaker with subtle pulse
                      GestureDetector(
                        onTap: () => viewModel.speakCurrentWord(),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.indigo.shade100, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Icon(Icons.volume_up_rounded,
                              size: 56, color: Colors.indigo.shade700),
                        )
                            .animate(
                                onPlay: (controller) => controller.repeat())
                            .scaleXY(end: 1.05, duration: 1000.ms),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Input field
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: !_isAnswered,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 22, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: 'Buraya yazın...',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _checkAnswer(),
                      ),

                      const SizedBox(height: 18),

                      // Hint / small info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                              'Büyük/küçük harf önemli değil. Boşluklar otomatik kırpılır.',
                              style: GoogleFonts.roboto(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Feedback card (after answer)
                if (_isAnswered) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _isCorrect
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _isCorrect
                              ? Colors.green.shade200
                              : Colors.red.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: (_isCorrect ? Colors.green : Colors.red)
                              .withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isCorrect ? Icons.check_circle : Icons.cancel,
                              color: _isCorrect
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isCorrect ? 'Doğru!' : 'Yanlış',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        if (!_isCorrect) ...[
                          const SizedBox(height: 12),
                          Text('Doğrusu: ${"${targetContent['word']}"}',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 12),
                        Text(
                            '${sourceContent['word']} (${sourceContent['meaning']})',
                            style: GoogleFonts.roboto(color: Colors.grey[700])),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: 18),
                ],

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isAnswered ? _loadNextWord : _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAnswered
                          ? (_isCorrect
                              ? Colors.green.shade700
                              : Colors.red.shade700)
                          : Colors.indigo.shade600,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 10,
                      shadowColor: Colors.indigo.withOpacity(0.25),
                    ),
                    child: Text(
                      _isAnswered ? 'Devam Et' : 'Kontrol Et',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // Small footer: example sentence
                if (_isAnswered)
                  Text(
                    word.getSentence(
                            viewModel.proficiencyLevel, viewModel.targetLang) ??
                        '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.grey[700]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
