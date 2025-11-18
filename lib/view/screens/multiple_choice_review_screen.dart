// lib/screens/review/multiple_choice_review_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';

import '../../data/models/word_model.dart';
import '../../viewmodel/review_viewmodel.dart';
import 'test_result_screen.dart';

class MultipleChoiceReviewScreen extends StatefulWidget {
  const MultipleChoiceReviewScreen({super.key});

  @override
  State<MultipleChoiceReviewScreen> createState() =>
      _MultipleChoiceReviewScreenState();
}

class _MultipleChoiceReviewScreenState
    extends State<MultipleChoiceReviewScreen> {
  bool _isAnswered = false;
  int? _selectedOptionIndex;
  int _correctOptionIndex = 0;
  List<String> _options = [];
  Word? _currentWord;
  bool _showSourceLanguage = false;
  String _currentSentenceLevel = 'beginner';

  @override
  void initState() {
    super.initState();
    _loadNextWord();
  }

  Future<void> _loadNextWord() async {
    final viewModel = context.read<ReviewViewModel>();

    if (viewModel.reviewQueue.isEmpty) {
      await _finishTestAndNavigate();
      return;
    }

    final word = viewModel.currentReviewWord;
    if (word == null) return;

    final sourceLang = viewModel.sourceLang;
    _currentSentenceLevel = viewModel.proficiencyLevel;

    final decoys = await viewModel.getDecoys(word);
    final correctTranslation =
        word.getLocalizedContent(sourceLang)['word'] ?? "???";

    final options = [correctTranslation, ...decoys]..shuffle(Random());
    final correctIndex = options.indexOf(correctTranslation);

    if (!mounted) return;

    setState(() {
      _currentWord = word;
      _options = options;
      _correctOptionIndex = correctIndex;
      _isAnswered = false;
      _selectedOptionIndex = null;
      _showSourceLanguage = false;
    });

    if (viewModel.autoPlaySound) {
      viewModel.speakCurrentWord();
    }
  }

  void _handleAnswer(int selectedIndex) {
    if (_isAnswered) return;

    final viewModel = context.read<ReviewViewModel>();
    final isCorrect = selectedIndex == _correctOptionIndex;

    setState(() {
      _isAnswered = true;
      _selectedOptionIndex = selectedIndex;
    });

    if (isCorrect) {
      viewModel.answerCorrectly(_currentWord!);
    } else {
      viewModel.answerIncorrectly(_currentWord!);
    }
  }

  void _revealMeaning() {
    if (_isAnswered) return;
    setState(() {
      _isAnswered = true;
      _selectedOptionIndex = -1;
    });
    context.read<ReviewViewModel>().answerIncorrectly(_currentWord!);
  }

  Future<void> _finishTestAndNavigate() async {
    if (!mounted) return;
    final viewModel = context.read<ReviewViewModel>();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: 600.ms,
        pageBuilder: (_, __, ___) => TestResultScreen(
          correctCount: viewModel.correctCount,
          incorrectCount: viewModel.incorrectCount,
          wrongWords: List.from(viewModel.wrongAnswersInSession),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildOption(int index, String option) {
    final isSelected = _selectedOptionIndex == index;
    final isCorrect = index == _correctOptionIndex;

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color textColor = Colors.grey[800]!;
    IconData? icon;
    Color? iconColor;

    if (_isAnswered) {
      if (isCorrect) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade400;
        textColor = Colors.green.shade900;
        icon = Icons.check_circle;
        iconColor = Colors.green.shade600;
      } else if (isSelected && _selectedOptionIndex != -1) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade400;
        textColor = Colors.red.shade900;
        icon = Icons.cancel;
        iconColor = Colors.red.shade600;
      } else if (_selectedOptionIndex == -1 && isCorrect) {
        // Pas geçildi
        bgColor = Colors.amber.shade50;
        borderColor = Colors.amber.shade500;
        textColor = Colors.amber.shade900;
        icon = Icons.lightbulb;
        iconColor = Colors.amber.shade700;
      }
    }

    return AnimatedContainer(
          duration: 400.ms,
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 14),
          height: 68,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _isAnswered ? null : () => _handleAnswer(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: iconColor, size: 32),
                        const SizedBox(width: 16),
                      ],
                      Flexible(
                        child: Text(
                          option,
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .animate(delay: (120 * index + 100).ms)
        .fadeIn(duration: 500.ms)
        .slide(
          begin: const Offset(-0.8, 0),
          duration: 700.ms,
          curve: Curves.easeOutCubic,
        )
        .shimmer(delay: 800.ms, duration: 1200.ms);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReviewViewModel>();

    if (viewModel.isLoading || _currentWord == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF0F7FF), Colors.white],
            ),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
        ),
      );
    }

    final word = _currentWord!;
    final targetContent = word.getLocalizedContent(viewModel.targetLang);
    final sourceContent = word.getLocalizedContent(viewModel.sourceLang);

    final translationText = sourceContent['word'] ?? '';
    final definitionText = _showSourceLanguage
        ? (sourceContent['meaning'] ?? '')
        : (targetContent['meaning'] ?? '');

    final displayedSentence = _showSourceLanguage
        ? word.getSentence(_currentSentenceLevel, viewModel.sourceLang)
        : word.getSentence(_currentSentenceLevel, viewModel.targetLang);

    double progress = viewModel.totalWordsInReview > 0
        ? (viewModel.totalWordsInReview - viewModel.reviewQueue.length) /
              viewModel.totalWordsInReview
        : 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          "Kelime Testi",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                Text(
                  "${viewModel.totalWordsInReview - viewModel.reviewQueue.length}/${viewModel.totalWordsInReview}",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.indigo.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F7FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // SORU KARTI
                Container(
                      padding: const EdgeInsets.all(28),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.indigo.shade200),
                            ),
                            child: Text(
                              word.partOfSpeech.toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: Colors.indigo.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            targetContent['word'] ?? '?',
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey[900],
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  color: Colors.indigo.withOpacity(0.2),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ).animate().scale(
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          ),

                          if (word.transcription.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              word.transcription,
                              style: GoogleFonts.roboto(
                                fontSize: 20,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ).animate().fade(delay: 200.ms),
                          ],

                          const SizedBox(height: 20),

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
                              shadowColor: Colors.indigo.withOpacity(0.4),
                            ),
                            child: const Icon(
                              Icons.volume_up_rounded,
                              size: 36,
                            ),
                          ).animate().scale(
                            delay: 300.ms,
                            duration: 800.ms,
                            curve: Curves.elasticOut,
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .slideY(
                      begin: -0.3,
                      duration: 700.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fade(),

                const SizedBox(height: 32),

                // ŞIKLAR
                ..._options.mapIndexed((index, option) {
                  return _buildOption(index, option);
                }),

                if (!_isAnswered)
                  TextButton.icon(
                    onPressed: _revealMeaning,
                    icon: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                    ),
                    label: Text(
                      "Anlamını Gör (Pas Geç)",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3),

                // CEVAP SONRASI DETAY KARTI
                if (_isAnswered) ...[
                  const SizedBox(height: 32),

                  Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_selectedOptionIndex == _correctOptionIndex)
                                  ? Colors.green.withOpacity(0.2)
                                  : (_selectedOptionIndex == -1
                                        ? Colors.amber.withOpacity(0.18)
                                        : Colors.red.withOpacity(0.2)),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => setState(
                                  () => _showSourceLanguage =
                                      !_showSourceLanguage,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.swap_horiz_rounded,
                                        color: Colors.indigo.shade700,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _showSourceLanguage
                                            ? viewModel.sourceLang.toUpperCase()
                                            : viewModel.targetLang
                                                  .toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.indigo.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              translationText,
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[900],
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 10),

                            Text(
                              definitionText,
                              style: GoogleFonts.roboto(
                                fontSize: 17,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            Divider(
                              height: 40,
                              thickness: 1.2,
                              color: Colors.grey[300],
                            ),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '“$displayedSentence”',
                                    style: GoogleFonts.poppins(
                                      fontSize: 19,
                                      height: 1.6,
                                      color: Colors.grey[800],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildLevelPill('beginner', Colors.green),
                                      const SizedBox(width: 12),
                                      _buildLevelPill(
                                        'intermediate',
                                        Colors.orange,
                                      ),
                                      const SizedBox(width: 12),
                                      _buildLevelPill('advanced', Colors.red),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .slideY(
                        begin: 0.3,
                        duration: 600.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .fade(),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _loadNextWord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        elevation: 12,
                        shadowColor: Colors.indigo.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        "Devam Et",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ).animate().scale(
                    delay: 200.ms,
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelPill(String level, MaterialColor color) {
    final isSelected = _currentSentenceLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _currentSentenceLevel = level),
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.4),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Text(
          level == 'beginner'
              ? 'Kolay'
              : level == 'intermediate'
              ? 'Orta'
              : 'Zor',
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : color.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
