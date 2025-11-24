// lib/core/extensions/responsive_extension.dart
import 'package:flutter/material.dart';

/// Professional responsive design extension with adaptive breakpoints
/// Kullanım: context.responsive.mobileValue, context.responsive.isTablet, vb.
extension ResponsiveDesign on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}

class ResponsiveHelper {
  final BuildContext context;

  ResponsiveHelper(this.context);

  // CORE BREAKPOINTS (Material Design 3 standards)
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 840;
  static const double _desktopBreakpoint = 1200;

  // DEVICE TYPE DETECTION
  bool get isMobile => width < _mobileBreakpoint;
  bool get isTablet => width >= _mobileBreakpoint && width < _desktopBreakpoint;
  bool get isDesktop => width >= _desktopBreakpoint;
  bool get isSmallMobile => width < 400;
  bool get isLargeTablet =>
      width >= _tabletBreakpoint && width < _desktopBreakpoint;

  // SCREEN DIMENSIONS
  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;
  double get aspectRatio => width / height;
  double get pixelRatio => MediaQuery.of(context).devicePixelRatio;

  // SAFE AREA (Notch, Status bar, etc.)
  double get safeAreaTop => MediaQuery.of(context).padding.top;
  double get safeAreaBottom => MediaQuery.of(context).padding.bottom;
  double get safeAreaHeight => height - safeAreaTop - safeAreaBottom;

  // ORIENTATION
  bool get isPortrait => height > width;
  bool get isLandscape => width > height;
  Orientation get orientation => MediaQuery.of(context).orientation;

  // ADAPTIVE VALUE GETTER (Ana metod - diğerlerini kaldırabilirsin)
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? smallMobile,
    T? largeTablet,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isLargeTablet && largeTablet != null) return largeTablet;
    if (isTablet && tablet != null) return tablet;
    if (isSmallMobile && smallMobile != null) return smallMobile;
    return mobile;
  }

  // QUICK DIMENSION HELPERS (Yüzdelik bazlı)
  double wp(double percent) => width * (percent / 100);
  double hp(double percent) => height * (percent / 100);

  // SPACING SYSTEM (Material Design spacing)
  double get spacingXS => value(mobile: 4, tablet: 6, desktop: 8);
  double get spacingS => value(mobile: 8, tablet: 12, desktop: 16);
  double get spacingM => value(mobile: 16, tablet: 20, desktop: 24);
  double get spacingL => value(mobile: 24, tablet: 32, desktop: 40);
  double get spacingXL => value(mobile: 32, tablet: 48, desktop: 56);
  double get spacingXXL => value(mobile: 48, tablet: 64, desktop: 80);

  // PADDING PRESETS
  EdgeInsets get paddingPage => EdgeInsets.symmetric(
        horizontal: value(mobile: 16, tablet: 24, desktop: 32),
        vertical: value(mobile: 8, tablet: 12, desktop: 16),
      );

  EdgeInsets get paddingCard => EdgeInsets.all(value(
        mobile: 12,
        tablet: 16,
        desktop: 20,
        largeTablet: 24,
      ));

  EdgeInsets get paddingSection => EdgeInsets.symmetric(
        vertical: value(mobile: 16, tablet: 24, desktop: 32),
      );

  // TYPOGRAPHY SCALE
  double get fontSizeH1 => value(mobile: 24, tablet: 32, desktop: 40);
  double get fontSizeH2 => value(mobile: 20, tablet: 24, desktop: 32);
  double get fontSizeH3 => value(mobile: 18, tablet: 20, desktop: 24);
  double get fontSizeBody => value(mobile: 14, tablet: 16, desktop: 18);
  double get fontSizeCaption => value(mobile: 12, tablet: 14, desktop: 16);
  double get fontSizeSmall => value(mobile: 10, tablet: 12, desktop: 14);

  // ICON SIZES
  double get iconSizeS => value(mobile: 16, tablet: 20, desktop: 24);
  double get iconSizeM => value(mobile: 24, tablet: 28, desktop: 32);
  double get iconSizeL => value(mobile: 32, tablet: 40, desktop: 48);
  double get iconSizeXL => value(mobile: 40, tablet: 48, desktop: 56);

  // BORDER RADIUS
  double get borderRadiusS => value(mobile: 8, tablet: 12, desktop: 16);
  double get borderRadiusM => value(mobile: 12, tablet: 16, desktop: 20);
  double get borderRadiusL => value(mobile: 16, tablet: 20, desktop: 24);
  double get borderRadiusXL => value(mobile: 20, tablet: 24, desktop: 28);

  // ELEVATION
  double get elevationLow => value(mobile: 2, tablet: 4, desktop: 6);
  double get elevationMedium => value(mobile: 4, tablet: 8, desktop: 12);
  double get elevationHigh => value(mobile: 8, tablet: 16, desktop: 24);

  // GRID & LAYOUT
  int get gridCrossAxisCount => value(mobile: 2, tablet: 4, desktop: 6);
  double get gridChildAspectRatio =>
      value(mobile: 1.0, tablet: 1.2, desktop: 1.4);
  double get gridSpacing => value(mobile: 8.0, tablet: 12.0, desktop: 16.0);

  // BOTTOM NAVIGATION
  double get bottomNavHeight => value(mobile: 70, tablet: 80, desktop: 90);
  double get fabMarginBottom =>
      value(
        mobile: 80,
        tablet: 100,
        desktop: 120,
      ) +
      safeAreaBottom;
}
