// lib/features/dashboard/presentation/views/dashboard_view.dart
//
// FAZ 12 — F12-07, F12-08, F12-11: Dashboard tam yeniden tasarım
//   - Quick stats row (streak, XP, bu hafta) — korundu
//   - Bugün detay kartı (DayDetailCard)
//   - Aktivite Isı Haritası (HeatmapWidget)
//   - Akıllı koç mesajı
//   - Bu hafta özet kartı (WeekSummaryCard)
//   - Aylık arşiv (ActivityHistoryList)
//   - Takvim görünümü (CalendarStatsView) — genişleyebilir

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/init/theme/app_theme_extension.dart';
import '../../../auth/presentation/state/auth_bloc.dart';
import '../state/dashboard_bloc.dart';
import '../widgets/activity_history_list.dart';
import '../widgets/calendar_stats_view.dart';
import '../widgets/dashboard_stats_grid.dart';
import '../widgets/day_detail_card.dart';
import '../widgets/heatmap_widget.dart';
import '../widgets/skill_radar_card.dart';
import '../widgets/word_tier_panel.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _calendarExpanded = false;

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
          body: RefreshIndicator(
            onRefresh: () async {
              context
                  .read<DashboardBloc>()
                  .add(const DashboardRefreshRequested());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: context.colors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // ── Hero Header ──────────────────────────────────────────
                _buildHeroHeader(context, state),

                if (state is DashboardLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state is DashboardError)
                  _buildErrorView(context, state)
                else if (state is DashboardLoaded)
                  _buildContent(context, state)
                else
                  const SliverFillRemaining(child: SizedBox()),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Hero Header ────────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildHeroHeader(
      BuildContext context, DashboardState state) {
    final authState = context.watch<AuthBloc>().state;
    final name = authState is AuthAuthenticated
        ? authState.profile.displayName
        : 'Öğrenci';

    final scheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.of(context).padding.top + 16,
          24,
          24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.surface, scheme.surfaceContainer],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selamlama row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: context.colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context
                      .read<DashboardBloc>()
                      .add(const DashboardRefreshRequested()),
                  icon: Icon(Icons.refresh_rounded,
                      color: context.colors.onSurfaceVariant),
                  style: IconButton.styleFrom(
                    backgroundColor: context.colors.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 20),

            // Quick stats — streak, XP, bu hafta
            if (state is DashboardLoaded)
              _QuickStatsRow(
                streak:
                    authState is AuthAuthenticated ? authState.streakDays : 0,
                totalXp: authState is AuthAuthenticated ? authState.totalXp : 0,
                weekQuestions: state.stats.weekQuestions,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın 👋';
    if (hour < 18) return 'İyi günler 👋';
    return 'İyi akşamlar 👋';
  }

  // ── Error View ────────────────────────────────────────────────────────────

  SliverFillRemaining _buildErrorView(
      BuildContext context, DashboardError state) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: context.colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(state.message,
                style: TextStyle(color: context.colors.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => context
                  .read<DashboardBloc>()
                  .add(const DashboardRefreshRequested()),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Content ──────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, DashboardLoaded state) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 8),

          // ── Genel istatistik grid ─────────────────────────────────
          _SectionLabel(
                  title: 'quick_stats'.tr(), icon: Icons.bar_chart_rounded)
              .animate()
              .fadeIn(delay: 150.ms),
          const SizedBox(height: 12),
          DashboardStatsGrid(stats: state.stats),
          const SizedBox(height: 28),

          // ── Bugün detay kartı ─────────────────────────────────────
          _SectionLabel(
                  title: 'Bugün',
                  icon: Icons.wb_sunny_rounded)
              .animate()
              .fadeIn(delay: 170.ms),
          const SizedBox(height: 12),
          DayDetailCard(stats: state.stats)
              .animate()
              .fadeIn(delay: 180.ms)
              .slideY(begin: 0.05),
          const SizedBox(height: 28),

          // ── Aktivite Isı Haritası ─────────────────────────────────
          _SectionLabel(
                  title: 'Aktivite Haritası',
                  icon: Icons.grid_view_rounded)
              .animate()
              .fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.12)),
            ),
            child: HeatmapWidget(
              data: state.stats.heatmapData,
            ),
          ).animate().fadeIn(delay: 210.ms),
          const SizedBox(height: 28),

          // ── Akıllı Koç ────────────────────────────────────────────
          if (state.coachMessage.isNotEmpty) ...[
            _CoachCard(message: state.coachMessage)
                .animate()
                .fadeIn(delay: 220.ms)
                .slideY(begin: 0.05),
            const SizedBox(height: 28),
          ],

          // ── Bu Hafta Özet ─────────────────────────────────────────
          _SectionLabel(
                  title: 'Bu Hafta',
                  icon: Icons.calendar_view_week_rounded)
              .animate()
              .fadeIn(delay: 230.ms),
          const SizedBox(height: 12),
          WeekSummaryCard(stats: state.stats)
              .animate()
              .fadeIn(delay: 240.ms)
              .slideY(begin: 0.05),
          const SizedBox(height: 28),

          // ── Takvim görünümü (genişleyebilir) ─────────────────────
          _ExpandableSection(
            title: 'Takvim',
            icon: Icons.calendar_month_rounded,
            expanded: _calendarExpanded,
            onToggle: () =>
                setState(() => _calendarExpanded = !_calendarExpanded),
            child: CalendarStatsView(
              heatmapData: state.stats.heatmapData,
            ),
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 28),

          // ── AI Coach Radar ────────────────────────────────────────
          _SectionLabel(
                  title: 'ai_coach_analysis'.tr(),
                  icon: Icons.auto_awesome_rounded)
              .animate()
              .fadeIn(delay: 260.ms),
          const SizedBox(height: 12),
          SkillRadarCard(
            volumeStats: state.volumeStats,
            accuracyStats: state.accuracyStats,
            message: state.coachMessage,
          ),
          const SizedBox(height: 28),

          // ── Kelime Seviyeleri ─────────────────────────────────────
          _SectionLabel(title: 'word_levels'.tr(), icon: Icons.layers_rounded)
              .animate()
              .fadeIn(delay: 280.ms),
          const SizedBox(height: 12),
          WordTierPanel(tierDistribution: state.stats.tierDistribution),
          const SizedBox(height: 28),

          // ── Aylık Arşiv ───────────────────────────────────────────
          _SectionLabel(
                  title: 'detailed_analysis'.tr(),
                  icon: Icons.timeline_rounded)
              .animate()
              .fadeIn(delay: 300.ms),
          const SizedBox(height: 12),
          ActivityHistoryList(monthlyActivity: state.monthlyActivity),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// QUICK STATS ROW
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickStatsRow extends StatelessWidget {
  final int streak;
  final int totalXp;
  final int weekQuestions;

  const _QuickStatsRow({
    required this.streak,
    required this.totalXp,
    required this.weekQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Row(
      children: [
        _QuickStatChip(
          icon: Icons.local_fire_department_rounded,
          label: '$streak',
          sublabel: 'gün seri',
          color: ext.tertiary,
        ),
        const SizedBox(width: 10),
        _QuickStatChip(
          icon: Icons.star_rounded,
          label: _formatXp(totalXp),
          sublabel: 'XP',
          color: scheme.primary,
        ),
        const SizedBox(width: 10),
        _QuickStatChip(
          icon: Icons.trending_up_rounded,
          label: '$weekQuestions',
          sublabel: 'bu hafta',
          color: ext.success,
        ),
      ],
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}k';
    return '$xp';
  }
}

class _QuickStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _QuickStatChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COACH CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _CoachCard extends StatelessWidget {
  final String message;
  const _CoachCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.auto_awesome_rounded,
                color: scheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Koç',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXPANDABLE SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class _ExpandableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.12)),
            ),
            child: child,
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION LABEL
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.colors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: context.colors.onSurface,
          ),
        ),
      ],
    );
  }
}
