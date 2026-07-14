import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Text styles built on Hanken Grotesk, matching the Headline / Body /
/// Label samples in the style guide.
///
/// Requires the `google_fonts` package:
///   flutter pub add google_fonts
class AppTypography {
  AppTypography._();

  static TextStyle _base({
    required double fontSize,
    required FontWeight weight,
    Color color = AppColors.inverted,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.hankenGrotesk(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Headline — large, bold (matches the big "Aa" in the Headline card)
  static TextStyle headlineLarge = _base(fontSize: 40, weight: FontWeight.w700);
  static TextStyle headlineMedium = _base(
    fontSize: 32,
    weight: FontWeight.w700,
  );
  static TextStyle headlineSmall = _base(fontSize: 26, weight: FontWeight.w600);

  // Body — regular weight, softer gray-black
  static TextStyle bodyLarge = _base(
    fontSize: 18,
    weight: FontWeight.w400,
    color: AppColors.neutralShade(800),
  );
  static TextStyle bodyMedium = _base(
    fontSize: 15,
    weight: FontWeight.w400,
    color: AppColors.neutralShade(800),
  );
  static TextStyle bodySmall = _base(
    fontSize: 13,
    weight: FontWeight.w400,
    color: AppColors.neutralShade(700),
  );

  // Label — medium weight, used on buttons/chips/inputs
  static TextStyle labelXL = _base(fontSize: 20, weight: FontWeight.w600);
  static TextStyle labelLarge = _base(fontSize: 16, weight: FontWeight.w600);
  static TextStyle labelMedium = _base(fontSize: 14, weight: FontWeight.w600);
  static TextStyle labelSmall = _base(
    fontSize: 12,
    weight: FontWeight.w500,
    color: AppColors.neutralShade(600),
  );

  static TextTheme get textTheme => TextTheme(
    displayLarge: headlineLarge,
    displayMedium: headlineMedium,
    displaySmall: headlineSmall,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
