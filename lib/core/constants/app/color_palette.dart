// lib/core/constants/app/color_palette.dart
//
// FAZ 8A: "Midnight Sapphire" — Premium kelime öğrenme renk paleti
//
// Tasarım felsefesi:
//   Light: Temiz, nefes alan, indigo vurguları
//   Dark: Derin lacivert (saf siyah değil), neon glow efektleri
//
// Token sistemi Material 3 ColorScheme ile birebir eşleşir.

import 'package:flutter/material.dart';

class ColorPalette {
  ColorPalette._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY — Indigo (Ana marka rengi)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400 (dark mode)
  static const Color primaryContainer = Color(0xFFE0E7FF); // Indigo 100
  static const Color primaryContainerDark = Color(0xFF312E81); // Indigo 900
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFFFFFFFF);

  // ═══════════════════════════════════════════════════════════════════════════
  // SECONDARY — Sky Blue (İkincil eylemler)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color secondary = Color(0xFF0EA5E9); // Sky 500
  static const Color secondaryLight = Color(0xFF38BDF8); // Sky 400
  static const Color secondaryContainer = Color(0xFFE0F2FE); // Sky 100
  static const Color secondaryContainerDark = Color(0xFF0C4A6E); // Sky 900

  // ═══════════════════════════════════════════════════════════════════════════
  // TERTIARY — Amber (XP, ödül, streak)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color tertiary = Color(0xFFF59E0B); // Amber 500
  static const Color tertiaryLight = Color(0xFFFBBF24); // Amber 400
  static const Color tertiaryContainer = Color(0xFFFEF3C7); // Amber 100
  static const Color tertiaryContainerDark = Color(0xFF78350F); // Amber 900

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC — Başarı / Hata / Uyarı / Bilgi
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFF34D399); // Emerald 400
  static const Color successContainer = Color(0xFFD1FAE5); // Emerald 100
  static const Color successContainerDark = Color(0xFF064E3B);

  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFF87171); // Red 400
  static const Color errorContainer = Color(0xFFFEE2E2); // Red 100
  static const Color errorContainerDark = Color(0xFF7F1D1D);

  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight = Color(0xFF60A5FA);

  // ═══════════════════════════════════════════════════════════════════════════
  // SURFACE — Arka plan ve kart renkleri
  // ═══════════════════════════════════════════════════════════════════════════

  // Light mode
  static const Color surfaceLight = Color(0xFFFAFBFF); // Çok hafif mavi-beyaz
  static const Color surfaceContainerLight = Color(0xFFFFFFFF); // Kart bg
  static const Color surfaceContainerHighLight =
      Color(0xFFF1F5F9); // İkincil kart
  static const Color surfaceContainerHighestLight =
      Color(0xFFE2E8F0); // Disabled bg

  // Dark mode — DERİN LACİVERT (saf siyah değil!)
  static const Color surfaceDark = Color(0xFF0F0F23); // Ana bg
  static const Color surfaceContainerDark = Color(0xFF1A1A35); // Kart bg
  static const Color surfaceContainerHighDark =
      Color(0xFF252547); // İkincil kart
  static const Color surfaceContainerHighestDark =
      Color(0xFF2F2F5A); // Disabled bg

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT — Metin renkleri
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color onSurfaceLight = Color(0xFF0F172A); // Slate 900
  static const Color onSurfaceVariantLight = Color(0xFF64748B); // Slate 500
  static const Color outlineLight = Color(0xFFCBD5E1); // Slate 300

  static const Color onSurfaceDark = Color(0xFFF1F5F9); // Slate 100
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8); // Slate 400
  static const Color outlineDark = Color(0xFF334155); // Slate 700

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENT — Marka gradientleri
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ana gradient: Splash, onboard header, premium kartlar
  static const List<Color> gradientPrimary = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF7C3AED), // Violet
    Color(0xFFA855F7), // Purple
  ];

  /// Dark mode gradient
  static const List<Color> gradientPrimaryDark = [
    Color(0xFF312E81),
    Color(0xFF4C1D95),
    Color(0xFF6D28D9),
  ];

  /// Accent gradient: Quiz progress, secondary CTA
  static const List<Color> gradientAccent = [
    Color(0xFF0EA5E9),
    Color(0xFF06B6D4),
  ];

  /// XP / Streak / Ödül gradient
  static const List<Color> gradientGold = [
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  /// Başarı gradient
  static const List<Color> gradientSuccess = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  /// Kart subtle gradient (glassmorphism)
  static const List<Color> gradientGlassLight = [
    Color(0x0A4F46E5), // primary %4
    Color(0x05FFFFFF),
  ];

  static const List<Color> gradientGlassDark = [
    Color(0x15818CF8), // primary light %8
    Color(0x08FFFFFF),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // CHART — Grafik renkleri
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color chartVolume = Color(0xFF818CF8); // Indigo 400
  static const Color chartAccuracy = Color(0xFF34D399); // Emerald 400
  static const Color chartNew = Color(0xFF38BDF8); // Sky 400
  static const Color chartReview = Color(0xFFA78BFA); // Violet 400
  static const Color chartMastered = Color(0xFFFBBF24); // Amber 400
}
