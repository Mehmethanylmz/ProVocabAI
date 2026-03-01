// lib/core/init/theme/dark_theme.dart
//
// FAZ 8A: Premium Dark Theme — "Midnight Sapphire"
//
// Felsefe: Derin lacivert (saf siyah DEĞİL), neon glow vurguları
// Kartlar koyu-mor, primary açık indigo, subtle glow efektleri

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app/color_palette.dart';
import 'app_theme.dart';
import 'app_theme_extension.dart';

class DarkTheme extends AppTheme {
  static DarkTheme? _instance;
  static DarkTheme get instance {
    _instance ??= DarkTheme._init();
    return _instance!;
  }

  DarkTheme._init() {
    themeData = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ColorPalette.surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: ColorPalette.primaryLight,
        onPrimary: Color(0xFF1E1B4B),
        primaryContainer: ColorPalette.primaryContainerDark,
        onPrimaryContainer: Color(0xFFE0E7FF),
        secondary: ColorPalette.secondaryLight,
        onSecondary: Color(0xFF0C4A6E),
        secondaryContainer: ColorPalette.secondaryContainerDark,
        onSecondaryContainer: Color(0xFFE0F2FE),
        tertiary: ColorPalette.tertiaryLight,
        onTertiary: Color(0xFF78350F),
        tertiaryContainer: ColorPalette.tertiaryContainerDark,
        onTertiaryContainer: Color(0xFFFEF3C7),
        surface: ColorPalette.surfaceDark,
        onSurface: ColorPalette.onSurfaceDark,
        surfaceContainerLowest: Color(0xFF0A0A1A),
        surfaceContainerLow: Color(0xFF12122A),
        surfaceContainer: ColorPalette.surfaceContainerDark,
        surfaceContainerHigh: ColorPalette.surfaceContainerHighDark,
        surfaceContainerHighest: ColorPalette.surfaceContainerHighestDark,
        onSurfaceVariant: ColorPalette.onSurfaceVariantDark,
        outline: ColorPalette.outlineDark,
        outlineVariant: Color(0xFF1E293B),
        error: ColorPalette.errorLight,
        onError: Color(0xFF7F1D1D),
        errorContainer: ColorPalette.errorContainerDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: ColorPalette.onSurfaceDark),
        titleTextStyle: GoogleFonts.inter(
          color: ColorPalette.onSurfaceDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: ColorPalette.onSurfaceDark,
        displayColor: ColorPalette.onSurfaceDark,
      ),
      cardTheme: CardThemeData(
        color: ColorPalette.surfaceContainerDark,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: ColorPalette.outlineDark.withValues(alpha: 0.3),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primaryLight,
          foregroundColor: const Color(0xFF1E1B4B),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: ColorPalette.outlineDark),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.surfaceContainerHighDark,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: ColorPalette.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: ColorPalette.errorLight, width: 1),
        ),
        labelStyle: const TextStyle(color: ColorPalette.onSurfaceVariantDark),
        hintStyle: TextStyle(
            color: ColorPalette.onSurfaceVariantDark.withValues(alpha: 0.6)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColorPalette.surfaceContainerHighDark,
        selectedColor: ColorPalette.primaryContainerDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide.none,
        labelStyle:
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: ColorPalette.primaryContainerDark,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ColorPalette.primaryLight,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: ColorPalette.onSurfaceVariantDark,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: ColorPalette.outlineDark.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColorPalette.surfaceContainerDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColorPalette.surfaceContainerDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      extensions: [
        AppThemeExtension(
          success: ColorPalette.successLight,
          warning: ColorPalette.warningLight,
          info: ColorPalette.infoLight,
          tertiary: ColorPalette.tertiaryLight,
          tertiaryContainer: ColorPalette.tertiaryContainerDark,
          gradientPrimary: ColorPalette.gradientPrimaryDark,
          gradientAccent: ColorPalette.gradientAccent,
          gradientGold: ColorPalette.gradientGold,
          gradientSuccess: ColorPalette.gradientSuccess,
          gradientGlass: ColorPalette.gradientGlassDark,
          chartVolume: ColorPalette.chartVolume,
          chartAccuracy: ColorPalette.chartAccuracy,
          chartNew: ColorPalette.chartNew,
          chartReview: ColorPalette.chartReview,
          chartMastered: ColorPalette.chartMastered,
          glowPrimary: ColorPalette.primaryLight.withValues(alpha: 0.2),
          glowSuccess: ColorPalette.successLight.withValues(alpha: 0.2),
          glowError: ColorPalette.errorLight.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}
