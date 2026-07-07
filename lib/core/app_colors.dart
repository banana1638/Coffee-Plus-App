import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF6F7F3);
  static const Color surface = Color(0xFFFFFFFC);
  static const Color surfaceSubtle = Color(0xFFF5F5F0);
  static const Color primary = Color(0xFF136F54);
  static const Color primaryHover = Color(0xFF0D523F);
  static const Color accent = Color(0xFFB87E2D);
  static const Color textMain = Color(0xFF18201D);
  static const Color textBody = Color(0xFF39433E);
  static const Color textMuted = Color(0xFF5B6762);
  static const Color textSubtle = Color(0xFF8B948F);
  static const Color border = Color(0xFFDADFD8);
  static const Color borderStrong = Color(0xFFC4CBC2);
  static const Color darkAction = Color(0xFF18201D);
  static const Color success = Color(0xFF047857);
  static const Color danger = Color(0xFFE11D48);
  static const Color warning = Color(0xFFD97706);

  static const Color coffee = Color(0xFF4B2616);
  static const Color coffeeDark = Color(0xFF2A1710);
}

class AppColorsDark {
  AppColorsDark._();

  static const Color background = Color(0xFF101512);
  static const Color surface = Color(0xFF18201D);
  static const Color surfaceSubtle = Color(0xFF202B27);
  static const Color primary = Color(0xFF6EE7B7);
  static const Color primaryHover = Color(0xFFA7F3D0);
  static const Color accent = Color(0xFFF2B866);
  static const Color textMain = Color(0xFFF8FAF6);
  static const Color textBody = Color(0xFFDCE4DE);
  static const Color textMuted = Color(0xFFA7B2AB);
  static const Color textSubtle = Color(0xFF76837C);
  static const Color border = Color(0xFF33413A);
  static const Color borderStrong = Color(0xFF46564E);
  static const Color darkAction = Color(0xFFF8FAF6);
  static const Color success = Color(0xFF34D399);
  static const Color danger = Color(0xFFFB7185);
  static const Color warning = Color(0xFFFBBF24);

  static const Color coffee = Color(0xFFC47B3A);
  static const Color coffeeDark = Color(0xFF6F3F24);
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
