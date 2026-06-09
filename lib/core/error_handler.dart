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
          final serverMsg = error.response?.data?['message'];
          if (serverMsg != null) return serverMsg.toString();
          if (statusCode == 401) return 'Session expired. Please login again.';
          if (statusCode == 403) return 'You do not have permission to do this.';
          if (statusCode == 404) return 'Resource not found.';
          if (statusCode == 422) return 'Invalid input. Please check your details.';
          if (statusCode != null && statusCode >= 500) return 'Server error. Please try again later.';
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
}