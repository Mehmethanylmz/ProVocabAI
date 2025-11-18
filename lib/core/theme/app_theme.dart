import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ColorScheme lightScheme = ColorScheme.light(
    primary: Colors.indigo.shade400,
    primaryContainer: Colors.indigo.shade50,
    secondary: Colors.teal.shade400,
    surface: Colors.white.withOpacity(0.85),
    surfaceContainerHighest: Colors.grey.shade200.withOpacity(0.4),
  );

  static final ColorScheme darkScheme = ColorScheme.dark(
    primary: Colors.indigo.shade300,
    primaryContainer: Colors.indigo.shade900.withOpacity(0.4),
    secondary: Colors.teal.shade300,
    surface: Colors.white.withOpacity(0.08),
    surfaceContainerHighest: Colors.white.withOpacity(0.05),
  );

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: lightScheme,
    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: darkScheme,
    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.white,
    ),
  );
}
