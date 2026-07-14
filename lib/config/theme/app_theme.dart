import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Central app theme. Use with:
///   MaterialApp(theme: AppTheme.light, ...)
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.neutralShade(900),
      error: AppColors.secondary,
      onError: Colors.white,
      outline: AppColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme,
      fontFamily: AppTypography.bodyMedium.fontFamily,

      // ---------------------------------------------------------------
      // AppBar
      // ---------------------------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headlineSmall,
      ),

      // ---------------------------------------------------------------
      // Buttons — "Primary" filled style is the theme default.
      // See AppButtonStyles for Secondary / Inverted / Outlined.
      // ---------------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppButtonStyles.primary,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppButtonStyles.outlined,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.labelMedium,
        ),
      ),

      // ---------------------------------------------------------------
      // Search bar / text fields
      // ---------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutralShade(100),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutralShade(500),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: AppColors.tertiary, width: 1.5),
        ),
      ),

      // ---------------------------------------------------------------
      // Bottom navigation (Home / Search / Profile pill)
      // ---------------------------------------------------------------
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.neutralShade(100),
        indicatorColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? Colors.white : AppColors.neutralShade(700),
          );
        }),
        labelTextStyle: WidgetStateProperty.all(AppTypography.labelSmall),
      ),

      // ---------------------------------------------------------------
      // Linear progress bars (as in the 3-bar progress card)
      // ---------------------------------------------------------------
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.neutralShade(200),
        circularTrackColor: AppColors.neutralShade(200),
      ),

      // ---------------------------------------------------------------
      // Icon buttons (edit / wand / tag / delete circular actions)
      // ---------------------------------------------------------------
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(12),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.neutralShade(200),
        thickness: 1,
      ),

      cardTheme: CardThemeData(
        color: AppColors.neutralShade(100),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

/// Named button styles matching the four variants shown in the guide:
/// Primary, Secondary, Inverted, Outlined.
class AppButtonStyles {
  AppButtonStyles._();

  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  static final ButtonStyle primary = FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    disabledBackgroundColor: AppColors.primaryShade(200),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: AppTypography.labelXL,
  );

  static final ButtonStyle secondary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.neutralShade(200),
    foregroundColor: AppColors.neutralShade(800),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: AppTypography.labelXL.copyWith(
      color: AppColors.neutralShade(800),
    ),
  );

  static final ButtonStyle inverted = ElevatedButton.styleFrom(
    backgroundColor: AppColors.inverted,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: AppTypography.labelXL,
  );

  static final ButtonStyle outlined = OutlinedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.neutralShade(800),
    side: BorderSide(color: AppColors.outline, width: 1.5),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: AppTypography.labelXL.copyWith(
      color: AppColors.neutralShade(800),
    ),
  );

  /// Small square icon-only button (the blue edit-pencil squares).
  static final ButtonStyle iconSquarePrimary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.all(14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    minimumSize: const Size(48, 48),
  );

  /// Circular action buttons (wand / cube / tag / delete row).
  static ButtonStyle circularAction(Color background) =>
      ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(14),
      );
}
