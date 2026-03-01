// lib/core/constants/navigation/navigation_constants.dart
//
// FAZ 1 FIX:
//   F1-11: QUIZ route deprecated — quiz artık study_zone_screen içinde inline

// ignore_for_file: constant_identifier_names

class NavigationConstants {
  // ── Auth & Onboarding ──────────────────────────────────────────────────
  static const SPLASH = '/';
  static const LOGIN = '/login';
  static const ONBOARDING = '/onboarding';

  // ── Main ──────────────────────────────────────────────────────────────
  static const MAIN = '/main';
  static const SETTINGS = '/settings';

  // ── Study Zone ─────────────────────────────────────────────────────────
  static const STUDY_ZONE = '/study_zone';

  /// F1-11: DEPRECATED — Quiz artık study_zone_screen içinden
  /// BlocProvider.value ile tek seferlik push yapılıyor.
  /// NavigationRoute'ta bu route artık yok.
  @Deprecated('Quiz artık inline — study_zone_screen.dart içinde')
  static const QUIZ = '/quiz';

  static const SESSION_RESULT = '/session_result';

  // ── Leaderboard ────────────────────────────────────────────────────────
  static const LEADERBOARD = '/leaderboard';
}
