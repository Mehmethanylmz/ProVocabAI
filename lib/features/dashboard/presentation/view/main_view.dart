import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pratikapp/features/study_zone/presentation/view/test_menu_view.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/di/injection_container.dart';

import '../../../dashboard/presentation/view/dashboard_view.dart';
import '../../../main/presentation/view_model/main_view_model.dart';
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
          extendBody: true,
          body: IndexedStack(
            index: viewModel.selectedIndex,
            children: [
              const DashboardView(),
              const TestMenuView(),
            ],
          ),
          bottomNavigationBar: _ModernBottomNav(
            selectedIndex: viewModel.selectedIndex,
            onTap: (index) {
              viewModel.changeTab(index);
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
      margin: EdgeInsets.fromLTRB(
        context.responsive.value(mobile: 20, tablet: 24, desktop: 32),
        0,
        context.responsive.value(mobile: 20, tablet: 24, desktop: 32),
        context.responsive.value(mobile: 24, tablet: 28, desktop: 32),
      ),
      padding: EdgeInsets.symmetric(
        horizontal:
            context.responsive.value(mobile: 8, tablet: 12, desktop: 16),
        vertical: context.responsive.value(mobile: 8, tablet: 10, desktop: 12),
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'progress'.tr(),
            isSelected: selectedIndex == 0,
            onTap: () => onTap(0),
            gradient: context.ext.gradientPurple,
          ),
          _NavItem(
            icon: Icons.rocket_launch_rounded,
            label: 'study'.tr(),
            isSelected: selectedIndex == 1,
            onTap: () => onTap(1),
            gradient: context.ext.gradientBlue,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Color> gradient;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          padding: EdgeInsets.symmetric(
            vertical:
                context.responsive.value(mobile: 12, tablet: 14, desktop: 16),
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)
                : null,
            borderRadius:
                BorderRadius.circular(context.responsive.borderRadiusL),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? context.colors.onPrimary
                    : context.colors.onSurface.withOpacity(0.4),
                size: context.responsive.iconSizeM,
              ),
              if (isSelected) ...[
                SizedBox(width: context.responsive.spacingS),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: context.colors.onPrimary,
                      fontSize: context.responsive.fontSizeBody,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
