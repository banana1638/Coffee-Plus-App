import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String serifFamily = 'serif';
  static const String monoFamily = 'monospace';

  static TextStyle title(BuildContext context) {
    return TextStyle(
      color: context.appTextMain,
      fontFamily: serifFamily,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.1,
    );
  }

  static TextStyle sectionLabel(BuildContext context) {
    return TextStyle(
      color: context.appTextMuted,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
    );
  }

  static TextStyle money(BuildContext context, {double fontSize = 16}) {
    return TextStyle(
      color: context.appAccent,
      fontFamily: monoFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle ledger(BuildContext context, {double fontSize = 13}) {
    return TextStyle(
      color: context.appTextMain,
      fontFamily: monoFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
