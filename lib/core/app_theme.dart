import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceSubtle: AppColors.surfaceSubtle,
    primary: AppColors.primary,
    textMain: AppColors.textMain,
    textBody: AppColors.textBody,
    textMuted: AppColors.textMuted,
    border: AppColors.border,
  );

  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    background: AppColorsDark.background,
    surface: AppColorsDark.surface,
    surfaceSubtle: AppColorsDark.surfaceSubtle,
    primary: AppColorsDark.primary,
    textMain: AppColorsDark.textMain,
    textBody: AppColorsDark.textBody,
    textMuted: AppColorsDark.textMuted,
    border: AppColorsDark.border,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceSubtle,
    required Color primary,
    required Color textMain,
    required Color textBody,
    required Color textMuted,
    required Color border,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      surface: surface,
      onSurface: textMain,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: colorScheme.copyWith(
        secondary: primary,
        surface: surface,
        surfaceContainer: surfaceSubtle,
        onSurface: textMain,
      ),
      dividerColor: border,
      textTheme:
          (isDark
                  ? Typography.material2021().white
                  : Typography.material2021().black)
              .apply(bodyColor: textBody, displayColor: textMain),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 1,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textBody,
          minimumSize: const Size(double.infinity, 44),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
        labelStyle: TextStyle(color: textBody, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface.withValues(alpha: isDark ? 0.96 : 0.95),
        foregroundColor: textMain,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(color: textBody),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: isDark
            ? AppColorsDark.surfaceSubtle
            : AppColors.darkAction,
        disabledColor: surfaceSubtle,
        labelStyle: TextStyle(color: textBody, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? AppColorsDark.surfaceSubtle
            : AppColors.darkAction,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
