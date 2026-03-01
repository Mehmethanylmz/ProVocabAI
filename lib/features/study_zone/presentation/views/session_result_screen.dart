// lib/features/study_zone/presentation/views/session_result_screen.dart
//
// F3-05: Rewarded Ad "2x XP" CTA butonu eklendi.
// FIX: "Ana Sayfa" butonu crash → NavigationService.navigateToPageClear(/main)
// FIX: "Tekrar Çalış" → popUntil(study_zone)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../ads/ad_service.dart';
import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../state/study_zone_bloc.dart' hide AdService;
import '../state/study_zone_event.dart';
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

class _ResultBody extends StatefulWidget {
  final StudyZoneCompleted state;
  const _ResultBody({required this.state});

  @override
  State<_ResultBody> createState() => _ResultBodyState();
}

class _ResultBodyState extends State<_ResultBody> {
  bool _rewardedUsed = false;
  bool _rewardedGranted = false;

  AdService get _adService => getIt<AdService>();

  void _onClaimDoubleXP() {
    if (_rewardedUsed) return;

    _adService.showRewarded(
      onRewarded: (type) {
        if (mounted) {
          setState(() {
            _rewardedUsed = true;
            _rewardedGranted = true;
          });
          // BLoC'a 2x XP bonus bildir
          context
              .read<StudyZoneBloc>()
              .add(const RewardedAdCompleted(RewardedBonus.doubleXP));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 2x XP kazandın!'),
              backgroundColor: Colors.amber,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onFailed: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reklam şu an mevcut değil, tekrar deneyin.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final scheme = Theme.of(context).colorScheme;
    final accuracy =
        state.totalCards > 0 ? state.correctCards / state.totalCards : 0.0;
    final emoji = accuracy >= 0.8
        ? '🏆'
        : accuracy >= 0.5
            ? '👍'
            : '💪';
    final minutes = (state.totalTimeMs / 60000).ceil();

    // 2x XP uygulandıysa gerçek XP hesabı
    final displayXP = _rewardedGranted ? state.xpEarned * 2 : state.xpEarned;

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
                    // XP gösterimi — bonus uygulandıysa animasyonlu
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _rewardedGranted
                          ? Row(
                              key: const ValueKey('xp_bonus'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '+${state.xpEarned} XP',
                                  style: TextStyle(
                                    color: scheme.onPrimary.withOpacity(0.6),
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+$displayXP XP',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              key: const ValueKey('xp_normal'),
                              '+${state.xpEarned} XP kazandın',
                              style: TextStyle(
                                color: scheme.onPrimary.withOpacity(0.9),
                                fontSize: 16,
                              ),
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

            // ── 2x XP Rewarded CTA (F3-05) ───────────────────────────────
            if (!_rewardedUsed)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: _DoubleXPBanner(
                    xpEarned: state.xpEarned,
                    onClaim: _onClaimDoubleXP,
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

// ── 2x XP Banner ─────────────────────────────────────────────────────────────

class _DoubleXPBanner extends StatelessWidget {
  final int xpEarned;
  final VoidCallback onClaim;

  const _DoubleXPBanner({required this.xpEarned, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('double_xp_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2x XP Kazan!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '+$xpEarned XP → +${xpEarned * 2} XP — kısa video izle',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const Key('claim_double_xp_button'),
            onPressed: onClaim,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFF8F00),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('İzle',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────

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
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('retry_button'),
              onPressed: () {
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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('home_button'),
              onPressed: () {
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

// ── Stat Card ─────────────────────────────────────────────────────────────────

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

// ── Wrong Words Accordion ─────────────────────────────────────────────────────

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
