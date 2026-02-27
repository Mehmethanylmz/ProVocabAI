// lib/features/study_zone/presentation/views/session_result_screen.dart
//
// FIX: "Ana Sayfa" butonu crash → NavigationService.navigateToPageClear(/main)
// FIX: "Tekrar Çalış" → popUntil(study_zone) — BlocProvider.value stack'ini temizler

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../state/study_zone_bloc.dart';
import '../state/study_zone_state.dart';

class SessionResultScreen extends StatelessWidget {
  const SessionResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<StudyZoneBloc>().state;
    if (state is! StudyZoneCompleted) {
      return const Scaffold(body: Center(child: Text('Sonuç bulunamadı')));
    }
    return _ResultBody(state: state);
  }
}

class _ResultBody extends StatelessWidget {
  final StudyZoneCompleted state;
  const _ResultBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accuracy =
        state.totalCards > 0 ? state.correctCards / state.totalCards : 0.0;
    final emoji = accuracy >= 0.8
        ? '🏆'
        : accuracy >= 0.5
            ? '👍'
            : '💪';
    final minutes = (state.totalTimeMs / 60000).ceil();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 12),
                    Text(
                      'Oturum Tamamlandı!',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+${state.xpEarned} XP kazandın',
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats Grid ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                        label: 'Toplam Kart',
                        value: '${state.totalCards}',
                        icon: Icons.layers_rounded),
                    _StatCard(
                        label: 'Doğru',
                        value: '${state.correctCards}',
                        icon: Icons.check_circle_outline,
                        color: Colors.green),
                    _StatCard(
                        label: 'Başarı',
                        value: '%${(accuracy * 100).toStringAsFixed(0)}',
                        icon: Icons.emoji_events_rounded,
                        color: Colors.amber),
                    _StatCard(
                        label: 'Süre',
                        value: '$minutes dk',
                        icon: Icons.timer_outlined),
                  ],
                ),
              ),
            ),

            // ── Yanlış kelimeler ─────────────────────────────────────────
            if (state.wrongWordIds.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: _WrongWordsAccordion(wordIds: state.wrongWordIds),
                ),
              ),

            // ── Butonlar ─────────────────────────────────────────────────
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
          // Tekrar Çalış — study_zone route'una kadar pop et
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('retry_button'),
              onPressed: () {
                // BlocProvider.value ile açılmış quiz+result stack'ini temizle
                // study_zone route'una dön (ya da stack'in başına)
                Navigator.of(context).popUntil((route) =>
                    route.settings.name == NavigationConstants.STUDY_ZONE ||
                    route.isFirst);
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
          // Ana Sayfa — tüm stack'i temizle, /main'e git (CRASH FIX)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('home_button'),
              onPressed: () {
                // navigateToPageClear: pushNamedAndRemoveUntil
                // stack tamamen temizlenir → BLoC dispose sorunsuz
                NavigationService.instance.navigateToPageClear(
                  path: NavigationConstants.MAIN,
                );
              },
              icon: const Icon(Icons.home_rounded),
              label: const Text('Ana Sayfa',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: c, size: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: c)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WrongWordsAccordion extends StatelessWidget {
  final List<int> wordIds;
  const _WrongWordsAccordion({required this.wordIds});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('Yanlış Kelimeler (${wordIds.length})',
          style: const TextStyle(fontWeight: FontWeight.w700)),
      leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
      children: wordIds
          .map((id) => ListTile(
                dense: true,
                leading:
                    const Icon(Icons.circle, size: 8, color: Colors.orange),
                title:
                    Text('Kelime #$id', style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
    );
  }
}
