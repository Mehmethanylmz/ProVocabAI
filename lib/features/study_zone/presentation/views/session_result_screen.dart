// lib/features/study_zone/presentation/views/session_result_screen.dart
//
// Blueprint T-13: StudyZoneCompleted state'den totalCards, correctCards,
// xpEarned, accuracy%, totalTimeMs, wrongWords listesi (accordion),
// Rewarded "2x XP" CTA, "Ana Sayfa" ve "Tekrar Çalış" butonları.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/study_zone_bloc.dart';
import '../state/study_zone_event.dart';
import '../state/study_zone_state.dart';

// ── SessionResultScreen ───────────────────────────────────────────────────────

class SessionResultScreen extends StatelessWidget {
  const SessionResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<StudyZoneBloc>().state;

    if (state is! StudyZoneCompleted) {
      // Doğrudan navigate edilmişse fallback
      return const Scaffold(
        body: Center(child: Text('Sonuç bulunamadı')),
      );
    }

    return _ResultBody(state: state);
  }
}

// ── _ResultBody ───────────────────────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  final StudyZoneCompleted state;
  const _ResultBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Hero header
            SliverToBoxAdapter(
              child: _ResultHeader(state: state),
            ),

            // İstatistik grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverToBoxAdapter(
                child: _StatsGrid(state: state),
              ),
            ),

            // 2x XP rewarded CTA
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverToBoxAdapter(
                child: _RewardedXPBanner(
                  onTap: () {
                    // AdService.showRewarded → RewardedAdCompleted(doubleXP)
                    // Sprint 4'te bağlanacak
                  },
                ),
              ),
            ),

            // Yanlış kelimeler accordion
            if (state.wrongWordIds.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: _WrongWordsAccordion(wordIds: state.wrongWordIds),
                ),
              ),

            // Butonlar
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _ActionButtons(state: state),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _ResultHeader ─────────────────────────────────────────────────────────────

class _ResultHeader extends StatelessWidget {
  final StudyZoneCompleted state;
  const _ResultHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accuracy = state.accuracy;
    final emoji = accuracy >= 0.8
        ? '🎉'
        : accuracy >= 0.5
            ? '👍'
            : '💪';

    return Container(
      key: const Key('result_header'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.secondaryContainer,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            'Oturum Tamamlandı!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          // Accuracy yüzdesi
          Text(
            '%${(accuracy * 100).round()} doğruluk',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimaryContainer.withOpacity(0.75),
                ),
          ),
          const SizedBox(height: 16),
          // XP badge
          _XPBadge(xp: state.xpEarned),
        ],
      ),
    );
  }
}

// ── _StatsGrid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final StudyZoneCompleted state;
  const _StatsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final minutes = (state.totalTimeMs / 60000).ceil();

    return GridView.count(
      key: const Key('stats_grid'),
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          key: const Key('stat_total'),
          icon: Icons.layers_rounded,
          label: 'Toplam Kart',
          value: '${state.totalCards}',
          color: const Color(0xFF5C6BC0),
        ),
        _StatCard(
          key: const Key('stat_correct'),
          icon: Icons.check_circle_rounded,
          label: 'Doğru',
          value: '${state.correctCards}',
          color: const Color(0xFF43A047),
        ),
        _StatCard(
          key: const Key('stat_wrong'),
          icon: Icons.cancel_rounded,
          label: 'Yanlış',
          value: '${state.totalCards - state.correctCards}',
          color: const Color(0xFFE53935),
        ),
        _StatCard(
          key: const Key('stat_time'),
          icon: Icons.timer_rounded,
          label: 'Süre',
          value: '$minutes dk',
          color: const Color(0xFFFB8C00),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _RewardedXPBanner ─────────────────────────────────────────────────────────

class _RewardedXPBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _RewardedXPBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('rewarded_xp_banner'),
      color: Colors.amber.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.play_circle_filled,
                  color: Colors.amber, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2x XP Kazan!',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.amber,
                      ),
                    ),
                    Text(
                      'Kısa bir video izle, XP/’ini ikiye katla',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.amber),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _WrongWordsAccordion ──────────────────────────────────────────────────────

class _WrongWordsAccordion extends StatelessWidget {
  final List<int> wordIds;
  const _WrongWordsAccordion({required this.wordIds});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const Key('wrong_words_accordion'),
        leading: const Icon(Icons.refresh_rounded, color: Color(0xFFE53935)),
        title: Text(
          'Tekrar Edilecekler (${wordIds.length})',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        children: wordIds
            .map(
              (id) => ListTile(
                key: Key('wrong_word_$id'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.circle, size: 8, color: Color(0xFFE53935)),
                title:
                    Text('Kelime #$id', style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── _ActionButtons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final StudyZoneCompleted state;
  const _ActionButtons({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tekrar Çalış
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('retry_button'),
              onPressed: () {
                context.read<StudyZoneBloc>().add(
                      const LoadPlanRequested(
                        targetLang: 'en',
                        categories: [],
                        newWordsGoal: 10,
                      ),
                    );
                Navigator.of(context).pushReplacementNamed('/study_zone');
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Çalış',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Ana Sayfa
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('home_button'),
              onPressed: () {
                context.read<StudyZoneBloc>().add(const SessionAborted());
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (_) => false);
              },
              icon: const Icon(Icons.home_rounded),
              label: const Text('Ana Sayfa',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small Widgets ─────────────────────────────────────────────────────────────

class _XPBadge extends StatelessWidget {
  final int xp;
  const _XPBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
          const SizedBox(width: 6),
          Text(
            '+$xp XP',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
