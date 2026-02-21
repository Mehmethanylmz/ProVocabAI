import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/di/injection_container.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../auth/presentation/viewmodel/auth_view_model.dart';
import '../../../settings/presentation/view/settings_view.dart';
import '../../../dashboard/presentation/view_model/dashboard_view_model.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final dashboardVM = locator<DashboardViewModel>();

    final String name = authVM.displayName;
    final String? email = authVM.currentUser?.email;
    final String? photoUrl = authVM.currentUser?.photoUrl;
    final bool isAnonymous = authVM.currentUser?.isAnonymous ?? true;

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: Text('nav_profile'.tr()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded, color: context.colors.primary),
            onPressed: () {
              final text = dashboardVM.generateShareProgressText();
              if (text != null) Share.share(text);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            color: context.colors.onSurface,
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsView()));
            },
          ),
          SizedBox(width: context.responsive.spacingS),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),

          // ── Avatar ───────────────────────────────────────────────────────
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
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
                          child: Image.network(photoUrl, fit: BoxFit.cover),
                        )
                      : Icon(
                          isAnonymous
                              ? Icons.person_outline_rounded
                              : Icons.person_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                ),
                if (isAnonymous)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: context.colors.surface, width: 2),
                    ),
                    child: Icon(Icons.lock_outline_rounded,
                        size: 14, color: context.colors.onSurfaceVariant),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Ad ────────────────────────────────────────────────────────────
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.colors.onSurface,
            ),
          ),

          if (email != null && email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                email,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),

          if (isAnonymous)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Misafir Hesabı',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 40),
          const Divider(),

          // ── Giriş Yap (misafir ise) ───────────────────────────────────────
          if (isAnonymous)
            ListTile(
              leading: Icon(Icons.login_rounded, color: context.colors.primary),
              title: Text('Hesabınla giriş yap',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text('Verilerini kaybet',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: context.colors.onSurfaceVariant)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => NavigationService.instance
                  .navigateToPageClear(path: NavigationConstants.LOGIN),
            ),

          // ── Çıkış ────────────────────────────────────────────────────────
          ListTile(
            leading: Icon(Icons.logout_rounded, color: context.colors.error),
            title: Text(
              'Çıkış Yap',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: context.colors.error,
              ),
            ),
            onTap: () async {
              final vm = context.read<AuthViewModel>();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content:
                      const Text('Hesabından çıkmak istediğine emin misin?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('İptal')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Çıkış',
                            style: TextStyle(color: context.colors.error))),
                  ],
                ),
              );
              if (confirm == true) {
                await vm.signOut();
                if (context.mounted) {
                  NavigationService.instance
                      .navigateToPageClear(path: NavigationConstants.LOGIN);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
