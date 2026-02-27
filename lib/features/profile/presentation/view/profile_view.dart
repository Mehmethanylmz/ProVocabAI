// lib/features/profile/presentation/view/profile_view.dart
//
// REWRITE: AuthViewModel + Provider → AuthBloc + BLoC
// Çıkış: AuthBloc.add(SignOutRequested()) → AuthUnauthenticated → LOGIN

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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          NavigationService.instance
              .navigateToPageClear(path: NavigationConstants.LOGIN);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isAuth = authState is AuthAuthenticated;
          final user = isAuth ? authState.user : null;
          final isGuest = isAuth ? authState.isGuest : true;
          final name = user?.displayName ?? (isGuest ? 'Misafir' : 'Kullanıcı');
          final email = user?.email;
          final photoUrl = user?.photoURL;

          return Scaffold(
            backgroundColor: context.colors.surface,
            appBar: AppBar(
              title: Text('nav_profile'.tr()),
              centerTitle: true,
              actions: [
                BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (context, dashState) {
                    final shareText = dashState is DashboardLoaded
                        ? dashState.shareText
                        : null;
                    return IconButton(
                      icon: Icon(Icons.share_rounded,
                          color: context.colors.primary),
                      onPressed: shareText != null
                          ? () => Share.share(shareText)
                          : null,
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
              children: [
                const SizedBox(height: 32),

                // ── Avatar ───────────────────────────────────────────────
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

                const SizedBox(height: 16),

                // ── İsim & Email ─────────────────────────────────────────
                Center(
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: 4),
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

                const SizedBox(height: 32),
                const Divider(height: 1),

                // ── Misafir uyarısı ──────────────────────────────────────
                if (isGuest)
                  ListTile(
                    leading: Icon(Icons.person_add_rounded,
                        color: context.colors.primary),
                    title: Text(
                      'Hesabınla giriş yap',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Verilerini kaydetmek için giriş yap',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => NavigationService.instance
                        .navigateToPageClear(path: NavigationConstants.LOGIN),
                  ),

                // ── Çıkış ────────────────────────────────────────────────
                ListTile(
                  leading:
                      Icon(Icons.logout_rounded, color: context.colors.error),
                  title: Text(
                    'Çıkış Yap',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: context.colors.error,
                    ),
                  ),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Çıkış Yap'),
                        content: const Text(
                            'Hesabından çıkmak istediğine emin misin?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              'Çıkış',
                              style: TextStyle(color: context.colors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      context.read<AuthBloc>().add(const SignOutRequested());
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

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
