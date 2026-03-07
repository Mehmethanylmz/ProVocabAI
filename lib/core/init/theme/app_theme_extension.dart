// lib/core/init/theme/app_theme_extension.dart
//
// FAZ 8A: Genişletilmiş tema extension
//   - Gradient listesi (primary, accent, gold, success, glass)
//   - Semantic renkler (success, warning, info, tertiary)
//   - Chart renkleri
//   - Glow shadow renkleri

import 'package:flutter/material.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color success;
  final Color warning;
  final Color info;
  final Color tertiary;
  final Color tertiaryContainer;

  final List<Color> gradientPrimary;
  final List<Color> gradientAccent;
  final List<Color> gradientGold;
  final List<Color> gradientSuccess;
  final List<Color> gradientGlass;

  // Eski uyumluluk (gradientPurple / gradientBlue)
  List<Color> get gradientPurple => gradientPrimary;
  List<Color> get gradientBlue => gradientAccent;

  final Color chartVolume;
  final Color chartAccuracy;
  final Color chartNew;
  final Color chartReview;
  final Color chartMastered;

  /// Primary rengin glow shadow'u (blur efektleri için)
  final Color glowPrimary;
  final Color glowSuccess;
  final Color glowError;

  // ── Kart tipi rozet renkleri (FAZ 17 — F17-01) ──────────────────────────────
  // Dark/light modda otomatik uyum sağlar; hardcoded Color() kullanımı kaldırıldı.

  /// "Yeni" kart rozeti rengi — Sky/Secondary tonu
  final Color cardNew;

  /// "Zor/Leech" kart rozeti rengi — Error tonu
  final Color cardLeech;

  /// "Tekrar/Due" kart rozeti rengi — Success/Emerald tonu
  final Color cardDue;

  AppThemeExtension({
    required this.success,
    required this.warning,
    required this.info,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.gradientPrimary,
    required this.gradientAccent,
    required this.gradientGold,
    required this.gradientSuccess,
    required this.gradientGlass,
    required this.chartVolume,
    required this.chartAccuracy,
    required this.chartNew,
    required this.chartReview,
    required this.chartMastered,
    required this.glowPrimary,
    required this.glowSuccess,
    required this.glowError,
    required this.cardNew,
    required this.cardLeech,
    required this.cardDue,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? tertiary,
    Color? tertiaryContainer,
    List<Color>? gradientPrimary,
    List<Color>? gradientAccent,
    List<Color>? gradientGold,
    List<Color>? gradientSuccess,
    List<Color>? gradientGlass,
    Color? chartVolume,
    Color? chartAccuracy,
    Color? chartNew,
    Color? chartReview,
    Color? chartMastered,
    Color? glowPrimary,
    Color? glowSuccess,
    Color? glowError,
    Color? cardNew,
    Color? cardLeech,
    Color? cardDue,
  }) {
    return AppThemeExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      tertiary: tertiary ?? this.tertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      gradientPrimary: gradientPrimary ?? this.gradientPrimary,
      gradientAccent: gradientAccent ?? this.gradientAccent,
      gradientGold: gradientGold ?? this.gradientGold,
      gradientSuccess: gradientSuccess ?? this.gradientSuccess,
      gradientGlass: gradientGlass ?? this.gradientGlass,
      chartVolume: chartVolume ?? this.chartVolume,
      chartAccuracy: chartAccuracy ?? this.chartAccuracy,
      chartNew: chartNew ?? this.chartNew,
      chartReview: chartReview ?? this.chartReview,
      chartMastered: chartMastered ?? this.chartMastered,
      glowPrimary: glowPrimary ?? this.glowPrimary,
      glowSuccess: glowSuccess ?? this.glowSuccess,
      glowError: glowError ?? this.glowError,
      cardNew: cardNew ?? this.cardNew,
      cardLeech: cardLeech ?? this.cardLeech,
      cardDue: cardDue ?? this.cardDue,
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
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      tertiaryContainer:
          Color.lerp(tertiaryContainer, other.tertiaryContainer, t)!,
      gradientPrimary:
          _lerpColorList(gradientPrimary, other.gradientPrimary, t),
      gradientAccent: _lerpColorList(gradientAccent, other.gradientAccent, t),
      gradientGold: _lerpColorList(gradientGold, other.gradientGold, t),
      gradientSuccess:
          _lerpColorList(gradientSuccess, other.gradientSuccess, t),
      gradientGlass: _lerpColorList(gradientGlass, other.gradientGlass, t),
      chartVolume: Color.lerp(chartVolume, other.chartVolume, t)!,
      chartAccuracy: Color.lerp(chartAccuracy, other.chartAccuracy, t)!,
      chartNew: Color.lerp(chartNew, other.chartNew, t)!,
      chartReview: Color.lerp(chartReview, other.chartReview, t)!,
      chartMastered: Color.lerp(chartMastered, other.chartMastered, t)!,
      glowPrimary: Color.lerp(glowPrimary, other.glowPrimary, t)!,
      glowSuccess: Color.lerp(glowSuccess, other.glowSuccess, t)!,
      glowError: Color.lerp(glowError, other.glowError, t)!,
      cardNew: Color.lerp(cardNew, other.cardNew, t)!,
      cardLeech: Color.lerp(cardLeech, other.cardLeech, t)!,
      cardDue: Color.lerp(cardDue, other.cardDue, t)!,
    );
  }

  List<Color> _lerpColorList(List<Color> a, List<Color> b, double t) {
    final length = a.length < b.length ? a.length : b.length;
    return List.generate(length, (i) => Color.lerp(a[i], b[i], t)!);
  }
}
