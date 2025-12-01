import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/di/injection_container.dart';

// Viewlar
import '../../../dashboard/presentation/view/dashboard_view.dart';
import '../../../study_zone/presentation/view/test_menu_view.dart';
// YENİ EKLENEN VIEW'LAR (Import yollarını kendi projene göre ayarla)
import '../../../social/presentation/view/social_view.dart';
import '../../../profile/presentation/view/profile_view.dart';

import '../view_model/main_view_model.dart';
import '../../../study_zone/presentation/view_model/menu_view_model.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseView<MainViewModel>(
      viewModel: locator<MainViewModel>(),
      onModelReady: (model) {
        model.setContext(context);
      },
      builder: (context, viewModel, child) {
        return Scaffold(
          extendBody: true, // BottomNav arkasına içerik kayabilsin diye
          body: IndexedStack(
            index: viewModel.selectedIndex,
            children: [
              const DashboardView(), // 0: Ana Ekran
              const TestMenuView(), // 1: Atölye
              const SocialView(), // 2: Hub (Sosyal)
              const ProfileView(), // 3: Profil
            ],
          ),
          bottomNavigationBar: _ModernBottomNav(
            selectedIndex: viewModel.selectedIndex,
            onTap: (index) {
              viewModel.changeTab(index);
              // Eğer Atölye sekmesine geçilirse verileri yenile
              if (index == 1) {
                locator<MenuViewModel>().loadMenuData();
              }
            },
          ),
        );
      },
    );
  }
}

class _ModernBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _ModernBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Alt taraftan ve yanlardan boşluk bırakarak "yüzen" tasarım
      margin: EdgeInsets.fromLTRB(
        context.responsive.value(mobile: 16, tablet: 24, desktop: 32),
        0,
        context.responsive.value(mobile: 16, tablet: 24, desktop: 32),
        context.responsive.value(mobile: 24, tablet: 28, desktop: 32),
      ),
      padding: EdgeInsets.all(
        context.responsive.value(mobile: 8, tablet: 10, desktop: 12),
      ),
      decoration: BoxDecoration(
        color: context.colors.surface, // Tema rengi (Dark/Light uyumlu)
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'nav_home'.tr(),
            index: 0,
            selectedIndex: selectedIndex,
            onTap: onTap,
            activeColor: context.colors.primary,
          ),
          _NavItem(
            icon: Icons.rocket_launch_rounded,
            label: 'nav_study'.tr(),
            index: 1,
            selectedIndex: selectedIndex,
            onTap: onTap,
            activeColor: context.ext.gradientPurple.first, // Mor
          ),
          _NavItem(
            icon: Icons.hub_rounded, // Veya groups_rounded
            label: 'nav_hub'.tr(),
            index: 2,
            selectedIndex: selectedIndex,
            onTap: onTap,
            activeColor: context.ext.gradientBlue.last, // Mavi
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'nav_profile'.tr(),
            index: 3,
            selectedIndex: selectedIndex,
            onTap: onTap,
            activeColor: context.ext.warning, // Turuncu/Sarı
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final Function(int) onTap;
  final Color activeColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: EdgeInsets.symmetric(
            vertical: context.responsive.value(mobile: 10, tablet: 12),
          ),
          decoration: BoxDecoration(
            color:
                isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
            borderRadius:
                BorderRadius.circular(context.responsive.borderRadiusL),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İKON ANİMASYONU
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  color: isSelected
                      ? activeColor
                      : context.colors.onSurface.withOpacity(0.4),
                  size: context.responsive.iconSizeM,
                ),
              ),
              // YAZI ANİMASYONU (Sadece seçiliyse görünsün veya renk değiştirsin)
              // Tasarım tercihi: 4 tab olunca yazılar sığmayabilir.
              // Sadece seçili olanın yazısını göstermek daha temiz durur.
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  height: isSelected
                      ? null
                      : 0, // Seçili değilse yüksekliği 0 yap (gizle)
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: activeColor,
                        fontSize: 10, // Küçük punto
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
