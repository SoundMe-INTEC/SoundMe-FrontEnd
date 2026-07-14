import 'package:flutter/material.dart';

/// All brand colors and their generated shade swatches.
///
/// Each swatch runs from 50 (near-white / lightest tint) to 900
/// (near-black / darkest shade), matching the strip pattern in the
/// style guide: base color on the left fading to white on the right,
/// with a darker/black tail before it.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------
  // Base brand colors (from the style guide)
  // ---------------------------------------------------------------------
  static const Color primary = Color(0xFF003366); // Primary
  static const Color secondary = Color(0xFFCC0000); // Secondary
  static const Color tertiary = Color(0xFF4A90E2); // Tertiary
  static const Color neutral = Color(0xFFF0F2F5); // Neutral

  // ---------------------------------------------------------------------
  // Generated swatches
  // ---------------------------------------------------------------------
  static final MaterialColor primarySwatch = _createSwatch(primary);
  static final MaterialColor secondarySwatch = _createSwatch(secondary);
  static final MaterialColor tertiarySwatch = _createSwatch(tertiary);

  /// Neutral is treated as a true grayscale ramp (black -> white),
  /// same as the bottom-left strip in the guide.
  static final MaterialColor neutralSwatch = _createGrayscaleSwatch();

  // Convenience accessors, e.g. AppColors.primaryShade(700)
  static Color primaryShade(int shade) => primarySwatch[shade]!;
  static Color secondaryShade(int shade) => secondarySwatch[shade]!;
  static Color tertiaryShade(int shade) => tertiarySwatch[shade]!;
  static Color neutralShade(int shade) => neutralSwatch[shade]!;

  // Frequently used semantic aliases
  static const Color inverted = Color(0xFF1A1A1A); // "Inverted" button color
  static const Color surface = Colors.white;
  static const Color background = neutral;
  static const Color outline = Color(0xFFD5D9DE);

  // ---------------------------------------------------------------------
  // Swatch generation helpers
  // ---------------------------------------------------------------------

  /// Builds a Material-style swatch from a single base color by blending
  /// it toward white (for lighter tints) and toward black (for darker
  /// shades), the same technique used to generate the strips shown in
  /// the guide.
  static MaterialColor _createSwatch(Color base) {
    final Map<int, Color> shades = {
      50: _tint(base, 0.94),
      100: _tint(base, 0.85),
      200: _tint(base, 0.70),
      300: _tint(base, 0.50),
      400: _tint(base, 0.28),
      500: base,
      600: _shade(base, 0.12),
      700: _shade(base, 0.26),
      800: _shade(base, 0.40),
      900: _shade(base, 0.55),
    };
    return MaterialColor(base.value, shades);
  }

  static MaterialColor _createGrayscaleSwatch() {
    final Map<int, Color> shades = {
      50: const Color(0xFFFAFAFA),
      100: const Color(0xFFF0F2F5), // brand neutral base
      200: const Color(0xFFE1E4E8),
      300: const Color(0xFFC9CDD2),
      400: const Color(0xFFA9AEB4),
      500: const Color(0xFF888E96),
      600: const Color(0xFF666C74),
      700: const Color(0xFF474C52),
      800: const Color(0xFF2A2D31),
      900: const Color(0xFF0D0E10),
    };
    return MaterialColor(0xFFF0F2F5, shades);
  }

  /// Blends [color] toward white. [amount] 0-1, higher = lighter.
  static Color _tint(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount)!;
  }

  /// Blends [color] toward black. [amount] 0-1, higher = darker.
  static Color _shade(Color color, double amount) {
    return Color.lerp(color, Colors.black, amount)!;
  }
}
