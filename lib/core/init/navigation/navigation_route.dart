// lib/core/init/navigation/navigation_route.dart
//
// FAZ 1 FIX:
//   F1-11: QUIZ route kaldırıldı — quiz artık study_zone_screen içinden
//          BlocProvider.value ile TEK push yapılıyor.
//   NOT: NavigationConstants.QUIZ hâlâ tanımlı (geriye dönük uyumluluk)
//        ama buradan case kaldırıldı.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/navigation/navigation_constants.dart';
import '../../../core/di/injection_container.dart';
import '../../../features/auth/presentation/state/auth_bloc.dart';
import '../../../features/auth/presentation/view/login_view.dart';
import '../../../features/dashboard/presentation/state/dashboard_bloc.dart';
import '../../../features/leaderboard/presentation/views/leaderboard_screen.dart';
import '../../../features/main/presentation/view/main_view.dart';
import '../../../features/onboarding/presentation/state/onboarding_bloc.dart';
import '../../../features/onboarding/presentation/view/onboarding_view.dart';
import '../../../features/settings/presentation/view/settings_view.dart';
import '../../../features/splash/presentation/state/splash_bloc.dart';
import '../../../features/splash/presentation/view/splash_view.dart';
import '../../../features/study_zone/presentation/state/study_zone_bloc.dart';
import '../../../features/study_zone/presentation/views/session_result_screen.dart';
import '../../../features/study_zone/presentation/views/study_zone_screen.dart';

class NavigationRoute {
  static final NavigationRoute _instance = NavigationRoute._init();
  static NavigationRoute get instance => _instance;
  NavigationRoute._init();

  Route<dynamic> generateRoute(RouteSettings args) {
    switch (args.name) {
      // ── Splash ─────────────────────────────────────────────────────────
      case NavigationConstants.SPLASH:
        return _slide(
          BlocProvider(
            create: (_) => getIt<SplashBloc>(),
            child: const SplashView(),
          ),
        );

      // ── Auth ───────────────────────────────────────────────────────────
      case NavigationConstants.LOGIN:
        return _slide(
          BlocProvider(
            create: (_) => getIt<AuthBloc>()..add(const AuthStarted()),
            child: const LoginView(),
          ),
        );

      // ── Onboarding ────────────────────────────────────────────────────
      case NavigationConstants.ONBOARDING:
        return _slide(
          BlocProvider(
            create: (_) => getIt<OnboardingBloc>(),
            child: const OnboardingView(),
          ),
        );

      // ── Main (Dashboard + StudyZone + Profile) ────────────────────────
      case NavigationConstants.MAIN:
        return _slide(
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => getIt<AuthBloc>()..add(const AuthStarted()),
              ),
              BlocProvider(
                create: (_) => getIt<DashboardBloc>(),
              ),
            ],
            child: const MainView(),
          ),
        );

      case NavigationConstants.SETTINGS:
        return _slide(const SettingsView());

      // ── Study Zone ─────────────────────────────────────────────────────
      case NavigationConstants.STUDY_ZONE:
        return _slide(
          BlocProvider(
            create: (_) => getIt<StudyZoneBloc>(),
            child: const StudyZoneScreen(),
          ),
        );

      // F1-11: QUIZ route KALDIRILDI
      // Quiz artık study_zone_screen.dart içinden BlocProvider.value ile
      // tek seferlik push yapılıyor. Bu route'a gelen istekler 404 döner.

      case NavigationConstants.SESSION_RESULT:
        return _slide(const SessionResultScreen());

      // ── Leaderboard ─────────────────────────────────────────────────────
      case NavigationConstants.LEADERBOARD:
        return _slide(const LeaderboardScreen());

      default:
        return _slide(const Scaffold(
          body: Center(child: Text('404 — Route bulunamadı')),
        ));
    }
  }

  PageRouteBuilder<dynamic> _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}
