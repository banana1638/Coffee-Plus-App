import 'package:flutter/material.dart';

class AppColors {
  // 基础背景 (对应 Tailwind bg-gray-50/50)
  static const Color background = Color(0xFFF9FAFB);
  // 卡片背景 (对应 Tailwind bg-white)
  static const Color surface = Color(0xFFFFFFFF);
  // 主色调 (对应 Tailwind bg-blue-600)
  static const Color primary = Color(0xFF2563EB);
  // 强调色 (对应 Tailwind bg-blue-500)
  static const Color accent = Color(0xFF3B82F6);
  // 文字颜色 (对应 Tailwind text-gray-900)
  static const Color textMain = Color(0xFF111827);
  // 副文本颜色 (对应 Tailwind text-gray-400)
  static const Color textMuted = Color(0xFF9CA3AF);
  // 咖啡相关颜色
  static const Color coffee = Color(0xFF6F4E37);
  static const Color coffeeDark = Color(0xFF5D3A1A);
  // 边框颜色 (对应 Tailwind border-gray-100)
  static const Color border = Color(0xFFF3F4F6);
}

class AppColorsDark {
  // 基础背景 - 深邃曜石黑 (不再是纯黑，更有质感)
  static const Color background = Color(0xFF0D1117);
  // 卡片背景 - 午夜灰 (提升层次感)
  static const Color surface = Color(0xFF161B22);
  // 次级卡片背景
  static const Color surfaceSubtle = Color(0xFF21262D);
  // 主色调 - 荧光蓝 (在暗色下更醒目)
  static const Color primary = Color(0xFF58A6FF);
  // 强调色
  static const Color accent = Color(0xFF1F6FEB);
  // 主要文字 - 银白 (减少对比度带来的刺眼感)
  static const Color textMain = Color(0xFFE6EDF3);
  // 辅助文字 - 钢灰
  static const Color textMuted = Color(0xFF8B949E);
  // 咖啡相关颜色 (暗色模式下稍微提亮)
  static const Color coffee = Color(0xFF8B5E3C);
  static const Color coffeeDark = Color(0xFF6F4E37);
  // 边框颜色 - 灰岩色
  static const Color border = Color(0xFF30363D);
}

extension AppThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground => isDarkMode ? AppColorsDark.background : AppColors.background;
  Color get appSurface => isDarkMode ? AppColorsDark.surface : AppColors.surface;
  Color get appSurfaceSubtle => isDarkMode ? AppColorsDark.surfaceSubtle : AppColors.background;
  Color get appPrimary => isDarkMode ? AppColorsDark.primary : AppColors.primary;
  Color get appAccent => isDarkMode ? AppColorsDark.accent : AppColors.accent;
  Color get appTextMain => isDarkMode ? AppColorsDark.textMain : AppColors.textMain;
  Color get appTextMuted => isDarkMode ? AppColorsDark.textMuted : AppColors.textMuted;
  Color get appCoffee => isDarkMode ? AppColorsDark.coffee : AppColors.coffee;
  Color get appCoffeeDark => isDarkMode ? AppColorsDark.coffeeDark : AppColors.coffeeDark;
  Color get appBorder => isDarkMode ? AppColorsDark.border : AppColors.border;
}
