import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../viewmodel/home_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';
import '../../viewmodel/main_viewmodel.dart';
import '../../viewmodel/review_viewmodel.dart';

import 'settings_screen.dart';
import 'multiple_choice_review_screen.dart';

import '../widgets/home/skill_radar_card.dart';
import '../widgets/home/dashboard_stats_grid.dart';
import '../widgets/home/word_tier_panel.dart';
import '../widgets/home/activity_history_list.dart';

import '../../core/extensions/responsive_extension.dart';
import '../../core/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _difficultWordsPopupShown = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.watch<HomeViewModel>();

    if (viewModel.difficultWords.length > 2 && !_difficultWordsPopupShown) {
      _difficultWordsPopupShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showDifficultWordsDialog(viewModel.difficultWords.length);
        }
      });
    }
  }

  Future<void> _quickStartTest() async {
    final reviewVM = context.read<ReviewViewModel>();
    final testMenuVM = context.read<TestMenuViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await testMenuVM.loadTestData();
      final status = await reviewVM.startReview(
        'daily',
        categoryFilter: ['all'],
        grammarFilter: ['all'],
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (status == ReviewStatus.success) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MultipleChoiceReviewScreen()),
        ).then((_) {
          if (mounted) {
            testMenuVM.loadTestData();
            context.read<HomeViewModel>().loadHomeData();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("daily_goal_completed".tr()),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
        context.read<MainViewModel>().changeTab(1);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Hızlı başlatma hatası: $e");
    }
  }

  void _shareProgress(BuildContext context) {
    final viewModel = context.read<HomeViewModel>();
    final shareText = viewModel.generateShareProgressText();

    if (shareText != null) {
      Share.share(shareText, subject: 'progress_share_subject'.tr());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('stats_not_loaded'.tr()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(context.responsive.borderRadiusM),
          ),
        ),
      );
    }
  }

  void _showDifficultWordsDialog(int difficultWordCount) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(context.responsive.borderRadiusXL),
        ),
        backgroundColor: AppColors.surface,
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(context.responsive.spacingM),
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: [AppColors.error, Colors.red[700]!]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.surface,
                size: context.responsive.iconSizeL,
              ),
            ),
            SizedBox(height: context.responsive.spacingM),
            Text(
              'difficult_words_detected'.tr(),
              style: GoogleFonts.poppins(
                fontSize: context.responsive.fontSizeH3,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'difficult_words_description'
              .tr()
              .replaceFirst('{}', difficultWordCount.toString()),
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeBody,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(context.responsive.borderRadiusL),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.spacingL,
                  vertical: context.responsive.spacingM,
                ),
                elevation: context.responsive.elevationMedium,
              ),
              child: Text(
                'understood'.tr(),
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeBody,
                  color: AppColors.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'dashboard_title'.tr(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: context.responsive.fontSizeH2,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: context.responsive.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(context.responsive.borderRadiusM),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.share_rounded,
                    color: AppColors.primary,
                    size: context.responsive.iconSizeM,
                  ),
                  onPressed: () => _shareProgress(context),
                  tooltip: 'share'.tr(),
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: context.responsive.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(context.responsive.borderRadiusM),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.settings_rounded,
                    color: AppColors.info,
                    size: context.responsive.iconSizeM,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  tooltip: 'settings'.tr(),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: context.responsive.paddingPage.copyWith(top: 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(height: context.responsive.spacingM),
                _buildSectionHeader(
                  'ai_coach_analysis'.tr(),
                  'skill_volume_analysis'.tr(),
                  AppColors.gradientPurple,
                  context,
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                SizedBox(height: context.responsive.spacingM),
                SkillRadarCard(
                  volumeStats: viewModel.volumeStats,
                  accuracyStats: viewModel.accuracyStats,
                  message: viewModel.coachMessage,
                ),
                SizedBox(height: context.responsive.spacingL),
                _buildSectionHeader(
                  'quick_stats'.tr(),
                  'daily_weekly_monthly_performance'.tr(),
                  AppColors.gradientBlue,
                  context,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                SizedBox(height: context.responsive.spacingM),
                DashboardStatsGrid(
                  stats: viewModel.stats,
                ),
                SizedBox(height: context.responsive.spacingL),
                _buildSectionHeader(
                  'word_levels'.tr(),
                  'word_level_distribution'.tr(),
                  AppColors.gradientGreen,
                  context,
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                SizedBox(height: context.responsive.spacingM),
                WordTierPanel(
                  tierDistribution: viewModel.stats?.tierDistribution ?? {},
                ),
                SizedBox(height: context.responsive.spacingL),
                _buildSectionHeader(
                  'detailed_analysis'.tr(),
                  'monthly_weekly_activity_history'.tr(),
                  AppColors.gradientPink,
                  context,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                SizedBox(height: context.responsive.spacingM),
                const ActivityHistoryList(),
                SizedBox(height: context.responsive.fabMarginBottom),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: context.responsive.fabMarginBottom),
        child: FloatingActionButton.extended(
          onPressed: _quickStartTest,
          backgroundColor: AppColors.primary,
          elevation: context.responsive.elevationHigh,
          icon: Icon(
            Icons.rocket_launch_rounded,
            color: AppColors.surface,
            size: context.responsive.iconSizeM,
          ),
          label: Text(
            'quick_start'.tr(),
            style: GoogleFonts.poppins(
              color: AppColors.surface,
              fontWeight: FontWeight.w600,
              fontSize: context.responsive.fontSizeBody,
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
            duration: 2000.ms, color: AppColors.surface.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    List<Color> gradientColors,
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: context.responsive.value(
            mobile: 32,
            tablet: 36,
            desktop: 40,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: context.responsive.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeH3,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeCaption,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
