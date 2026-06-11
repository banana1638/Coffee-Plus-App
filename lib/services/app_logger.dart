import 'package:flutter/foundation.dart';

/// Shared logger for debug, profile, and release builds.
class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (kDebugMode) debugPrint('[DEBUG] $message');
  }

  static void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  static void warning(String message) {
    if (!kReleaseMode) debugPrint('[WARN] $message');
  }

  static void error(String message, {dynamic error}) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('       -> $error');
    } else {
      debugPrint('[ERROR] $message');
    }
  }
}
