import 'package:flutter/material.dart';
import '../../../features/splash/presentation/view/splash_view.dart';
import '../../constants/navigation/navigation_constants.dart';
import '../../../features/main/presentation/view/main_view.dart';
import '../../../features/onboarding/presentation/view/onboarding_view.dart';
import '../../../features/settings/presentation/view/settings_view.dart';
import '../../../features/study_zone/presentation/view/test_menu_view.dart';

class NavigationRoute {
  static final NavigationRoute _instance = NavigationRoute._init();
  static NavigationRoute get instance => _instance;

  NavigationRoute._init();

  Route<dynamic> generateRoute(RouteSettings args) {
    switch (args.name) {
      case NavigationConstants.SPLASH:
        return normalNavigate(const SplashView());
      case NavigationConstants.ONBOARDING:
        return normalNavigate(const OnboardingView());

      case NavigationConstants.MAIN:
        return normalNavigate(const MainView());

      case NavigationConstants.SETTINGS:
        return normalNavigate(const SettingsView());

      case NavigationConstants.TEST_MENU:
        return normalNavigate(const TestMenuView());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Page Not Found")),
          ),
        );
    }
  }

  MaterialPageRoute normalNavigate(Widget widget) {
    return MaterialPageRoute(builder: (context) => widget);
  }
}
