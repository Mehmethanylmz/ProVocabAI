// lib/features/main/presentation/view/main_view.dart
//
// FAZ 8B: Premium Bottom Navigation
//   - Floating glassmorphism nav bar
//   - Gradient indicator
//   - Smooth tab geçişleri
//   - IndexedStack ile tab korunması

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app/color_palette.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../dashboard/presentation/views/dashboard_view.dart';
import '../../../leaderboard/presentation/views/leaderboard_screen.dart';
import '../../../profile/presentation/view/profile_view.dart';
import '../../../study_zone/presentation/state/study_zone_bloc.dart';
import '../../../study_zone/presentation/views/study_zone_screen.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int _selectedIndex = 0;

  void _changeTab(int index) {
    if (index != _selectedIndex) {
      HapticFeedback.selectionClick();
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const DashboardView(),
          BlocProvider(
            create: (_) => getIt<StudyZoneBloc>(),
            child: const StudyZoneScreen(),
          ),
          const LeaderboardScreen(),
          const ProfileView(),
        ],
      ),
      bottomNavigationBar: _PremiumBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _changeTab,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PREMIUM BOTTOM NAV
// ═══════════════════════════════════════════════════════════════════════════════

class _PremiumBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _PremiumBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded,
        'nav_home'),
    _NavItem(Icons.school_outlined, Icons.school_rounded, 'nav_study'),
    _NavItem(Icons.emoji_events_outlined, Icons.emoji_events_rounded,
        'nav_leaderboard'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'nav_profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: isDark
            ? ColorPalette.surfaceContainerDark.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? ColorPalette.outlineDark.withValues(alpha: 0.2)
              : ColorPalette.outlineLight.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          if (!isDark)
            BoxShadow(
              color: ColorPalette.primary.withValues(alpha: 0.04),
              blurRadius: 40,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final isSelected = i == selectedIndex;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          key: ValueKey('${item.labelKey}_$isSelected'),
                          color: isSelected
                              ? context.colors.primary
                              : context.colors.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.labelKey.tr(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? context.colors.primary
                              : context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
  const _NavItem(this.icon, this.activeIcon, this.labelKey);
}
