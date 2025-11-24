import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';
import '../../viewmodel/main_viewmodel.dart';
import 'home_screen.dart';
import 'test_menu_screen.dart';
import '../../core/extensions/responsive_extension.dart';
import '../../core/constants/app_colors.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const TestMenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final mainViewModel = context.watch<MainViewModel>();

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: mainViewModel.selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: _ModernBottomNav(
        selectedIndex: mainViewModel.selectedIndex,
        onTap: (index) {
          context.read<MainViewModel>().changeTab(index);

          if (index == 0) {
            context.read<HomeViewModel>().loadHomeData();
          } else if (index == 1) {
            context.read<TestMenuViewModel>().loadTestData();
          }
        },
      ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
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
            gradient: AppColors.gradientPurple,
          ),
          _NavItem(
            icon: Icons.rocket_launch_rounded,
            label: 'study'.tr(),
            isSelected: selectedIndex == 1,
            onTap: () => onTap(1),
            gradient: AppColors.gradientBlue,
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
            vertical: context.responsive.value(
              mobile: 12,
              tablet: 14,
              desktop: 16,
            ),
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius:
                BorderRadius.circular(context.responsive.borderRadiusL),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.4),
                      blurRadius: context.responsive.value(
                        mobile: 8,
                        tablet: 12,
                        desktop: 16,
                      ),
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
                color: isSelected ? AppColors.surface : AppColors.textDisabled,
                size: context.responsive.value(
                  mobile: 24,
                  tablet: 26,
                  desktop: 28,
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: context.responsive.spacingS),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: AppColors.surface,
                      fontSize: context.responsive.value(
                        mobile: 14,
                        tablet: 15,
                        desktop: 16,
                      ),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
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
