import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // 真机调试使用: 你的电脑局域网 IP (例如 192.168.1.104)
  // 注意：通过 IP 访问通常需要指向项目的 public 目录
  final String baseUrl = "http://192.168.1.104/coffee_plus/public/api";
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);

    // 添加拦截器来自动附加 Token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Token 过期处理逻辑可以放在这里
            debugPrint("Unauthorized: Token might be expired.");
          }
          return handler.next(e);
        },
      ),
    );
  }

  // 获取首页数据
  Future<Map<String, dynamic>> fetchDashboard() async {
    try {
      final response = await _dio.get('/dashboard');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Loading Error');
      }
    } catch (e) {
      debugPrint("Dashboard Error: $e");
      rethrow;
    }
  }

  // 修改后的登录方法，提供详细错误反馈
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        String token = response.data['access_token'];
        await _storage.write(key: 'auth_token', value: token);
        return {'success': true};
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Invalid credentials',
      };
    } catch (e) {
      debugPrint("Login Error: $e");
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        String message = 'Login failed (${e.response?.statusCode})';
        if (data is Map && data.containsKey('message')) {
          message = data['message'];
        } else if (data is String && data.isNotEmpty) {
          // 如果返回的是纯文本或 HTML，截取一部分
          message = data.length > 100 ? data.substring(0, 100) : data;
        }
        return {'success': false, 'message': message};
      }
      return {
        'success': false,
        'message': 'Network error: Please check your IP or Wi-Fi',
      };
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } finally {
      await _storage.delete(key: 'auth_token');
    }
  }
}
