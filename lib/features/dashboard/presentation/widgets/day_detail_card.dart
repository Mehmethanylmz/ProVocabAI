// lib/features/dashboard/presentation/widgets/day_detail_card.dart
//
// FAZ 12 — F12-06: Bugün (veya seçili gün) detay kartı
//   - Soru, doğru, yanlış, süre
//   - Mod dağılımı satırı (MCQ/Dinleme/Konuşma)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/init/theme/app_theme_extension.dart';
import '../../domain/entities/dashboard_stats_entity.dart';

class DayDetailCard extends StatelessWidget {
  final DashboardStatsEntity stats;

  const DayDetailCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final hasTodayActivity = stats.todayQuestions > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: hasTodayActivity
          ? _buildContent(context, scheme)
          : _buildEmpty(context, scheme),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme scheme) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stat satırı ───────────────────────────────────────────────────
        Row(
          children: [
            _StatItem(
              value: '${stats.todayQuestions}',
              label: 'soru',
              color: scheme.primary,
              icon: Icons.quiz_rounded,
            ),
            const SizedBox(width: 16),
            _StatItem(
              value: '${stats.todayCorrect}',
              label: 'doğru',
              color: ext.success,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(width: 16),
            _StatItem(
              value: '${stats.todayWrong}',
              label: 'yanlış',
              color: scheme.error,
              icon: Icons.cancel_rounded,
            ),
            if (stats.todayTimeMinutes > 0) ...[
              const SizedBox(width: 16),
              _StatItem(
                value: '${stats.todayTimeMinutes}',
                label: 'dakika',
                color: ext.tertiary,
                icon: Icons.timer_rounded,
              ),
            ],
          ],
        ),

        // ── Doğruluk çubuğu ───────────────────────────────────────────────
        if (stats.todayQuestions > 0) ...[
          const SizedBox(height: 12),
          _AccuracyBar(
            correct: stats.todayCorrect,
            total: stats.todayQuestions,
          ),
        ],

        // ── Mod dağılımı ──────────────────────────────────────────────────
        if (stats.todayModeDistribution.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ModeDistributionRow(modeMap: stats.todayModeDistribution),
        ],
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, ColorScheme scheme) {
    return Row(
      children: [
        Icon(
          Icons.sunny_snowing,
          color: scheme.onSurface.withValues(alpha: 0.3),
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          'Bugün henüz çalışmadın',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

// ── Week Summary Card ─────────────────────────────────────────────────────────

/// Bu hafta özet kartı — F12-07
class WeekSummaryCard extends StatelessWidget {
  final DashboardStatsEntity stats;

  const WeekSummaryCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: stats.weekQuestions == 0
          ? Row(
              children: [
                Icon(Icons.calendar_view_week_rounded,
                    color: scheme.onSurface.withValues(alpha: 0.3), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Bu hafta henüz çalışmadın',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatItem(
                      value: '${stats.weekQuestions}',
                      label: 'soru',
                      color: scheme.primary,
                      icon: Icons.quiz_rounded,
                    ),
                    const SizedBox(width: 16),
                    _StatItem(
                      value: '${stats.weekCorrect}',
                      label: 'doğru',
                      color: ext.success,
                      icon: Icons.check_circle_rounded,
                    ),
                    const SizedBox(width: 16),
                    _StatItem(
                      value: '${stats.weekWrong}',
                      label: 'yanlış',
                      color: scheme.error,
                      icon: Icons.cancel_rounded,
                    ),
                    if (stats.weekTimeMinutes > 0) ...[
                      const SizedBox(width: 16),
                      _StatItem(
                        value: '${stats.weekTimeMinutes}',
                        label: 'dk',
                        color: ext.tertiary,
                        icon: Icons.timer_rounded,
                      ),
                    ],
                  ],
                ),
                if (stats.weekQuestions > 0) ...[
                  const SizedBox(height: 12),
                  _AccuracyBar(
                    correct: stats.weekCorrect,
                    total: stats.weekQuestions,
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccuracyBar extends StatelessWidget {
  final int correct;
  final int total;
  const _AccuracyBar({required this.correct, required this.total});

  @override
  Widget build(BuildContext context) {
    final rate = total > 0 ? correct / total : 0.0;
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    final rateColor = rate >= 0.8
        ? ext.success
        : rate >= 0.6
            ? ext.tertiary
            : scheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Doğruluk',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            Text(
              '%${(rate * 100).toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: rateColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 5,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(rateColor),
          ),
        ),
      ],
    );
  }
}

class _ModeDistributionRow extends StatelessWidget {
  final Map<String, int> modeMap;

  const _ModeDistributionRow({required this.modeMap});

  String _modeLabel(String mode) => switch (mode) {
        'mcq' => 'Test',
        'listening' => 'Dinleme',
        'speaking' => 'Konuşma',
        'vocabulary' => 'Kelime',
        _ => mode,
      };

  IconData _modeIcon(String mode) => switch (mode) {
        'mcq' => Icons.quiz_rounded,
        'listening' => Icons.hearing_rounded,
        'speaking' => Icons.mic_rounded,
        'vocabulary' => Icons.book_rounded,
        _ => Icons.circle,
      };

  Color _modeColor(String mode, ColorScheme scheme, AppThemeExtension ext) =>
      switch (mode) {
        'mcq' => scheme.primary,
        'listening' => ext.tertiary,
        'speaking' => scheme.secondary,
        'vocabulary' => ext.success,
        _ => scheme.primary,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    final entries = modeMap.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: entries.map((e) {
        final color = _modeColor(e.key, scheme, ext);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_modeIcon(e.key), size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                '${_modeLabel(e.key)}: ${e.value}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
