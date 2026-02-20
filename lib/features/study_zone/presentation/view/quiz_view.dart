import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/di/injection_container.dart';
import '../../domain/entities/word_entity.dart';
import '../view_model/study_view_model.dart';
import 'test_result_view.dart';

class QuizView extends StatefulWidget {
  const QuizView({super.key});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  bool _isAnswered = false;
  int? _selectedOptionIndex;
  int _correctOptionIndex = 0;
  List<String> _options = [];
  WordEntity? _currentWord;
  bool _showSourceLanguage = false;
  String _currentSentenceLevel = 'beginner';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNextWord());
  }

  Future<void> _loadNextWord() async {
    final viewModel = locator<StudyViewModel>();

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
    final viewModel = locator<StudyViewModel>();
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
    locator<StudyViewModel>().answerIncorrectly(_currentWord!);
  }

  Future<void> _finishTestAndNavigate() async {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: 600.ms,
        pageBuilder: (_, __, ___) => const TestResultView(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<StudyViewModel>(
      viewModel: locator<StudyViewModel>(),
      onModelReady: (model) {},
      builder: (context, viewModel, child) {
        if (viewModel.isLoading || _currentWord == null) {
          return Scaffold(
            backgroundColor: context.colors.surface,
            body: Center(
                child:
                    CircularProgressIndicator(color: context.colors.primary)),
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

        final progress = viewModel.totalWordsInReview > 0
            ? (viewModel.totalWordsInReview - viewModel.reviewQueue.length) /
                viewModel.totalWordsInReview
            : 0.0;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: context.colors.onSurface),
            title: Text(
              "multiple_choice_test".tr(),
              style: context.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(context.responsive
                  .value(mobile: 60, tablet: 70, desktop: 80)),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.responsive.spacingL,
                    vertical: context.responsive.spacingS),
                child: Column(
                  children: [
                    Text(
                      "${viewModel.totalWordsInReview - viewModel.reviewQueue.length}/${viewModel.totalWordsInReview}",
                      style: context.textTheme.bodyMedium
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                    SizedBox(height: context.responsive.spacingS),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                          context.responsive.borderRadiusM),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: context.responsive
                            .value(mobile: 8, tablet: 10, desktop: 12),
                        backgroundColor: context.colors.outlineVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            context.colors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Container(
            color: context.colors.surface,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: context.responsive.paddingPage,
                child: Column(
                  children: [
                    // SORU KARTI
                    Container(
                      padding: EdgeInsets.all(context.responsive.spacingXL),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(
                            context.responsive.borderRadiusXL),
                        boxShadow: [
                          BoxShadow(
                              color: context.colors.primary.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: context.responsive.spacingM,
                                vertical: context.responsive.spacingS),
                            decoration: BoxDecoration(
                              color: context.colors.primaryContainer
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(
                                  context.responsive.borderRadiusL),
                            ),
                            child: Text(
                              word.partOfSpeech.toUpperCase(),
                              style: context.textTheme.labelLarge?.copyWith(
                                color: context.colors.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: context.responsive.spacingL),
                          Text(
                            targetContent['word'] ?? '?',
                            style: GoogleFonts.poppins(
                              fontSize: context.responsive
                                  .value(mobile: 40, tablet: 48, desktop: 56),
                              fontWeight: FontWeight.w800,
                              color: context.colors.onSurface,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().scale(
                              duration: 600.ms, curve: Curves.easeOutBack),
                          if (word.transcription.isNotEmpty) ...[
                            SizedBox(height: context.responsive.spacingS),
                            Text(
                              word.transcription,
                              style: context.textTheme.titleMedium?.copyWith(
                                color: context.colors.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ).animate().fade(delay: 200.ms),
                          ],
                          SizedBox(height: context.responsive.spacingL),
                          ElevatedButton(
                            onPressed: () => viewModel.speakText(
                                targetContent['word'] ?? '',
                                viewModel.targetLang),
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding:
                                  EdgeInsets.all(context.responsive.spacingM),
                              backgroundColor: context.colors.primary,
                              foregroundColor: context.colors.onPrimary,
                            ),
                            child: Icon(Icons.volume_up_rounded,
                                size: context.responsive.value(
                                    mobile: 32, tablet: 36, desktop: 40)),
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: -0.3, duration: 700.ms).fade(),

                    SizedBox(height: context.responsive.spacingXL),

                    // ŞIKLAR
                    ..._options.mapIndexed((index, option) =>
                        _buildOption(index, option, context)),

                    if (!_isAnswered)
                      TextButton.icon(
                        onPressed: _revealMeaning,
                        icon: Icon(Icons.lightbulb_outline,
                            color: context.ext.warning,
                            size: context.responsive.iconSizeM),
                        label: Text(
                          "reveal_meaning".tr(),
                          style: context.textTheme.bodyLarge?.copyWith(
                              color: context.ext.warning,
                              fontWeight: FontWeight.w600),
                        ),
                      ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3),

                    // CEVAP DETAYI
                    if (_isAnswered) ...[
                      SizedBox(height: context.responsive.spacingXL),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(context.responsive.spacingL),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(
                              context.responsive.borderRadiusXL),
                          border:
                              Border.all(color: context.colors.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: InkWell(
                                onTap: () => setState(() =>
                                    _showSourceLanguage = !_showSourceLanguage),
                                child: Icon(Icons.swap_horiz_rounded,
                                    color: context.colors.primary),
                              ),
                            ),
                            Text(
                              translationText,
                              style: GoogleFonts.poppins(
                                fontSize: context.responsive.fontSizeH2,
                                fontWeight: FontWeight.bold,
                                color: context.colors.onSurface,
                              ),
                            ),
                            Text(definitionText,
                                style: context.textTheme.bodyMedium
                                    ?.copyWith(fontStyle: FontStyle.italic)),
                            Divider(height: context.responsive.spacingL),
                            Text('“$displayedSentence”',
                                style: context.textTheme.bodyLarge,
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ).animate().slideY(begin: 0.3).fade(),
                      SizedBox(height: context.responsive.spacingL),
                      SizedBox(
                        width: double.infinity,
                        height: context.responsive
                            .value(mobile: 56, tablet: 64, desktop: 72),
                        child: ElevatedButton(
                          onPressed: _loadNextWord,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.primary,
                            foregroundColor: context.colors.onPrimary,
                          ),
                          child: Text("continue".tr(),
                              style: context.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.onPrimary)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption(int index, String option, BuildContext context) {
    final isSelected = _selectedOptionIndex == index;
    final isCorrect = index == _correctOptionIndex;

    Color bgColor = context.colors.surface;
    Color borderColor = context.colors.outlineVariant;
    Color textColor = context.colors.onSurface;
    IconData? icon;

    if (_isAnswered) {
      if (isCorrect) {
        bgColor = context.ext.success.withOpacity(0.1);
        borderColor = context.ext.success;
        textColor = context.ext.success;
        icon = Icons.check_circle;
      } else if (isSelected) {
        bgColor = context.colors.error.withOpacity(0.1);
        borderColor = context.colors.error;
        textColor = context.colors.error;
        icon = Icons.cancel;
      } else if (_selectedOptionIndex == -1 && isCorrect) {
        bgColor = context.ext.warning.withOpacity(0.1);
        borderColor = context.ext.warning;
        textColor = context.ext.warning;
        icon = Icons.lightbulb;
      }
    }

    return AnimatedContainer(
      duration: 400.ms,
      margin: EdgeInsets.only(bottom: context.responsive.spacingS),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isAnswered ? null : () => _handleAnswer(index),
          borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: context.responsive.spacingM,
                horizontal: context.responsive.spacingL),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: textColor),
                  SizedBox(width: context.responsive.spacingM)
                ],
                Expanded(
                  child: Text(
                    option,
                    style: GoogleFonts.poppins(
                        fontSize: context.responsive.fontSizeBody,
                        fontWeight: FontWeight.w600,
                        color: textColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
