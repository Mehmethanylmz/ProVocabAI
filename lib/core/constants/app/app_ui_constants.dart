// lib/core/constants/app/app_ui_constants.dart
//
// FAZ 17 — F17-03/F17-04/F17-05: Centralized UI constants
//
// Design token system — single source of truth for:
//   - Spacing (4pt grid)
//   - Border radius
//   - Animation durations + curves
//   - Accessibility constraints

import 'package:flutter/material.dart';

// ── Spacing ───────────────────────────────────────────────────────────────────

/// 4pt-grid spacing tokens. Use instead of magic numbers.
///
/// Usage: `SizedBox(height: AppSpacing.m)` instead of `SizedBox(height: 16)`
abstract final class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets listItemPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);
}

// ── Border Radius ─────────────────────────────────────────────────────────────

/// Consistent radius tokens matching the Midnight Sapphire design system.
abstract final class AppRadius {
  static const double xs = 6;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;

  static const BorderRadius card =
      BorderRadius.all(Radius.circular(l));
  static const BorderRadius button =
      BorderRadius.all(Radius.circular(14));
  static const BorderRadius chip =
      BorderRadius.all(Radius.circular(10));
  static const BorderRadius badge =
      BorderRadius.all(Radius.circular(xs));
  static const BorderRadius bottomSheet =
      BorderRadius.vertical(top: Radius.circular(xl));
  static const BorderRadius dialog =
      BorderRadius.all(Radius.circular(xl));
}

// ── Animation Durations ───────────────────────────────────────────────────────

/// Standard animation duration tokens. Keeps all transitions consistent.
///
/// Rule of thumb:
///   instant (100ms) — state toggle highlights
///   fast    (200ms) — button press feedback
///   normal  (300ms) — card appear, fade, page transitions
///   slow    (500ms) — complex sequences (splash, onboarding)
abstract final class AppDuration {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Specific semantic names
  static const Duration fadeIn = Duration(milliseconds: 300);
  static const Duration slideIn = Duration(milliseconds: 250);
  static const Duration scaleIn = Duration(milliseconds: 200);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration splashLogo = Duration(milliseconds: 600);
  static const Duration shimmer = Duration(milliseconds: 2000);

  // Quiz-specific
  static const Duration cardSwitch = Duration(milliseconds: 220);
  static const Duration snackBar = Duration(milliseconds: 1200);
  static const Duration nextCard = Duration(milliseconds: 500);

  // Stagger for list animations
  static const Duration staggerStep = Duration(milliseconds: 60);
}

// ── Animation Curves ──────────────────────────────────────────────────────────

/// Standard curve tokens — ensures animation feel is consistent across screens.
abstract final class AppCurves {
  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.decelerate;
  static const Curve accelerate = Curves.fastOutSlowIn;
  static const Curve spring = Curves.easeOutBack;
  static const Curve fadeIn = Curves.easeOut;
  static const Curve slideIn = Curves.easeOut;
}

// ── Accessibility ─────────────────────────────────────────────────────────────

/// WCAG 2.1 AA compliance constants.
///
/// Minimum contrast ratios:
///   4.5:1 — normal text (< 18sp or < 14sp bold)
///   3.0:1 — large text (>= 18sp or >= 14sp bold)
///   3.0:1 — UI components and graphical objects
abstract final class AppAccessibility {
  /// Minimum touch target per Material Design / WCAG 2.5.5 (48×48 dp).
  static const double minTouchTarget = 48;

  /// Large text threshold in sp (above this, 3:1 contrast ratio is sufficient).
  static const double largeTextSp = 18;

  /// Large bold text threshold in sp.
  static const double largeBoldTextSp = 14;

  /// Maximum text scale factor before layouts need to adapt.
  /// Flutter's default is uncapped; we clamp to 1.3 to prevent overflow.
  static const double maxTextScale = 1.3;

  /// Opacity floor for readable secondary text (above 0.45 on all themes).
  static const double minReadableOpacity = 0.45;
}
