import 'package:flutter/material.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color success;
  final Color warning;
  final Color info;
  final List<Color> gradientPurple;
  final List<Color> gradientBlue;
  final Color chartVolume;
  final Color chartAccuracy;

  AppThemeExtension({
    required this.success,
    required this.warning,
    required this.info,
    required this.gradientPurple,
    required this.gradientBlue,
    required this.chartVolume,
    required this.chartAccuracy,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? success,
    Color? warning,
    Color? info,
    List<Color>? gradientPurple,
    List<Color>? gradientBlue,
    Color? chartVolume,
    Color? chartAccuracy,
  }) {
    return AppThemeExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      gradientPurple: gradientPurple ?? this.gradientPurple,
      gradientBlue: gradientBlue ?? this.gradientBlue,
      chartVolume: chartVolume ?? this.chartVolume,
      chartAccuracy: chartAccuracy ?? this.chartAccuracy,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
      ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      gradientPurple: other.gradientPurple,
      gradientBlue: other.gradientBlue,
      chartVolume: Color.lerp(chartVolume, other.chartVolume, t)!,
      chartAccuracy: Color.lerp(chartAccuracy, other.chartAccuracy, t)!,
    );
  }
}
