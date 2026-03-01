// lib/features/dashboard/presentation/widgets/dashboard_stats_grid.dart
//
// FAZ 8B: Premium stat kartları
//   - Gradient border + subtle background
//   - Inter tipografi
//   - Staggered fade-in animasyonu
//   - Deprecated withOpacity → withValues

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../domain/entities/dashboard_stats_entity.dart';

class DashboardStatsGrid extends StatelessWidget {
  final DashboardStatsEntity? stats;

  const DashboardStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) return _buildLoading(context);

    final cards = [
      _CardData(
        title: 'stats_today'.tr(),
        value: '${stats?.todayQuestions ?? 0}',
        subtitle: '%${stats?.todaySuccessRate.toStringAsFixed(0) ?? 0}',
        subtitleLabel: 'success_rate'.tr(),
        gradient: context.ext.gradientAccent,
        icon: Icons.today_rounded,
      ),
      _CardData(
        title: 'stats_week'.tr(),
        value: '${stats?.weekQuestions ?? 0}',
        subtitle: '%${stats?.weekSuccessRate.toStringAsFixed(0) ?? 0}',
        subtitleLabel: 'success_rate'.tr(),
        gradient: context.ext.gradientSuccess,
        icon: Icons.calendar_view_week_rounded,
      ),
      _CardData(
        title: 'stats_month'.tr(),
        value: '${stats?.monthQuestions ?? 0}',
        subtitle: '%${stats?.monthSuccessRate.toStringAsFixed(0) ?? 0}',
        subtitleLabel: 'success_rate'.tr(),
        gradient: context.ext.gradientGold,
        icon: Icons.calendar_month_rounded,
      ),
      _CardData(
        title: 'stats_mastered'.tr(),
        value: '${stats?.masteredWords ?? 0}',
        subtitle: null,
        subtitleLabel: 'words'.tr(),
        gradient: context.ext.gradientPrimary.take(2).toList(),
        icon: Icons.workspace_premium_rounded,
      ),
    ];

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.responsive.value(mobile: 2, tablet: 4),
        childAspectRatio: context.responsive.value(mobile: 1.35, tablet: 1.5),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      itemBuilder: (context, i) => _StatCard(data: cards[i])
          .animate(delay: (i * 80).ms)
          .fadeIn()
          .slideY(begin: 0.08),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.responsive.value(mobile: 2, tablet: 4),
        childAspectRatio: context.responsive.value(mobile: 1.35, tablet: 1.5),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 1500.ms,
            color: context.colors.surface.withValues(alpha: 0.5),
          ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final _CardData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColor = data.gradient.first;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? gradientColor.withValues(alpha: 0.06)
            : context.colors.surfaceContainer,
        border: Border.all(
          color: gradientColor.withValues(alpha: isDark ? 0.15 : 0.1),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: gradientColor.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: data.gradient),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.colors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Value
            Text(
              data.value,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: gradientColor,
                letterSpacing: -0.5,
              ),
            ),

            // Subtitle
            if (data.subtitle != null)
              Row(
                children: [
                  Text(
                    data.subtitleLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: gradientColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      data.subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: gradientColor,
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                data.subtitleLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardData {
  final String title;
  final String value;
  final String? subtitle;
  final String subtitleLabel;
  final List<Color> gradient;
  final IconData icon;

  const _CardData({
    required this.title,
    required this.value,
    this.subtitle,
    required this.subtitleLabel,
    required this.gradient,
    required this.icon,
  });
}
