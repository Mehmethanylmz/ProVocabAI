// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);

  // Gradient Sets
  static const List<Color> gradientBlue = [
    Color(0xFF4facfe),
    Color(0xFF00f2fe)
  ];
  static const List<Color> gradientPurple = [
    Color(0xFF667eea),
    Color(0xFF764ba2)
  ];
  static const List<Color> gradientGreen = [
    Color(0xFF11998e),
    Color(0xFF38ef7d)
  ];
  static const List<Color> gradientPink = [
    Color(0xFFF093FB),
    Color(0xFFF5576C)
  ];
  static const List<Color> gradientOrange = [
    Color(0xFFF09819),
    Color(0xFFEDDE5D)
  ];

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Neutral Colors
  static const Color background = Color(0xFFF8F9FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1F2937);
  static const Color onSurfaceVariant = Color(0xFF6B7280);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);

  // Border Colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);

  // Chart Colors
  static const Color chartAccuracy = Color(0xFF50E3C2);
  static const Color chartVolume = Color(0xFFFFB74D);

  // Method to get gradient by index (for consistent theming)
  static List<Color> getGradient(int index) {
    final gradients = [
      gradientBlue,
      gradientPurple,
      gradientGreen,
      gradientPink,
      gradientOrange
    ];
    return gradients[index % gradients.length];
  }

  // Method for success rate color
  static Color getSuccessColor(double rate) {
    if (rate >= 80) return success;
    if (rate >= 60) return warning;
    return error;
  }
}
