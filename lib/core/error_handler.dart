import 'package:dio/dio.dart';

class ErrorHandler {
  ErrorHandler._();

  /// 将各种异常转换为用户友好的提示信息
  static String toUserMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Request timed out. Please check your connection.';
        case DioExceptionType.connectionError:
          return 'Cannot connect to server. Please try again.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final serverMsg = _serverMessage(error.response?.data);
          if (statusCode == 401) return 'Session expired. Please login again.';
          if (statusCode == 403) {
            return 'You do not have permission to do this.';
          }
          if (statusCode == 409) {
            return serverMsg ??
                'This request conflicts with the latest server state.';
          }
          if (statusCode == 404) return 'Resource not found.';
          if (statusCode == 422) {
            return _validationMessage(error.response?.data) ??
                serverMsg ??
                'Invalid input. Please check your details.';
          }
          if (statusCode == 429) {
            return serverMsg ??
                'Too many requests. Please wait before retrying.';
          }
          if (serverMsg != null) return serverMsg;
          if (statusCode != null && statusCode >= 500) {
            return 'Server error. Please try again later.';
          }
          return 'Request failed. Please try again.';
        default:
          return 'Network error. Please try again.';
      }
    }

    if (error is Exception) {
      // 提取 Exception 包装的消息
      final msg = error.toString().replaceFirst('Exception: ', '');
      // 不要暴露技术细节（包含冒号的通常是技术堆栈）
      if (msg.contains('SocketException') || msg.contains('DioException')) {
        return 'Network error. Please try again.';
      }
      return msg;
    }

    return 'An unexpected error occurred.';
  }

  static String? _serverMessage(dynamic data) {
    if (data is! Map) return null;
    final message = data['message'] ?? data['error'];
    return message?.toString();
  }

  static String? _validationMessage(dynamic data) {
    if (data is! Map) return null;
    final errors = data['errors'];
    if (errors is! Map || errors.isEmpty) return null;

    final messages = <String>[];
    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is Iterable) {
        messages.addAll(value.map((item) => item.toString()));
      } else if (value != null) {
        messages.add(value.toString());
      }
      if (messages.length >= 3) break;
    }

    return messages.isEmpty ? null : messages.take(3).join('\n');
  }
}
