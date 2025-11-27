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

      // Arka plan
      scaffoldBackgroundColor: ColorPalette.gray100,

      // Temel Renk Şeması
      colorScheme: const ColorScheme.light(
        primary: ColorPalette.royalBlue,
        onPrimary: ColorPalette.white,
        secondary: ColorPalette.emeraldGreen,
        onSecondary: ColorPalette.white,
        surface: ColorPalette.white,
        onSurface: ColorPalette.gray900,
        error: ColorPalette.redError,
        onError: ColorPalette.white,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: ColorPalette.gray900),
        titleTextStyle: TextStyle(
          color: ColorPalette.gray900,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Text (VİRGÜLE DİKKAT)
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: ColorPalette.gray900,
        displayColor: ColorPalette.gray900,
      ), // <--- BURADAKİ VİRGÜL ÇOK ÖNEMLİ

      // Kartlar
      cardTheme: CardThemeData(
        color: ColorPalette.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),

      // Butonlar
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.royalBlue,
          foregroundColor: ColorPalette.white,
          elevation: 4,
          shadowColor: ColorPalette.royalBlue.withOpacity(0.3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // Input Alanları (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.gray800, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorPalette.gray800.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.royalBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.redError, width: 1),
        ),
        labelStyle: const TextStyle(color: ColorPalette.gray800),
        hintStyle: TextStyle(color: ColorPalette.gray800.withOpacity(0.5)),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: ColorPalette.gray800.withOpacity(0.1),
        thickness: 1,
        space: 1,
      ),

      // Extension (Özel Renkler)
      extensions: [
        AppThemeExtension(
          success: ColorPalette.emeraldGreen,
          warning: ColorPalette.amberWarning,
          info: ColorPalette.infoBlue,
          gradientPurple: [
            ColorPalette.gradientPurpleStart,
            ColorPalette.gradientPurpleEnd
          ],
          gradientBlue: [ColorPalette.lightBlue, ColorPalette.royalBlue],
          chartVolume: ColorPalette.chartVolume,
          chartAccuracy: ColorPalette.chartAccuracy,
        ),
      ],
    );
  }
}
