// lib/features/profile/presentation/view/profile_view.dart
//
// FAZ 13 — F13-01..F13-09: Profil ekranı yeniden yazımı
//   F13-01: Hero banner (avatar, isim, XP, seviye)
//   F13-02: Tarihsel istatistik bölümü
//   F13-03: Başarı rozetleri 3-sütun grid
//   F13-04: SkillRadarCard + WordTierPanel
//   F13-05: Paylaşım (screenshot + share_plus)
//   F13-06: Yüzde düzeltme (toStringAsFixed(0), *100 yok)
//   F13-07: Bottom padding 100px (nav bar altında kalmama)
//   F13-08: Çıkış butonu görünür konum
//   F13-09: Misafir CTA belirgin

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app/color_palette.dart';
import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../../../auth/presentation/state/auth_bloc.dart';
import '../../../dashboard/domain/entities/dashboard_stats_entity.dart';
import '../../../dashboard/presentation/state/dashboard_bloc.dart';
import '../../../dashboard/presentation/widgets/skill_radar_card.dart';
import '../../../dashboard/presentation/widgets/word_tier_panel.dart';
import '../../../settings/presentation/view/settings_view.dart';
import '../widgets/share_card_widget.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final GlobalKey _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAuth = authState is AuthAuthenticated;
        final authData = isAuth ? authState : null;
        final isGuest = authData?.isGuest ?? true;
        final name =
            authData?.displayName ?? (isGuest ? 'Misafir' : 'Kullanıcı');
        final email = authData?.user.email;
        final photoUrl = authData?.photoUrl;

        return BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, dashState) {
            final dashLoaded =
                dashState is DashboardLoaded ? dashState : null;
            final stats = dashLoaded?.stats;

            return Scaffold(
              backgroundColor: context.colors.surface,
              appBar: AppBar(
                title: Text('nav_profile'.tr()),
                centerTitle: true,
                actions: [
                  // F13-05: Paylaşım butonu
                  IconButton(
                    icon: Icon(Icons.share_rounded,
                        color: context.colors.primary),
                    onPressed: stats != null
                        ? () => _showShareSheet(
                              context,
                              authData: authData,
                              stats: stats,
                            )
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsView(),
                      ),
                    ),
                  ),
                ],
              ),
              body: ListView(
                // F13-07: Bottom padding nav bar için
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // F13-01: Hero banner
                  _HeroBanner(
                    name: name,
                    email: email,
                    photoUrl: photoUrl,
                    authData: authData,
                  ),

                  const SizedBox(height: 8),

                  // F13-03: Başarı rozetleri grid
                  _AchievementSection(authData: authData),

                  const SizedBox(height: 8),

                  // F13-02: Tarihsel istatistikler
                  if (stats != null) ...[
                    _HistoricalStats(stats: stats),
                    const SizedBox(height: 8),
                  ],

                  // F13-04: SkillRadarCard
                  if (dashLoaded != null &&
                      dashLoaded.volumeStats.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SkillRadarCard(
                        volumeStats: dashLoaded.volumeStats,
                        accuracyStats: dashLoaded.accuracyStats,
                        message: dashLoaded.coachMessage,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // F13-04: WordTierPanel
                  if (stats != null &&
                      stats.tierDistribution.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: WordTierPanel(
                        tierDistribution: stats.tierDistribution,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // F13-09: Misafir CTA
                  if (isGuest) ...[
                    _GuestUpgradeCTA(),
                    const SizedBox(height: 8),
                  ],

                  const Divider(height: 32, indent: 16, endIndent: 16),

                  // F13-08: Çıkış butonu — görünür konum
                  _SignOutButton(),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showShareSheet(
    BuildContext context, {
    required AuthAuthenticated? authData,
    required DashboardStatsEntity stats,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShareBottomSheet(
        authData: authData,
        stats: stats,
        shareKey: _shareKey,
      ),
    );
  }
}

// ── F13-01: Hero Banner ────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final String name;
  final String? email;
  final String? photoUrl;
  final AuthAuthenticated? authData;

  const _HeroBanner({
    required this.name,
    this.email,
    this.photoUrl,
    this.authData,
  });

  String _levelLabel(int xp) {
    if (xp < 100) return 'Başlangıç';
    if (xp < 500) return 'Çalışkan';
    if (xp < 1000) return 'Gelişen';
    if (xp < 5000) return 'İleri';
    if (xp < 10000) return 'Uzman';
    return 'Elmas';
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalXp = authData?.totalXp ?? 0;
    final weeklyXp = authData?.weeklyXp ?? 0;
    final streak = authData?.streakDays ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            ColorPalette.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _InitialsWidget(name: name, light: true),
                        ),
                      )
                    : _InitialsWidget(name: name, light: true),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (email != null && email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _levelLabel(totalXp),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // XP row
          Row(
            children: [
              _HeroStat(
                icon: Icons.star_rounded,
                value: _formatNumber(totalXp),
                label: 'Toplam XP',
              ),
              const _HeroDivider(),
              _HeroStat(
                icon: Icons.trending_up_rounded,
                value: _formatNumber(weeklyXp),
                label: 'Bu Hafta XP',
              ),
              const _HeroDivider(),
              _HeroStat(
                icon: Icons.local_fire_department_rounded,
                value: '$streak',
                label: 'Gün Serisi',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 3),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}

// ── F13-02: Tarihsel İstatistikler ────────────────────────────────────────────

class _HistoricalStats extends StatelessWidget {
  final DashboardStatsEntity stats;
  const _HistoricalStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İstatistikler',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            // F13-06: Yüzde düzeltme — todaySuccessRate zaten 0-100 arasında değil,
            // 0.0–1.0 arası float; toStringAsFixed ile doğru çevir, *100 tekrar yapma.
            _StatRow(
              icon: Icons.today_rounded,
              label: 'Bugün',
              value:
                  '${stats.todayQuestions} soru · %${(stats.todaySuccessRate * 100).toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.date_range_rounded,
              label: 'Bu hafta',
              value:
                  '${stats.weekQuestions} soru · %${(stats.weekSuccessRate * 100).toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.calendar_month_rounded,
              label: 'Bu ay',
              value:
                  '${stats.monthQuestions} soru · %${(stats.monthSuccessRate * 100).toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.school_rounded,
              label: 'Öğrenilen',
              value: '${stats.masteredWords} kelime',
              valueColor: ColorPalette.success,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 17, color: scheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ── F13-03: Başarı Rozetleri (3-sütun grid) ───────────────────────────────────

class _AchievementSection extends StatelessWidget {
  final AuthAuthenticated? authData;
  const _AchievementSection({this.authData});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalXp = authData?.totalXp ?? 0;
    final streak = authData?.streakDays ?? 0;

    final badges = <_BadgeData>[
      if (totalXp >= 100) _BadgeData('🌱', 'Başlangıç', '100 XP kazandın'),
      if (totalXp >= 500) _BadgeData('🌿', 'Çalışkan', '500 XP kazandın'),
      if (totalXp >= 1000) _BadgeData('🌳', 'Bilgi Ağacı', '1000 XP kazandın'),
      if (totalXp >= 5000) _BadgeData('🏆', 'Uzman', '5000 XP kazandın'),
      if (totalXp >= 10000) _BadgeData('💎', 'Elmas', '10000 XP kazandın'),
      if (streak >= 3) _BadgeData('🔥', '3 Gün Seri', '3 gün çalıştın'),
      if (streak >= 7) _BadgeData('⚡', 'Haftalık', '7 gün çalıştın'),
      if (streak >= 30) _BadgeData('🌟', 'Aylık Seri', '30 gün çalıştın'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Başarılar',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          badges.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      const Text('🏅', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'İlk rozetini kazan!',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '100 XP kazanarak başla',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: badges.length,
                  itemBuilder: (context, i) {
                    final b = badges[i];
                    return Tooltip(
                      message: b.description,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: scheme.outline.withValues(alpha: 0.12)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(b.emoji,
                                style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 4),
                            Text(
                              b.label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class _BadgeData {
  final String emoji, label, description;
  const _BadgeData(this.emoji, this.label, this.description);
}

// ── F13-09: Misafir CTA (belirgin) ────────────────────────────────────────────

class _GuestUpgradeCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.12),
              ColorPalette.secondary.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(Icons.person_add_rounded,
                      color: scheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hesabını Bağla',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'İlerlemenin kaybolmasın — Google ile senkronize et.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => NavigationService.instance
                    .navigateToPageClear(path: NavigationConstants.LOGIN),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(
                  'Google ile Giriş Yap',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── F13-08: Çıkış Butonu (görünür konum) ─────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(
                'Çıkış Yap',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              content: Text(
                'Hesabından çıkmak istediğine emin misin?\n\n'
                'Lokal ilerleme verilerin temizlenecek. '
                'Tekrar giriş yaptığında Firestore\'dan senkronize edilir.',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('İptal',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Çıkış',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: scheme.error,
                    ),
                  ),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            context.read<AuthBloc>().add(const SignOutRequested());
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.error,
          side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(Icons.logout_rounded, color: scheme.error, size: 18),
        label: Text(
          'Çıkış Yap',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: scheme.error,
          ),
        ),
      ),
    );
  }
}

// ── F13-05: Paylaşım Bottom Sheet ─────────────────────────────────────────────

class _ShareBottomSheet extends StatelessWidget {
  final AuthAuthenticated? authData;
  final DashboardStatsEntity stats;
  final GlobalKey shareKey;

  const _ShareBottomSheet({
    required this.authData,
    required this.stats,
    required this.shareKey,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'İstatistiklerini Paylaş',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            key: shareKey,
            child: ShareCardWidget(
              authData: authData,
              stats: stats,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await shareProfileCard(shareKey);
              },
              icon: const Icon(Icons.share_rounded, size: 18),
              label: Text(
                'Paylaş',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Initials Widget ────────────────────────────────────────────────────────────

class _InitialsWidget extends StatelessWidget {
  final String name;
  final bool light;
  const _InitialsWidget({required this.name, this.light = false});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: light ? Colors.white : context.colors.onPrimary,
        ),
      ),
    );
  }
}
