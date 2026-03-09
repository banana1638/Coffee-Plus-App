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

  // 获取仪表盘数据
  Future<Map<String, dynamic>> fetchDashboard({
    String? search,
    String? category,
  }) async {
    try {
      final response = await _dio.get(
        '/dashboard',
        queryParameters: {'search': search, 'category': category}
          ..removeWhere((key, value) => value == null),
      );
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

  // 获取储水箱数据
  Future<Map<String, dynamic>> fetchTangki() async {
    try {
      final response = await _dio.get('/tangki');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Tangki Loading Error');
      }
    } catch (e) {
      debugPrint("Tangki Error: $e");
      rethrow;
    }
  }

  // 充值储水箱
  Future<Map<String, dynamic>> refillTangki(double amount) async {
    try {
      final response = await _dio.post(
        '/tangki/refill',
        data: {'amount': amount},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Refill Error');
      }
    } catch (e) {
      debugPrint("Refill Error: $e");
      rethrow;
    }
  }

  // 获取个人资料
  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final response = await _dio.get('/profile');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Profile Loading Error');
      }
    } catch (e) {
      debugPrint("Profile Error: $e");
      rethrow;
    }
  }

  // 更新个人资料
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      final response = await _dio.post(
        '/profile/update',
        data: {'name': name, 'email': email}
          ..removeWhere((_, value) => value == null),
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Update Error');
      }
    } catch (e) {
      debugPrint("Profile Update Error: $e");
      rethrow;
    }
  }

  // 注销账号
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      final response = await _dio.post(
        '/profile/delete',
        data: {'password': password},
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Delete Error');
      }
    } catch (e) {
      debugPrint("Account Delete Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchCart() async {
    try {
      final response = await _dio.get('/cart');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Cart Loading Error');
      }
    } catch (e) {
      debugPrint("Cart Fetch Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addToCart({
    required int productId,
    required int quantity,
    required Map<String, dynamic> options,
  }) async {
    try {
      final response = await _dio.post(
        '/cart/add',
        data: {
          'product_id': productId,
          'quantity': quantity,
          'options': options,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Add to Cart Error');
      }
    } catch (e) {
      debugPrint("Cart Add Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCartItem(
    int productId,
    int quantity,
  ) async {
    try {
      final response = await _dio.post(
        '/cart/update',
        data: {'product_id': productId, 'quantity': quantity},
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Update Cart Error');
      }
    } catch (e) {
      debugPrint("Cart Update Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> removeFromCart(int productId) async {
    try {
      final response = await _dio.post(
        '/cart/remove',
        data: {'product_id': productId},
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Remove From Cart Error');
      }
    } catch (e) {
      debugPrint("Cart Remove Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkout() async {
    try {
      final response = await _dio.post('/checkout');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Checkout Error');
      }
    } catch (e) {
      debugPrint("Checkout Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkoutWithOz(List<int> useOzIds) async {
    try {
      final response = await _dio.post('/checkout', data: {'use_oz': useOzIds});
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Checkout Error');
      }
    } catch (e) {
      debugPrint("Checkout Error: $e");
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
