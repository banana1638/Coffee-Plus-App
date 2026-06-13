import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Shared logger for non-release diagnostics.
class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (kDebugMode) developer.log(message, name: 'CoffeePlus.debug');
  }

  static void info(String message) {
    if (kDebugMode) developer.log(message, name: 'CoffeePlus.info');
  }

  static void warning(String message) {
    if (kDebugMode) developer.log(message, name: 'CoffeePlus.warning');
  }

  static void error(String message, {dynamic error}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'CoffeePlus.error',
        error: error == null ? null : error.toString(),
      );
    }
  }
}
