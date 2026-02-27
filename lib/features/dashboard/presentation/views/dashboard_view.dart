// lib/features/dashboard/presentation/view/dashboard_view.dart
//
// REWRITE v2: DashboardStats → DashboardStatsEntity (mevcut widget imzasıyla uyumlu)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../state/dashboard_bloc.dart';
import '../widgets/activity_history_list.dart';
import '../widgets/dashboard_stats_grid.dart';
import '../widgets/skill_radar_card.dart';
import '../widgets/word_tier_panel.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardBloc>().add(const DashboardLoadRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              if (state is DashboardLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is DashboardError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 8),
                        Text(state.message),
                        TextButton(
                          onPressed: () => context
                              .read<DashboardBloc>()
                              .add(const DashboardRefreshRequested()),
                          child: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state is DashboardLoaded)
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
                        volumeStats: state.volumeStats,
                        accuracyStats: state.accuracyStats,
                        message: state.coachMessage,
                      ),
                      SizedBox(height: context.responsive.spacingL),
                      _buildSectionHeader(
                        context,
                        'quick_stats'.tr(),
                        'daily_weekly_monthly_performance'.tr(),
                        context.ext.gradientBlue,
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                      SizedBox(height: context.responsive.spacingM),
                      // DashboardStatsGrid DashboardStatsEntity? alıyor — doğrudan geç
                      DashboardStatsGrid(stats: state.stats),
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
                          tierDistribution: state.stats.tierDistribution),
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
                      ActivityHistoryList(
                          monthlyActivity: state.monthlyActivity),
                      SizedBox(height: context.responsive.fabMarginBottom),
                    ]),
                  ),
                )
              else
                const SliverFillRemaining(child: SizedBox()),
            ],
          ),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
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
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context
              .read<DashboardBloc>()
              .add(const DashboardRefreshRequested()),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      String subtitle, List<Color> gradient) {
    return Row(
      children: [
        Container(
          width: 4,
          height: context.responsive
              .value(mobile: 32, tablet: 36, desktop: 40)
              .toDouble(),
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
              Text(title,
                  style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              Text(subtitle,
                  style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.6))),
            ],
          ),
        ),
      ],
    );
  }
}
