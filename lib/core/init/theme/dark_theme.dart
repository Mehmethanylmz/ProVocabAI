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

      scaffoldBackgroundColor: ColorPalette.black,

      colorScheme: const ColorScheme.dark(
        primary: ColorPalette.royalBlue,
        onPrimary: ColorPalette.white,
        secondary: ColorPalette.emeraldGreen,
        onSecondary: ColorPalette.black,
        surface: ColorPalette.darkSurface,
        onSurface: ColorPalette.white,
        error: ColorPalette.softRedError,
        onError: ColorPalette.black,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: ColorPalette.white),
        titleTextStyle: TextStyle(
          color: ColorPalette.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Typography (Beyaz Yazılar)
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: ColorPalette.white,
        displayColor: ColorPalette.white,
      ),

      // Kartlar (Koyu Gri)
      cardTheme: CardThemeData(
        color: ColorPalette.darkSurface,
        elevation:
            0, // Dark mode'da gölge yerine border veya renk farkı tercih edilir
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: ColorPalette.white.withOpacity(0.05)), // Hafif border
        ),
        margin: EdgeInsets.zero,
      ),

      // Butonlar
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.royalBlue,
          foregroundColor: ColorPalette.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // Input Alanları (Koyu Gri Dolgu)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            ColorPalette.darkSurface, // Kart rengiyle aynı veya biraz farklı
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorPalette.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.royalBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: ColorPalette.softRedError, width: 1),
        ),
        labelStyle: const TextStyle(color: ColorPalette.gray100),
        hintStyle: TextStyle(color: ColorPalette.gray100.withOpacity(0.5)),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: ColorPalette.white.withOpacity(0.1),
        thickness: 1,
        space: 1,
      ),

      // Extension (Dark Mode Özel Renkleri)
      extensions: [
        AppThemeExtension(
          success: ColorPalette.brightGreen, // Daha parlak yeşil
          warning: ColorPalette.yellowWarning, // Daha parlak sarı
          info: ColorPalette.darkInfoBlue,
          gradientPurple: [
            ColorPalette.darkGradientPurpleStart,
            ColorPalette.darkGradientPurpleEnd
          ],
          gradientBlue: [
            ColorPalette.darkGradientBlueStart,
            ColorPalette.darkGradientBlueEnd
          ],
          chartVolume: ColorPalette.chartVolume,
          chartAccuracy: ColorPalette.chartAccuracy,
        ),
      ],
    );
  }
}
