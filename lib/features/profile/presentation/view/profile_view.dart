import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/di/injection_container.dart';
import '../../../settings/presentation/view/settings_view.dart';
import '../../../dashboard/presentation/view_model/dashboard_view_model.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // İstatistiklere erişmek için DashboardViewModel'i kullanıyoruz
    final dashboardVM = locator<DashboardViewModel>();

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: Text('nav_profile'.tr()),
        centerTitle: true,
        actions: [
          // PAYLAŞ BUTONU
          IconButton(
            icon: Icon(Icons.share_rounded, color: context.colors.primary),
            onPressed: () {
              final text = dashboardVM.generateShareProgressText();
              if (text != null) Share.share(text);
            },
          ),
          // AYARLAR BUTONU
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: context.colors.primary.withOpacity(0.1),
              child:
                  Icon(Icons.person, size: 50, color: context.colors.primary),
            ),
            SizedBox(height: context.responsive.spacingM),
            Text(
              "Misafir Kullanıcı", // İleride Auth ile burası dolacak
              style: context.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: context.responsive.spacingS),
            Text(
              "Profil detayları yakında...",
              style: context.textTheme.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
