import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand Primary & Accent
  static const Color primaryNavy = Color(0xFF002D62);
  static const Color primaryNavyDark = Color(0xFF001F45);
  static const Color primaryNavyLight = Color(0xFF0A448C);
  
  static const Color accentRed = Color(0xFFCE1126);
  static const Color accentRedLight = Color(0xFFFF4D63);
  
  // Neutral Text Colors (WCAG AA Compliant)
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGray = Color(0xFF595959);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // Background & Surfaces
  static const Color backgroundWhite = Colors.white;
  static const Color backgroundOffWhite = Color(0xFFF8FAFC);
  static const Color inputFillColor = Color(0xFFF1F5F9);
  static const Color cardFillColor = Color(0xFFF1F5F9);
  static const Color cardBorderColor = Color(0xFFE2E8F0);
  
  static const Color cardBlue = Color(0xFF4FA3D1);
  static const Color cardBlueText = Color(0xFF002D62);
  static const Color accentLightBlue = Color(0x1F4FA3D1);

  // Soft shadows
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF002D62).withValues(alpha: 0.07),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}