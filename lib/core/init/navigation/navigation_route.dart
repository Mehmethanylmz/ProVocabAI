import 'package:flutter/material.dart';
import '../../../features/auth/presentation/view/email_verification_view.dart';
import '../../../features/auth/presentation/view/forgot_password_view.dart';
import '../../../features/auth/presentation/view/login_view.dart';
import '../../../features/auth/presentation/view/register_view.dart';
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

      case NavigationConstants.LOGIN:
        return normalNavigate(const LoginView());

      case NavigationConstants.REGISTER:
        return normalNavigate(const RegisterView());

      case NavigationConstants.FORGOT_PASSWORD:
        return normalNavigate(const ForgotPasswordView());

      case NavigationConstants.EMAIL_VERIFICATION:
        return normalNavigate(const EmailVerificationView());

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
