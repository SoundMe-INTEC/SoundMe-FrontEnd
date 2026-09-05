import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color primaryNavy = Color(0xFF002D62);
  static const Color accentRed = Color(0xFFCE1126);
  // WCAG AA compliant text colors (>4.5:1 on white and on inputFillColor #E7EAEE)
  static const Color textGray = Color(0xFF595959); // 5.9:1 on E7EAEE, 7.0:1 on White
  static const Color textSecondary = Color(0xFF555555);

  // Colores globales
  static const Color backgroundWhite = Colors.white;
  static const Color textBlack = Colors.black;
  static const Color inputFillColor = Color(0xFFE7EAEE);
  static const Color cardBlue = Color(0xFF4FA3D1);
  // Color de texto con ratio 4.89:1 sobre cardBlue (frente a 2.80:1 de blanco)
  static const Color cardBlueText = Color(0xFF002D62);

  // Colores para el Taskbar
  static const Color cardFillColor = Color(0xFFE7EAEE);
  static const Color accentLightBlue = Color(0x264FA3D1); // 15% opacidad
}