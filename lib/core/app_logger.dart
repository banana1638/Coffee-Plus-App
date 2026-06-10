import 'package:flutter/foundation.dart';

/// 统一日志工具 — 替代散落各处的 debugPrint / print
///
/// 设计原则：
/// - debug/info：只在 kDebugMode 输出（开发时）
/// - warning：在 debug 和 profile 模式输出（但不是 release）
/// - error：任何模式都记录消息，但 release 模式隐藏内部细节
class AppLogger {
  // 工具类，禁止实例化
  AppLogger._();

  /// 开发调试信息（仅 Debug 模式）
  static void debug(String message) {
    if (kDebugMode) debugPrint('[DEBUG] $message');
  }

  /// 一般流程信息（仅 Debug 模式）
  static void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  /// 警告信息（Debug + Profile 模式）
  static void warning(String message) {
    if (!kReleaseMode) debugPrint('[WARN] $message');
  }

  /// 错误信息
  /// - Debug 模式：显示完整错误细节
  /// - Release 模式：只记录消息，隐藏内部堆栈（防止信息泄露）
  static void error(String message, {dynamic error}) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('       ↳ $error');
    } else {
      // Release 模式只记录友好消息，不暴露内部错误
      debugPrint('[ERROR] $message');
    }
  }
}