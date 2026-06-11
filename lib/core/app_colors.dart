import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryHover = Color(0xFF4338CA);
  static const Color accent = Color(0xFF6366F1);
  static const Color textMain = Color(0xFF020617);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color darkAction = Color(0xFF0F172A);
  static const Color success = Color(0xFF047857);
  static const Color danger = Color(0xFFE11D48);
  static const Color warning = Color(0xFFD97706);

  static const Color coffee = primary;
  static const Color coffeeDark = darkAction;
}

class AppColorsDark {
  AppColorsDark._();

  static const Color background = Color(0xFF020617);
  static const Color surface = Color(0xFF0F172A);
  static const Color surfaceSubtle = Color(0xFF1E293B);
  static const Color primary = Color(0xFF818CF8);
  static const Color primaryHover = Color(0xFFA5B4FC);
  static const Color accent = Color(0xFF6366F1);
  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textBody = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);
  static const Color border = Color(0xFF334155);
  static const Color borderStrong = Color(0xFF475569);
  static const Color darkAction = Color(0xFFF8FAFC);
  static const Color success = Color(0xFF34D399);
  static const Color danger = Color(0xFFFB7185);
  static const Color warning = Color(0xFFFBBF24);

  static const Color coffee = primary;
  static const Color coffeeDark = surfaceSubtle;
}

extension AppThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground =>
      isDarkMode ? AppColorsDark.background : AppColors.background;
  Color get appSurface =>
      isDarkMode ? AppColorsDark.surface : AppColors.surface;
  Color get appSurfaceSubtle =>
      isDarkMode ? AppColorsDark.surfaceSubtle : AppColors.surfaceSubtle;
  Color get appPrimary =>
      isDarkMode ? AppColorsDark.primary : AppColors.primary;
  Color get appPrimaryHover =>
      isDarkMode ? AppColorsDark.primaryHover : AppColors.primaryHover;
  Color get appAccent => isDarkMode ? AppColorsDark.accent : AppColors.accent;
  Color get appTextMain =>
      isDarkMode ? AppColorsDark.textMain : AppColors.textMain;
  Color get appTextBody =>
      isDarkMode ? AppColorsDark.textBody : AppColors.textBody;
  Color get appTextMuted =>
      isDarkMode ? AppColorsDark.textMuted : AppColors.textMuted;
  Color get appTextSubtle =>
      isDarkMode ? AppColorsDark.textSubtle : AppColors.textSubtle;
  Color get appCoffee => isDarkMode ? AppColorsDark.coffee : AppColors.coffee;
  Color get appCoffeeDark =>
      isDarkMode ? AppColorsDark.coffeeDark : AppColors.coffeeDark;
  Color get appBorder => isDarkMode ? AppColorsDark.border : AppColors.border;
  Color get appBorderStrong =>
      isDarkMode ? AppColorsDark.borderStrong : AppColors.borderStrong;
  Color get appDarkAction =>
      isDarkMode ? AppColorsDark.darkAction : AppColors.darkAction;
  Color get appSuccess =>
      isDarkMode ? AppColorsDark.success : AppColors.success;
  Color get appDanger => isDarkMode ? AppColorsDark.danger : AppColors.danger;
  Color get appWarning =>
      isDarkMode ? AppColorsDark.warning : AppColors.warning;
}
