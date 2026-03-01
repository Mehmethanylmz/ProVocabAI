// lib/features/main/presentation/view/main_view.dart
//
// REWRITE: BaseView<MainViewModel> + locator → StatefulWidget (tab index)
// SILINDI: MainViewModel bağımlılığı, TestMenuView import
// Atölye sekmesi: TestMenuView → StudyZoneScreen (BLoC tabanlı)
// NOT: Tab index için BLoC overkill — StatefulWidget yeterli (YAGNI prensibi)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
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
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const DashboardView(), // 0: Ana Ekran
          BlocProvider(
            create: (_) => getIt<StudyZoneBloc>(),
            child: const StudyZoneScreen(),
          ), // 1: Atölye
          const LeaderboardScreen(), // 2: Liderlik Tablosu
          const ProfileView(), // 3: Profil
        ],
      ),
      bottomNavigationBar: _ModernBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _changeTab,
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────

class _ModernBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _ModernBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: context.responsive.spacingM,
        right: context.responsive.spacingM,
        bottom: context.responsive.spacingM,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusXL),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: context.colors.primary.withOpacity(0.15),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon:
                  Icon(Icons.dashboard_rounded, color: context.colors.primary),
              label: 'nav_home'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.school_outlined),
              selectedIcon:
                  Icon(Icons.school_rounded, color: context.colors.primary),
              label: 'nav_study'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events_rounded,
                  color: context.colors.primary),
              label: 'Liderlik',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon:
                  Icon(Icons.person_rounded, color: context.colors.primary),
              label: 'nav_profile'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
