import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/di/injection_container.dart';
import '../view_model/dashboard_view_model.dart';
import '../widgets/skill_radar_card.dart';
import '../widgets/dashboard_stats_grid.dart';
import '../widgets/word_tier_panel.dart';
import '../widgets/activity_history_list.dart';
import '../../../settings/presentation/view/settings_view.dart';

// Study Zone Entegrasyonu
import '../../../study_zone/presentation/view_model/study_view_model.dart';
import '../../../study_zone/presentation/view_model/menu_view_model.dart';
import '../../../study_zone/presentation/view/quiz_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseView<DashboardViewModel>(
      viewModel: locator<DashboardViewModel>(),
      onModelReady: (model) {
        model.setContext(context);
        model.loadHomeData();
      },
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, viewModel),
              SliverPadding(
                padding: context.responsive.paddingPage.copyWith(top: 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: context.responsive.spacingM),
                    _buildSectionHeader(
                      context,
                      'ai_coach_analysis'.tr(),
                      'skill_volume_analysis'.tr(),
                      context.ext.gradientPurple,
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                    SizedBox(height: context.responsive.spacingM),
                    SkillRadarCard(
                      volumeStats: viewModel.volumeStats,
                      accuracyStats: viewModel.accuracyStats,
                      message: viewModel.coachMessage,
                    ),
                    SizedBox(height: context.responsive.spacingL),
                    _buildSectionHeader(
                      context,
                      'quick_stats'.tr(),
                      'daily_weekly_monthly_performance'.tr(),
                      context.ext.gradientBlue,
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                    SizedBox(height: context.responsive.spacingM),
                    DashboardStatsGrid(stats: viewModel.stats),
                    SizedBox(height: context.responsive.spacingL),
                    _buildSectionHeader(
                      context,
                      'word_levels'.tr(),
                      'word_level_distribution'.tr(),
                      [
                        context.ext.success,
                        context.ext.success.withOpacity(0.6)
                      ],
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                    SizedBox(height: context.responsive.spacingM),
                    WordTierPanel(
                        tierDistribution:
                            viewModel.stats?.tierDistribution ?? {}),
                    SizedBox(height: context.responsive.spacingL),
                    _buildSectionHeader(
                      context,
                      'detailed_analysis'.tr(),
                      'monthly_weekly_activity_history'.tr(),
                      [
                        context.colors.error,
                        context.colors.error.withOpacity(0.6)
                      ],
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
            padding:
                EdgeInsets.only(bottom: context.responsive.fabMarginBottom),
            child: FloatingActionButton.extended(
              onPressed: () => _quickStartTest(context),
              backgroundColor: context.colors.primary,
              elevation: context.responsive.elevationHigh,
              icon: Icon(Icons.rocket_launch_rounded,
                  color: context.colors.onPrimary),
              label: Text(
                'quick_start'.tr(),
                style: GoogleFonts.poppins(
                  color: context.colors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(
      BuildContext context, DashboardViewModel viewModel) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: context.colors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'dashboard_title'.tr(),
        style: context.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.colors.onSurface,
        ),
      ),
      actions: [
        _buildActionButton(
          context,
          icon: Icons.share_rounded,
          color: context.colors.primary,
          onTap: () {
            final text = viewModel.generateShareProgressText();
            if (text != null) Share.share(text);
          },
        ),
        _buildActionButton(
          context,
          icon: Icons.settings_rounded,
          color: context.ext.info,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsView()),
          ),
        ),
        SizedBox(width: context.responsive.spacingM),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.only(right: context.responsive.spacingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusM),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: context.responsive.iconSizeM),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      String subtitle, List<Color> gradient) {
    return Row(
      children: [
        Container(
          width: 4,
          height: context.responsive.value(mobile: 32, tablet: 36, desktop: 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
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
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                subtitle,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _quickStartTest(BuildContext context) async {
    final studyVM = locator<StudyViewModel>();
    final menuVM = locator<MenuViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
          child: CircularProgressIndicator(color: context.colors.primary)),
    );

    // Günlük testi başlat
    await studyVM.startReview('daily');

    if (!context.mounted) return;
    Navigator.pop(context);

    if (studyVM.status == StudyStatus.success) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuizView()),
      );

      // Testten dönünce dashboard'u yenile
      if (context.mounted) {
        locator<DashboardViewModel>().loadHomeData();
        menuVM.loadMenuData();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('daily_goal_completed'.tr()),
          backgroundColor: context.ext.success,
        ),
      );
    }
  }
}
