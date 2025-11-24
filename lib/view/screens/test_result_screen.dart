import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/models/word_model.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../../viewmodel/review_viewmodel.dart';
import '../../viewmodel/settings_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';
import 'multiple_choice_review_screen.dart';
import '../../core/extensions/responsive_extension.dart';
import '../../core/constants/app_colors.dart';

class TestResultScreen extends StatefulWidget {
  final int correctCount;
  final int incorrectCount;
  final List<Word> wrongWords;

  const TestResultScreen({
    super.key,
    required this.correctCount,
    required this.incorrectCount,
    required this.wrongWords,
  });

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _setupTts();
    _saveResultAndRefreshData();
  }

  void _saveResultAndRefreshData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final reviewVM = context.read<ReviewViewModel>();
      await reviewVM.saveTestResult();

      if (!mounted) return;
      // Diğer ekranların verilerini tazele
      context.read<HomeViewModel>().loadHomeData();
      context.read<TestMenuViewModel>().loadTestData();
    });
  }

  void _setupTts() async {
    // TTS dilini ayarlardan al
    final targetLang = context.read<SettingsViewModel>().targetLang;
    await flutterTts.setLanguage(targetLang == 'en' ? 'en-US' : targetLang);
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _repeatWrongWords() async {
    final viewModel = context.read<ReviewViewModel>();
    await viewModel.startReviewWithWords(widget.wrongWords);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const MultipleChoiceReviewScreen()),
    );
  }

  Future<void> _startNewDailyTest() async {
    final viewModel = context.read<ReviewViewModel>();
    await viewModel.startReview('daily');

    if (!mounted) return;

    if (viewModel.reviewQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('test_result_daily_complete'.tr()),
          backgroundColor: AppColors.info,
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MultipleChoiceReviewScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ayarları al (Dil gösterimi için)
    final settings = context.watch<SettingsViewModel>();

    final int correct = widget.correctCount;
    final int incorrect = widget.incorrectCount;
    final int total = correct + incorrect;
    final double successRate = (total == 0) ? 0 : (correct / total) * 100;

    String resultTitle;
    IconData resultIcon;
    Color resultColor;

    if (successRate >= 80) {
      resultTitle = 'test_result_excellent'.tr();
      resultIcon = Icons.emoji_events;
      resultColor = AppColors.success;
    } else if (successRate >= 50) {
      resultTitle = 'test_result_good'.tr();
      resultIcon = Icons.thumb_up_alt;
      resultColor = AppColors.info;
    } else {
      resultTitle = 'test_result_completed'.tr();
      resultIcon = Icons.check_circle_outline;
      resultColor = AppColors.warning;
    }

    final wrongWords = widget.wrongWords;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'test_result_title'.tr(),
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeH2,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: resultColor.withOpacity(0.8),
        foregroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: context.responsive.paddingPage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BAŞLIK VE İKON
            Icon(
              resultIcon,
              size: context.responsive.value(
                mobile: 80,
                tablet: 100,
                desktop: 120,
              ),
              color: resultColor,
            ).animate().scale(duration: 600.ms, curve: Curves.bounceOut),

            SizedBox(height: context.responsive.spacingL),

            Text(
              resultTitle,
              style: GoogleFonts.poppins(
                fontSize: context.responsive.fontSizeH1,
                color: resultColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),

            SizedBox(height: context.responsive.spacingS),

            Text(
              'test_result_saved'.tr(),
              style: GoogleFonts.poppins(
                fontSize: context.responsive.fontSizeBody,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),

            SizedBox(height: context.responsive.spacingXL),

            // İSTATİSTİK KARTLARI
            Container(
              padding: EdgeInsets.all(context.responsive.spacingL),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(context.responsive.borderRadiusXL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                      'correct'.tr(), '$correct', AppColors.success),
                  _buildStatColumn(
                      'incorrect'.tr(), '$incorrect', AppColors.error),
                  _buildStatColumn(
                    'success_rate'.tr(),
                    '%${successRate.toStringAsFixed(0)}',
                    AppColors.primary,
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.3, duration: 500.ms),

            SizedBox(height: context.responsive.spacingXL),

            // YANLIŞ KELİMELER LİSTESİ
            if (wrongWords.isNotEmpty) ...[
              Text(
                'test_result_wrong_words'.tr(),
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeH2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn(delay: 400.ms),
              SizedBox(height: context.responsive.spacingM),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wrongWords.length,
                itemBuilder: (context, index) {
                  final word = wrongWords[index];
                  final targetContent =
                      word.getLocalizedContent(settings.targetLang);
                  final sourceContent =
                      word.getLocalizedContent(settings.sourceLang);

                  return Container(
                    margin: EdgeInsets.symmetric(
                        vertical: context.responsive.spacingXS),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                          context.responsive.borderRadiusL),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: context.responsive.spacingM,
                        vertical: context.responsive.spacingS,
                      ),
                      title: Text(
                        targetContent['word']!,
                        style: GoogleFonts.poppins(
                          fontSize: context.responsive.fontSizeBody,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        sourceContent['meaning']!,
                        style: GoogleFonts.poppins(
                          fontSize: context.responsive.fontSizeCaption,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.volume_up,
                          color: AppColors.primary,
                          size: context.responsive.iconSizeM,
                        ),
                        onPressed: () => _speak(targetContent['word']!),
                      ),
                    ),
                  ).animate(delay: (index * 150).ms).fadeIn();
                },
              ),
              SizedBox(height: context.responsive.spacingXL),
            ],

            // BUTONLAR
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: resultColor,
                      foregroundColor: AppColors.surface,
                      padding: EdgeInsets.symmetric(
                          vertical: context.responsive.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            context.responsive.borderRadiusXL),
                      ),
                      elevation: context.responsive.elevationMedium,
                    ),
                    child: Text(
                      'btn_home'.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: context.responsive.fontSizeH3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ).animate().scale(delay: 500.ms),
                if (wrongWords.isNotEmpty) ...[
                  SizedBox(height: context.responsive.spacingS),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.replay,
                        size: context.responsive.iconSizeM,
                      ),
                      label: Text('test_result_repeat_wrong'.tr()),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: context.responsive.spacingM),
                        side: BorderSide(color: resultColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              context.responsive.borderRadiusXL),
                        ),
                      ),
                      onPressed: _repeatWrongWords,
                    ),
                  ).animate().scale(delay: 600.ms),
                ],
                SizedBox(height: context.responsive.spacingS),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.refresh,
                      size: context.responsive.iconSizeM,
                    ),
                    label: Text('test_result_new_test'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      padding: EdgeInsets.symmetric(
                          vertical: context.responsive.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            context.responsive.borderRadiusXL),
                      ),
                      elevation: context.responsive.elevationMedium,
                    ),
                    onPressed: _startNewDailyTest,
                  ),
                ).animate().scale(delay: 700.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: context.responsive.value(
              mobile: 24,
              tablet: 28,
              desktop: 32,
            ),
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.responsive.spacingXS),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeCaption,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
