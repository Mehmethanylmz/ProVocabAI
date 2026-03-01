// lib/core/init/theme/light_theme.dart
//
// FAZ 8A: Premium Light Theme — "Midnight Sapphire" paleti
//
// Felsefe: Temiz, nefes alan, indigo vurguları
// Kartlar beyaz, arka plan çok hafif mavi-beyaz, gölgeler yumuşak

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app/color_palette.dart';
import 'app_theme.dart';
import 'app_theme_extension.dart';

class LightTheme extends AppTheme {
  static LightTheme? _instance;
  static LightTheme get instance {
    _instance ??= LightTheme._init();
    return _instance!;
  }

  LightTheme._init() {
    themeData = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ── Arka plan ──────────────────────────────────────────────────────
      scaffoldBackgroundColor: ColorPalette.surfaceLight,

      // ── Renk Şeması ───────────────────────────────────────────────────
      colorScheme: const ColorScheme.light(
        primary: ColorPalette.primary,
        onPrimary: ColorPalette.onPrimary,
        primaryContainer: ColorPalette.primaryContainer,
        onPrimaryContainer: Color(0xFF1E1B4B), // Indigo 950

        secondary: ColorPalette.secondary,
        onSecondary: Colors.white,
        secondaryContainer: ColorPalette.secondaryContainer,
        onSecondaryContainer: Color(0xFF0C4A6E),

        tertiary: ColorPalette.tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: ColorPalette.tertiaryContainer,
        onTertiaryContainer: Color(0xFF78350F),

        surface: ColorPalette.surfaceLight,
        onSurface: ColorPalette.onSurfaceLight,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Color(0xFFF8FAFC),
        surfaceContainer: ColorPalette.surfaceContainerLight,
        surfaceContainerHigh: ColorPalette.surfaceContainerHighLight,
        surfaceContainerHighest: ColorPalette.surfaceContainerHighestLight,
        onSurfaceVariant: ColorPalette.onSurfaceVariantLight,

        outline: ColorPalette.outlineLight,
        outlineVariant: Color(0xFFE2E8F0),

        error: ColorPalette.error,
        onError: Colors.white,
        errorContainer: ColorPalette.errorContainer,
      ),

      // ── AppBar ─────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: ColorPalette.onSurfaceLight),
        titleTextStyle: GoogleFonts.inter(
          color: ColorPalette.onSurfaceLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      // ── Typography ─────────────────────────────────────────────────────
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: ColorPalette.onSurfaceLight,
        displayColor: ColorPalette.onSurfaceLight,
      ),

      // ── Kartlar ────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: ColorPalette.surfaceContainerLight,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: ColorPalette.outlineLight.withValues(alpha: 0.5),
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Butonlar ───────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primary,
          foregroundColor: Colors.white,
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
          side: const BorderSide(color: ColorPalette.outlineLight),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      // ── Input ──────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.surfaceContainerHighLight,
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
          borderSide: const BorderSide(color: ColorPalette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ColorPalette.error, width: 1),
        ),
        labelStyle: const TextStyle(color: ColorPalette.onSurfaceVariantLight),
        hintStyle: TextStyle(
            color: ColorPalette.onSurfaceVariantLight.withValues(alpha: 0.6)),
      ),

      // ── Chip ───────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: ColorPalette.surfaceContainerHighLight,
        selectedColor: ColorPalette.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide.none,
        labelStyle:
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),

      // ── Navigation Bar ─────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: ColorPalette.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ColorPalette.primary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: ColorPalette.onSurfaceVariantLight,
          );
        }),
      ),

      // ── Divider ────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: ColorPalette.outlineLight.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),

      // ── Bottom Sheet ───────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColorPalette.surfaceContainerLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // ── Dialog ─────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: ColorPalette.surfaceContainerLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),

      // ── Extension ──────────────────────────────────────────────────────
      extensions: [
        AppThemeExtension(
          success: ColorPalette.success,
          warning: ColorPalette.warning,
          info: ColorPalette.info,
          tertiary: ColorPalette.tertiary,
          tertiaryContainer: ColorPalette.tertiaryContainer,
          gradientPrimary: ColorPalette.gradientPrimary,
          gradientAccent: ColorPalette.gradientAccent,
          gradientGold: ColorPalette.gradientGold,
          gradientSuccess: ColorPalette.gradientSuccess,
          gradientGlass: ColorPalette.gradientGlassLight,
          chartVolume: ColorPalette.chartVolume,
          chartAccuracy: ColorPalette.chartAccuracy,
          chartNew: ColorPalette.chartNew,
          chartReview: ColorPalette.chartReview,
          chartMastered: ColorPalette.chartMastered,
          glowPrimary: ColorPalette.primary.withValues(alpha: 0.25),
          glowSuccess: ColorPalette.success.withValues(alpha: 0.25),
          glowError: ColorPalette.error.withValues(alpha: 0.25),
        ),
      ],
    );
  }
}
