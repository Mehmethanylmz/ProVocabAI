import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/models/word_model.dart';
import '../../viewmodel/review_viewmodel.dart';
import 'test_result_screen.dart';
import '../../core/extensions/responsive_extension.dart';
import '../../core/constants/app_colors.dart';

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
        SnackBar(
          content: Text('speaking_no_audio'.tr()),
          backgroundColor: AppColors.error,
        ),
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "speaking_test".tr(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: context.responsive.fontSizeH2,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          child: Padding(
            padding: context.responsive.paddingPage,
            child: Column(
              children: [
                // KELİME KARTI
                Container(
                  padding: EdgeInsets.all(context.responsive.spacingXL),
                  width: double.infinity,
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
                      Text(
                        targetContent['word'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: context.responsive.value(
                            mobile: 40,
                            tablet: 48,
                            desktop: 56,
                          ),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().scale(
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          ),
                      SizedBox(height: context.responsive.spacingM),
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
                        ),
                        child: Icon(
                          Icons.volume_up,
                          size: context.responsive.value(
                            mobile: 28,
                            tablet: 32,
                            desktop: 36,
                          ),
                        ),
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
                    padding: EdgeInsets.all(context.responsive.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                          context.responsive.borderRadiusL),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      "“${viewModel.spokenText}”",
                      style: GoogleFonts.poppins(
                        fontSize: context.responsive.fontSizeH3,
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),

                SizedBox(height: context.responsive.spacingL),

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

                SizedBox(height: context.responsive.spacingM),

                if (!_isAnswered)
                  Text(
                    viewModel.isListening
                        ? "speaking_listening".tr()
                        : "speaking_hold_to_talk".tr(),
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: context.responsive.fontSizeBody,
                    ),
                  ),

                if (_isAnswered)
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              context.responsive.borderRadiusL),
                        ),
                        elevation: context.responsive.elevationHigh,
                      ),
                      child: Text(
                        "btn_continue".tr(),
                        style: GoogleFonts.poppins(
                          fontSize: context.responsive.fontSizeH3,
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
      width: context.responsive.value(
        mobile: isListening ? 100 : 80,
        tablet: isListening ? 110 : 90,
        desktop: isListening ? 120 : 100,
      ),
      height: context.responsive.value(
        mobile: isListening ? 100 : 80,
        tablet: isListening ? 110 : 90,
        desktop: isListening ? 120 : 100,
      ),
      decoration: BoxDecoration(
        color: isListening ? AppColors.error : AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isListening ? AppColors.error : AppColors.primary)
                .withOpacity(0.4),
            blurRadius: context.responsive.value(
              mobile: 20,
              tablet: 25,
              desktop: 30,
            ),
            spreadRadius: context.responsive.value(
              mobile: 6,
              tablet: 8,
              desktop: 10,
            ),
          ),
        ],
      ),
      child: Icon(
        isListening ? Icons.mic : Icons.mic_none,
        color: AppColors.surface,
        size: context.responsive.value(
          mobile: isListening ? 40 : 34,
          tablet: isListening ? 46 : 40,
          desktop: isListening ? 52 : 46,
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildFeedbackCard() {
    return Container(
      padding: EdgeInsets.all(context.responsive.spacingL),
      margin: EdgeInsets.only(top: context.responsive.spacingS),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _isCorrect
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
        boxShadow: [
          BoxShadow(
            color: (_isCorrect ? AppColors.success : AppColors.error)
                .withOpacity(0.18),
            blurRadius: 25,
          ),
        ],
        border: Border.all(
          color: _isCorrect
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.cancel,
            size: context.responsive.iconSizeL,
            color: _isCorrect ? AppColors.success : AppColors.error,
          ),
          SizedBox(width: context.responsive.spacingM),
          Text(
            _isCorrect ? "speaking_perfect".tr() : "speaking_try_again".tr(),
            style: GoogleFonts.poppins(
              fontSize: context.responsive.fontSizeH3,
              color: _isCorrect ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.3);
  }
}
