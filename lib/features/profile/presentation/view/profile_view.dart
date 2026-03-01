// lib/features/profile/presentation/view/profile_view.dart
//
// FAZ 5 FIX — Profil Zenginleştirme:
//   - XP/streak/mastered stat kartları (AuthAuthenticated.profile + DashboardLoaded)
//   - Başarı rozetleri bölümü
//   - Misafir hesap bağlama CTA (daha belirgin)
//   - Sign-out dialog → Drift temizleme uyarısı
//   - Deprecated withOpacity → withValues
//   - Duplicate BlocListener kaldırıldı (sign-out app.dart'ta)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../../../auth/presentation/state/auth_bloc.dart';
import '../../../dashboard/presentation/state/dashboard_bloc.dart';
import '../../../settings/presentation/state/settings_bloc.dart';
import '../../../settings/presentation/view/settings_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // NOT: Sign-out navigasyonu app.dart global listener'da.
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAuth = authState is AuthAuthenticated;
        final authData = isAuth ? authState : null;
        final isGuest = authData?.isGuest ?? true;
        final name =
            authData?.displayName ?? (isGuest ? 'Misafir' : 'Kullanıcı');
        final email = authData?.user.email;
        final photoUrl = authData?.photoUrl;

        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: AppBar(
            title: Text('nav_profile'.tr()),
            centerTitle: true,
            actions: [
              BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, dashState) {
                  final shareText =
                      dashState is DashboardLoaded ? dashState.shareText : null;
                  return IconButton(
                    icon: Icon(Icons.share_rounded,
                        color: context.colors.primary),
                    onPressed:
                        shareText != null ? () => Share.share(shareText) : null,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => getIt<SettingsBloc>(),
                      child: const SettingsView(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const SizedBox(height: 24),

              // ── Avatar ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        context.colors.primary,
                        context.colors.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _InitialsWidget(name: name),
                          ),
                        )
                      : _InitialsWidget(name: name),
                ),
              ),

              const SizedBox(height: 14),

              // ── İsim & Email ────────────────────────────────────────
              Center(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (email != null && email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Center(
                  child: Text(
                    email,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Stat Kartları ───────────────────────────────────────
              _StatCardsRow(authData: authData),

              const SizedBox(height: 8),

              // ── Başarı Rozetleri ────────────────────────────────────
              _AchievementSection(authData: authData),

              const SizedBox(height: 8),

              // ── İstatistik Bölümü (Dashboard'dan) ──────────────────
              _StatsFromDashboard(),

              // ── Misafir CTA ─────────────────────────────────────────
              if (isGuest) ...[
                const SizedBox(height: 8),
                _GuestUpgradeCTA(),
              ],

              const Divider(height: 32),

              // ── Çıkış ────────────────────────────────────────────────
              _SignOutTile(),
            ],
          ),
        );
      },
    );
  }
}

// ── Stat Kartları (3'lü row) ──────────────────────────────────────────────────

class _StatCardsRow extends StatelessWidget {
  final AuthAuthenticated? authData;
  const _StatCardsRow({this.authData});

  @override
  Widget build(BuildContext context) {
    final totalXp = authData?.totalXp ?? 0;
    final weeklyXp = authData?.weeklyXp ?? 0;
    final streak = authData?.streakDays ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.star_rounded,
              iconColor: Colors.amber,
              label: 'Toplam XP',
              value: _formatNumber(totalXp),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.trending_up_rounded,
              iconColor: Colors.green,
              label: 'Bu Hafta',
              value: _formatNumber(weeklyXp),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.deepOrange,
              label: 'Seri',
              value: '$streak gün',
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style:
                GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Başarı Rozetleri ──────────────────────────────────────────────────────────

class _AchievementSection extends StatelessWidget {
  final AuthAuthenticated? authData;
  const _AchievementSection({this.authData});

  @override
  Widget build(BuildContext context) {
    final totalXp = authData?.totalXp ?? 0;
    final streak = authData?.streakDays ?? 0;

    final badges = <_BadgeData>[
      if (totalXp >= 100) _BadgeData('🌱', 'Başlangıç', '100 XP kazandın'),
      if (totalXp >= 500) _BadgeData('🌿', 'Çalışkan', '500 XP kazandın'),
      if (totalXp >= 1000) _BadgeData('🌳', 'Bilgi Ağacı', '1000 XP kazandın'),
      if (totalXp >= 5000) _BadgeData('🏆', 'Uzman', '5000 XP kazandın'),
      if (totalXp >= 10000) _BadgeData('💎', 'Elmas', '10000 XP kazandın'),
      if (streak >= 3)
        _BadgeData('🔥', '3 Gün Seri', '3 gün üst üste çalıştın'),
      if (streak >= 7) _BadgeData('⚡', 'Haftalık', '7 gün üst üste çalıştın'),
      if (streak >= 30)
        _BadgeData('🌟', 'Aylık Seri', '30 gün üst üste çalıştın'),
    ];

    if (badges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('İlk rozetini kazan!',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('100 XP kazanarak başla',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: context.colors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Başarılar',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: badges
                .map((b) => Tooltip(
                      message: b.description,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(b.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(b.label,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ))
                .toList(),
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

// ── İstatistik (Dashboard'dan) ────────────────────────────────────────────────

class _StatsFromDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is! DashboardLoaded) return const SizedBox.shrink();
        final stats = state.stats;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('İstatistikler',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurfaceVariant)),
                const SizedBox(height: 12),
                _StatRow(Icons.today_rounded, 'Bugün',
                    '${stats.todayQuestions} soru · %${(stats.todaySuccessRate * 100).toInt()}'),
                const SizedBox(height: 8),
                _StatRow(Icons.date_range_rounded, 'Bu hafta',
                    '${stats.weekQuestions} soru · %${(stats.weekSuccessRate * 100).toInt()}'),
                const SizedBox(height: 8),
                _StatRow(Icons.calendar_month_rounded, 'Bu ay',
                    '${stats.monthQuestions} soru · %${(stats.monthSuccessRate * 100).toInt()}'),
                const SizedBox(height: 8),
                _StatRow(Icons.school_rounded, 'Öğrenilen',
                    '${stats.masteredWords} kelime',
                    valueColor: Colors.green),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _StatRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Builder(builder: (context) {
      return Row(
        children: [
          Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ],
      );
    });
  }
}

// ── Misafir CTA ───────────────────────────────────────────────────────────────

class _GuestUpgradeCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.1),
              scheme.secondary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_rounded, color: scheme.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hesabınla giriş yap',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('İlerlemenin kaybolmasın! Google ile bağla.',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: context.colors.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => NavigationService.instance
                  .navigateToPageClear(path: NavigationConstants.LOGIN),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16)),
              child: Text('Bağla',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Çıkış Tile ────────────────────────────────────────────────────────────────

class _SignOutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.logout_rounded, color: context.colors.error),
      title: Text('Çıkış Yap',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: context.colors.error)),
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Çıkış Yap',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            content: Text(
              'Hesabından çıkmak istediğine emin misin?\n\n'
              'Lokal ilerleme verilerin temizlenecek. '
              'Tekrar giriş yaptığında Firestore\'dan senkronize edilir.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('İptal',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Çıkış',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: context.colors.error)),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          context.read<AuthBloc>().add(const SignOutRequested());
        }
      },
    );
  }
}

// ── Initials Widget ───────────────────────────────────────────────────────────

class _InitialsWidget extends StatelessWidget {
  final String name;
  const _InitialsWidget({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: context.colors.onPrimary,
        ),
      ),
    );
  }
}
