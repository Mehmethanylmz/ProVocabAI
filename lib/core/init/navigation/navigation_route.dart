// lib/core/init/navigation/navigation_route.dart
//
// REWRITE: Legacy routes + yeni Blueprint routes
// Silindi: TestMenuView (legacy), StudyViewModel bağımlı tüm view'lar
// Eklendi: /study_zone (FCM deep link), /quiz, /session_result, /leaderboard

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/navigation/navigation_constants.dart';
import '../../../core/di/injection_container.dart';
import '../../../features/auth/presentation/view/login_view.dart';
import '../../../features/main/presentation/view/main_view.dart';
import '../../../features/onboarding/presentation/view/onboarding_view.dart';
import '../../../features/settings/presentation/view/settings_view.dart';
import '../../../features/splash/presentation/view/splash_view.dart';
import '../../../features/study_zone/presentation/state/study_zone_bloc.dart';
import '../../../features/study_zone/presentation/views/quiz_screen.dart';
import '../../../features/study_zone/presentation/views/session_result_screen.dart';
import '../../../features/study_zone/presentation/views/study_zone_screen.dart';

class NavigationRoute {
  static final NavigationRoute _instance = NavigationRoute._init();
  static NavigationRoute get instance => _instance;
  NavigationRoute._init();

  Route<dynamic> generateRoute(RouteSettings args) {
    switch (args.name) {
      // ── Auth & Onboarding ──────────────────────────────────────────────
      case NavigationConstants.SPLASH:
        return _slide(const SplashView());

      case NavigationConstants.LOGIN:
        return _slide(const LoginView());

      case NavigationConstants.ONBOARDING:
        return _slide(const OnboardingView());

      // ── Main ───────────────────────────────────────────────────────────
      case NavigationConstants.MAIN:
        return _slide(const MainView());

      case NavigationConstants.SETTINGS:
        return _slide(const SettingsView());

      // ── Study Zone (Blueprint T-12/T-13) ──────────────────────────────
      // BlocProvider: getIt factory → yeni StudyZoneBloc her push'ta
      case NavigationConstants.STUDY_ZONE:
        return _slide(
          BlocProvider(
            create: (_) => getIt<StudyZoneBloc>(),
            child: const StudyZoneScreen(),
          ),
        );

      case NavigationConstants.QUIZ:
        // StudyZoneBloc üst widget'tan sağlanmalı — ayrı BlocProvider YOK
        return _slide(const QuizScreen());

      case NavigationConstants.SESSION_RESULT:
        return _slide(const SessionResultScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Sayfa bulunamadı')),
          ),
        );
    }
  }

  // ── Transition helpers ────────────────────────────────────────────────────

  PageRouteBuilder _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
