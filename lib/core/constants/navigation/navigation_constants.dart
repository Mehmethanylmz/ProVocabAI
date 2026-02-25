// lib/core/constants/navigation/navigation_constants.dart
//
// REWRITE: Legacy constants korundu + Blueprint yeni route'lar eklendi
// Silindi: TEST_MENU (legacy study view)

// ignore_for_file: constant_identifier_names

class NavigationConstants {
  // ── Auth & Onboarding ──────────────────────────────────────────────────
  static const SPLASH = '/';
  static const LOGIN = '/login';
  static const ONBOARDING = '/onboarding';

  // ── Main ──────────────────────────────────────────────────────────────
  static const MAIN = '/main';
  static const SETTINGS = '/settings';

  // ── Study Zone (Blueprint T-12/T-13, FCM deep link) ───────────────────
  static const STUDY_ZONE = '/study_zone';
  static const QUIZ = '/quiz';
  static const SESSION_RESULT = '/session_result';

  // ── Leaderboard (T-20) ────────────────────────────────────────────────
  static const LEADERBOARD = '/leaderboard';
}
