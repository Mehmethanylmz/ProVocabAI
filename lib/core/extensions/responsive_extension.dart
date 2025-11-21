import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;

  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1200;
  bool get isDesktop => width >= 1200;

  T value<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  double wp(double percent) => width * (percent / 100);
  double hp(double percent) => height * (percent / 100);

  double get lowValue => value(mobile: 4, tablet: 8);
  double get normalValue => value(mobile: 8, tablet: 12);
  double get mediumValue => value(mobile: 16, tablet: 24);
  double get highValue => value(mobile: 24, tablet: 32);
  double get extraHighValue => value(mobile: 32, tablet: 48);

  EdgeInsets get paddingLow => EdgeInsets.all(lowValue);
  EdgeInsets get paddingNormal => EdgeInsets.all(normalValue);
  EdgeInsets get paddingMedium => EdgeInsets.all(mediumValue);
  EdgeInsets get paddingHigh => EdgeInsets.all(highValue);
  EdgeInsets get paddingHorizontalMedium =>
      EdgeInsets.symmetric(horizontal: mediumValue);

  double get fontSmall => value(mobile: 12, tablet: 14);
  double get fontNormal => value(mobile: 14, tablet: 16);
  double get fontMedium => value(mobile: 16, tablet: 18);
  double get fontLarge => value(mobile: 20, tablet: 24);
  double get fontXLarge => value(mobile: 24, tablet: 32);
  double get fontHuge => value(mobile: 32, tablet: 48);

  double get iconSmall => value(mobile: 16, tablet: 20);
  double get iconNormal => value(mobile: 24, tablet: 28);
  double get iconLarge => value(mobile: 32, tablet: 40);
}
