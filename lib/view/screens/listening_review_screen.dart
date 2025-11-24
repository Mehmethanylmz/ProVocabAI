import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/models/word_model.dart';
import '../../viewmodel/review_viewmodel.dart';
import 'test_result_screen.dart';
import '../../core/extensions/responsive_extension.dart';
import '../../core/constants/app_colors.dart';

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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.05), AppColors.surface],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
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
          'listening_test'.tr(),
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeH2,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(context.responsive.value(
            mobile: 56,
            tablet: 64,
            desktop: 72,
          )),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive.spacingL,
              vertical: context.responsive.spacingS,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * viewModel.totalWordsInReview).toInt()}/${viewModel.totalWordsInReview}',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: context.responsive.fontSizeBody,
                      ),
                    ),
                    IconButton(
                      onPressed: () => viewModel.speakCurrentWord(),
                      icon: Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.primary,
                        size: context.responsive.iconSizeM,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.responsive.spacingXS),
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
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                SizedBox(height: context.responsive.spacingS),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.05), AppColors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: context.responsive.paddingPage,
            child: Column(
              children: [
                // Big Card with instruction
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.responsive.spacingL),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(
                        context.responsive.borderRadiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'listen_and_write'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: context.responsive.fontSizeH3,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: context.responsive.spacingS),
                      Text(
                        'listening_instruction'.tr(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: context.responsive.fontSizeBody,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: context.responsive.spacingM),

                      // Big speaker with subtle pulse
                      GestureDetector(
                        onTap: () => viewModel.speakCurrentWord(),
                        child: Container(
                          width: context.responsive.value(
                            mobile: 100,
                            tablet: 120,
                            desktop: 140,
                          ),
                          height: context.responsive.value(
                            mobile: 100,
                            tablet: 120,
                            desktop: 140,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            size: context.responsive.value(
                              mobile: 48,
                              tablet: 56,
                              desktop: 64,
                            ),
                            color: AppColors.primary,
                          ),
                        )
                            .animate(
                                onPlay: (controller) => controller.repeat())
                            .scaleXY(end: 1.05, duration: 1000.ms),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.responsive.spacingL),

                // Input field
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive.spacingS,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: !_isAnswered,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: context.responsive.fontSizeH2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'write_here'.tr(),
                          hintStyle: GoogleFonts.poppins(
                            color: AppColors.textDisabled,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: context.responsive.spacingM,
                            horizontal: context.responsive.spacingL,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              context.responsive.borderRadiusL,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              context.responsive.borderRadiusL,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _checkAnswer(),
                      ),
                      SizedBox(height: context.responsive.spacingM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: context.responsive.iconSizeS,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: context.responsive.spacingXS),
                          Text(
                            'case_sensitive_info'.tr(),
                            style: GoogleFonts.roboto(
                              fontSize: context.responsive.fontSizeCaption,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.responsive.spacingL),

                // Feedback card (after answer)
                if (_isAnswered) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.responsive.spacingM),
                    decoration: BoxDecoration(
                      color: _isCorrect
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        context.responsive.borderRadiusL,
                      ),
                      border: Border.all(
                        color: _isCorrect
                            ? AppColors.success.withOpacity(0.3)
                            : AppColors.error.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isCorrect ? AppColors.success : AppColors.error)
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
                                  ? AppColors.success
                                  : AppColors.error,
                              size: context.responsive.iconSizeL,
                            ),
                            SizedBox(width: context.responsive.spacingS),
                            Text(
                              _isCorrect ? 'correct'.tr() : 'wrong'.tr(),
                              style: GoogleFonts.poppins(
                                fontSize: context.responsive.fontSizeH3,
                                fontWeight: FontWeight.w700,
                                color: _isCorrect
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        if (!_isCorrect) ...[
                          SizedBox(height: context.responsive.spacingS),
                          Text(
                            'correct_answer'
                                .tr(args: [targetContent['word'] ?? '']),
                            style: GoogleFonts.poppins(
                              fontSize: context.responsive.fontSizeBody,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                        SizedBox(height: context.responsive.spacingS),
                        Text(
                          '${sourceContent['word']} (${sourceContent['meaning']})',
                          style: GoogleFonts.roboto(
                            fontSize: context.responsive.fontSizeBody,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),
                  SizedBox(height: context.responsive.spacingM),
                ],

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: context.responsive.value(
                    mobile: 56,
                    tablet: 60,
                    desktop: 64,
                  ),
                  child: ElevatedButton(
                    onPressed: _isAnswered ? _loadNextWord : _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAnswered
                          ? (_isCorrect ? AppColors.success : AppColors.error)
                          : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.responsive.borderRadiusL,
                        ),
                      ),
                      elevation: context.responsive.elevationHigh,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                    ),
                    child: Text(
                      _isAnswered ? 'continue'.tr() : 'check_answer'.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: context.responsive.fontSizeH3,
                        fontWeight: FontWeight.w700,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: context.responsive.spacingL),

                // Small footer: example sentence
                if (_isAnswered)
                  Text(
                    word.getSentence(
                        viewModel.proficiencyLevel, viewModel.targetLang),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: context.responsive.fontSizeBody,
                      color: AppColors.textSecondary,
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
