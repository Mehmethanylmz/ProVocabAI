import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../data/models/word_model.dart';
import '../../viewmodel/review_viewmodel.dart';
import 'test_result_screen.dart';
import '../../core/extensions/responsive_extension.dart';
import '../../core/constants/app_colors.dart';

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

    Color bgColor = AppColors.surface;
    Color borderColor = AppColors.borderLight;
    Color textColor = AppColors.textPrimary;
    IconData? icon;
    Color? iconColor;

    if (_isAnswered) {
      if (isCorrect) {
        bgColor = AppColors.success.withOpacity(0.1);
        borderColor = AppColors.success;
        textColor = AppColors.success;
        icon = Icons.check_circle;
        iconColor = AppColors.success;
      } else if (isSelected && _selectedOptionIndex != -1) {
        bgColor = AppColors.error.withOpacity(0.1);
        borderColor = AppColors.error;
        textColor = AppColors.error;
        icon = Icons.cancel;
        iconColor = AppColors.error;
      } else if (_selectedOptionIndex == -1 && isCorrect) {
        // Pas geçildi
        bgColor = AppColors.warning.withOpacity(0.1);
        borderColor = AppColors.warning;
        textColor = AppColors.warning;
        icon = Icons.lightbulb;
        iconColor = AppColors.warning;
      }
    }

    return AnimatedContainer(
      duration: 400.ms,
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: context.responsive.spacingS),
      height: context.responsive.value(
        mobile: 64,
        tablet: 68,
        desktop: 72,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
        border: Border.all(
          color: borderColor,
          width:
              context.responsive.value(mobile: 2.0, tablet: 2.5, desktop: 3.0),
        ),
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
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
        child: InkWell(
          borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
          onTap: _isAnswered ? null : () => _handleAnswer(index),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive.spacingL,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: iconColor,
                      size: context.responsive.value(
                        mobile: 28,
                        tablet: 32,
                        desktop: 36,
                      ),
                    ),
                    SizedBox(width: context.responsive.spacingM),
                  ],
                  Flexible(
                    child: Text(
                      option,
                      style: GoogleFonts.poppins(
                        fontSize: context.responsive.value(
                          mobile: 17,
                          tablet: 19,
                          desktop: 21,
                        ),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary.withOpacity(0.05), AppColors.surface],
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
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
        foregroundColor: AppColors.textPrimary,
        title: Text(
          "multiple_choice_test".tr(),
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeH2,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            context.responsive.value(mobile: 60, tablet: 70, desktop: 80),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive.spacingL,
              vertical: context.responsive.spacingS,
            ),
            child: Column(
              children: [
                Text(
                  "${viewModel.totalWordsInReview - viewModel.reviewQueue.length}/${viewModel.totalWordsInReview}",
                  style: GoogleFonts.poppins(
                    fontSize: context.responsive.fontSizeBody,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: context.responsive.spacingS),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(context.responsive.borderRadiusM),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: context.responsive.value(
                      mobile: 8,
                      tablet: 10,
                      desktop: 12,
                    ),
                    backgroundColor: AppColors.borderLight,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withOpacity(0.05), AppColors.surface],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: context.responsive.paddingPage,
            child: Column(
              children: [
                // SORU KARTI
                Container(
                  padding: EdgeInsets.all(context.responsive.spacingXL),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(
                        context.responsive.borderRadiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive.spacingM,
                          vertical: context.responsive.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                              context.responsive.borderRadiusL),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          word.partOfSpeech.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: context.responsive.fontSizeCaption,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: context.responsive.spacingL),
                      Text(
                        targetContent['word'] ?? '?',
                        style: GoogleFonts.poppins(
                          fontSize: context.responsive.value(
                            mobile: 40,
                            tablet: 48,
                            desktop: 56,
                          ),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.1,
                          shadows: [
                            Shadow(
                              color: AppColors.primary.withOpacity(0.2),
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
                        SizedBox(height: context.responsive.spacingS),
                        Text(
                          word.transcription,
                          style: GoogleFonts.roboto(
                            fontSize: context.responsive.fontSizeH3,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ).animate().fade(delay: 200.ms),
                      ],
                      SizedBox(height: context.responsive.spacingL),
                      ElevatedButton(
                        onPressed: () => viewModel.speakText(
                          targetContent['word'] ?? '',
                          viewModel.targetLang,
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.all(context.responsive.spacingM),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                          elevation: context.responsive.elevationHigh,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: context.responsive.value(
                            mobile: 32,
                            tablet: 36,
                            desktop: 40,
                          ),
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

                SizedBox(height: context.responsive.spacingXL),

                // ŞIKLAR
                ..._options.mapIndexed((index, option) {
                  return _buildOption(index, option);
                }),

                if (!_isAnswered)
                  TextButton.icon(
                    onPressed: _revealMeaning,
                    icon: Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.warning,
                      size: context.responsive.iconSizeM,
                    ),
                    label: Text(
                      "reveal_meaning".tr(),
                      style: GoogleFonts.poppins(
                        fontSize: context.responsive.fontSizeBody,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3),

                // CEVAP SONRASI DETAY KARTI
                if (_isAnswered) ...[
                  SizedBox(height: context.responsive.spacingXL),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.responsive.spacingL),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                          context.responsive.borderRadiusXL),
                      boxShadow: [
                        BoxShadow(
                          color: (_selectedOptionIndex == _correctOptionIndex)
                              ? AppColors.success.withOpacity(0.2)
                              : (_selectedOptionIndex == -1
                                  ? AppColors.warning.withOpacity(0.18)
                                  : AppColors.error.withOpacity(0.2)),
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
                            borderRadius: BorderRadius.circular(
                                context.responsive.borderRadiusL),
                            onTap: () => setState(
                              () => _showSourceLanguage = !_showSourceLanguage,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsive.spacingM,
                                vertical: context.responsive.spacingS,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    context.responsive.borderRadiusL),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.swap_horiz_rounded,
                                    color: AppColors.primary,
                                    size: context.responsive.iconSizeS,
                                  ),
                                  SizedBox(width: context.responsive.spacingXS),
                                  Text(
                                    _showSourceLanguage
                                        ? viewModel.sourceLang.toUpperCase()
                                        : viewModel.targetLang.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      fontSize:
                                          context.responsive.fontSizeCaption,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: context.responsive.spacingM),
                        Text(
                          translationText,
                          style: GoogleFonts.poppins(
                            fontSize: context.responsive.value(
                              mobile: 28,
                              tablet: 32,
                              desktop: 36,
                            ),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: context.responsive.spacingS),
                        Text(
                          definitionText,
                          style: GoogleFonts.roboto(
                            fontSize: context.responsive.fontSizeBody,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Divider(
                          height: context.responsive.spacingXL,
                          thickness: 1.2,
                          color: AppColors.borderLight,
                        ),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(context.responsive.spacingL),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(
                                context.responsive.borderRadiusL),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '“$displayedSentence”',
                                style: GoogleFonts.poppins(
                                  fontSize: context.responsive.fontSizeBody,
                                  height: 1.6,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: context.responsive.spacingM),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLevelPill(
                                      'beginner', AppColors.success),
                                  SizedBox(width: context.responsive.spacingS),
                                  _buildLevelPill(
                                      'intermediate', AppColors.warning),
                                  SizedBox(width: context.responsive.spacingS),
                                  _buildLevelPill('advanced', AppColors.error),
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
                  SizedBox(height: context.responsive.spacingXL),
                  SizedBox(
                    width: double.infinity,
                    height: context.responsive.value(
                      mobile: 56,
                      tablet: 64,
                      desktop: 72,
                    ),
                    child: ElevatedButton(
                      onPressed: _loadNextWord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        elevation: context.responsive.elevationHigh,
                        shadowColor: AppColors.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              context.responsive.borderRadiusL),
                        ),
                      ),
                      child: Text(
                        "continue".tr(),
                        style: GoogleFonts.poppins(
                          fontSize: context.responsive.fontSizeH3,
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

  Widget _buildLevelPill(String level, Color color) {
    final isSelected = _currentSentenceLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _currentSentenceLevel = level),
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.value(
            mobile: isSelected ? 16 : 12,
            tablet: isSelected ? 20 : 16,
            desktop: isSelected ? 24 : 20,
          ),
          vertical: context.responsive.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.15),
          borderRadius:
              BorderRadius.circular(context.responsive.borderRadiusXL),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.4),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Text(
          level == 'beginner'
              ? 'easy'.tr()
              : level == 'intermediate'
                  ? 'medium'.tr()
                  : 'hard'.tr(),
          style: GoogleFonts.poppins(
            color: isSelected ? AppColors.surface : color,
            fontWeight: FontWeight.w600,
            fontSize: context.responsive.fontSizeCaption,
          ),
        ),
      ),
    );
  }
}
