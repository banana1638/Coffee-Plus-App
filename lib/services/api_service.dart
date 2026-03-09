import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final String baseUrl = "http://192.168.1.104/coffee_plus/public/api";
  final String baseImageUrl =
      "http://192.168.1.104/coffee_plus/public/images/products/";
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  String? _sessionToken;

  Future<String?> getToken() async {
    if (_sessionToken != null) return _sessionToken;
    return await _storage.read(key: 'auth_token');
  }

  // Observable cart count
  final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);

  // Observable auth state
  final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

  // Simple In-memory cache
  final Map<String, dynamic> _cache = {};

  Future<void> _updateCartCountInternal() async {
    try {
      final token = await getToken();
      if (token == null) {
        cartCountNotifier.value = 0;
        return;
      }
      final cartData = await fetchCart();
      cartCountNotifier.value = (cartData['cartItems'] as List).length;
    } catch (e) {
      debugPrint("Error updating cart count: $e");
    }
  }

  Future<void> updateCartCount() async {
    await _updateCartCountInternal();
  }

  Future<bool> validateSession() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await _dio.get('/profile');
      if (response.statusCode == 200) {
        updateCartCount(); // Proactively refresh cart
        authStateNotifier.value = true;
        return true;
      }
      authStateNotifier.value = false;
      return false;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        await _storage.delete(key: 'auth_token');
      }
      authStateNotifier.value = false;
      return false;
    }
  }

  String getFullImageUrl(dynamic relativePath) {
    if (relativePath == null || relativePath.toString().isEmpty) return "";

    // 1. 去除两端可能存在的空格
    String path = relativePath.toString().trim();

    // 2. 将 Windows 反斜杠替换为标准斜杠
    path = path.replaceAll('\\', '/');

    // 如果数据库存的是完整路径 "images/products/coffee.jpg"，而 baseImageUrl 已经包含此路径
    // 可能会导致重复。确保这里只获取最后的文件名。
    if (path.contains('/')) {
      path = path.split('/').last;
    }

    return "$baseImageUrl$path";
  }

  ApiService._internal() {
    debugPrint("Initializing ApiService singleton with baseUrl: $baseUrl");
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Disable logging in release mode for performance
    if (!kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
        ),
      );
    } else {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint('DEBUG_DIO: $obj'),
        ),
      );
    }

    // 添加拦截器来自动附加 Token 和进行基础调试
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token = await _storage.read(key: 'auth_token');
          debugPrint(
            ">>> API REQUEST: [${options.method}] ${options.baseUrl}${options.path}",
          );
          debugPrint(">>> HEADERS: ${options.headers}");
          if (options.data != null) debugPrint(">>> DATA: ${options.data}");

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            "<<< API RESPONSE: [${response.statusCode}] ${response.realUri}",
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint("!!! API ERROR: ${e.type}");
          debugPrint("!!! MESSAGE: ${e.message}");
          debugPrint("!!! URI: ${e.requestOptions.uri}");
          if (e.response != null) {
            debugPrint("!!! STATUS CODE: ${e.response?.statusCode}");
            debugPrint("!!! ERROR DATA: ${e.response?.data}");
          }
          return handler.next(e);
        },
      ),
    );
  }

  // 获取仪表盘数据 (With Cache and Cancellation)
  Future<Map<String, dynamic>> fetchDashboard({
    String? search,
    String? category,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'dashboard_${search ?? ""}_${category ?? ""}';

    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      debugPrint("Serving Dashboard from cache: $cacheKey");
      return _cache[cacheKey];
    }

    try {
      final response = await _dio.get(
        '/dashboard',
        queryParameters: {'search': search, 'category': category}
          ..removeWhere((key, value) => value == null),
        cancelToken: cancelToken,
      );
      if (response.statusCode == 200) {
        _cache[cacheKey] = response.data;
        return response.data;
      } else {
        throw Exception(
          'Dashboard Error (${response.statusCode}): ${response.data}',
        );
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint("Dashboard request cancelled");
      } else {
        debugPrint("Dashboard Error: $e");
      }
      rethrow;
    }
  }

  void clearCache() => _cache.clear();

  // 获取储水箱数据
  Future<Map<String, dynamic>> fetchTangki() async {
    try {
      final response = await _dio.get('/tangki');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Tangki Error (${response.statusCode}): ${response.data}',
        );
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
        throw Exception(
          'Refill Error (${response.statusCode}): ${response.data}',
        );
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
        throw Exception(
          'Profile Error (${response.statusCode}): ${response.data}',
        );
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
        throw Exception(
          'Profile Update Error (${response.statusCode}): ${response.data}',
        );
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
        throw Exception(
          'Cart Error (${response.statusCode}): ${response.data}',
        );
      }
    } catch (e) {
      debugPrint("Cart Fetch Error: $e");
      rethrow;
    }
  }

  Future<void> addToCart({
    required int productId,
    required int quantity,
    required String size,
    required String temp,
    required List<String> addons,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');

      final response = await _dio.post(
        '/cart/add',
        data: {
          'product_id': productId,
          'quantity': quantity,
          'size': size,
          'temp': temp,
          'addons': addons,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      debugPrint("Add to Cart Success: ${response.data}");
      updateCartCount(); // 刷新购物车计数
    } on DioException catch (e) {
      String errorMessage = "Failed to add to cart";

      if (e.response != null) {
        // 捕获 422 验证错误
        if (e.response?.statusCode == 422) {
          final data = e.response?.data;
          if (data is Map && data['errors'] != null) {
            // 提取具体的错误信息，例如 {"errors": {"size": ["The size field is required"]}}
            Map<String, dynamic> validationErrors = data['errors'];
            errorMessage = validationErrors.values.first[0].toString();
          } else if (data['message'] != null) {
            errorMessage = data['message'];
          }
        } else {
          errorMessage = "Server error: ${e.response?.statusCode}";
        }

        // 在开发阶段打印出来，极其重要！
        debugPrint("Detailed Error Response: ${e.response?.data}");
      } else {
        errorMessage = "Network error: ${e.message}";
      }

      throw Exception(errorMessage);
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
        updateCartCount();
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
        updateCartCount();
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
        updateCartCount();
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
  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        String token = response.data['access_token'];
        if (rememberMe) {
          await _storage.write(key: 'auth_token', value: token);
        } else {
          // Keep in memory for this session only
          _sessionToken = token;
        }

        // Notify auth changed (force value change even if already true)
        authStateNotifier.value = false;
        authStateNotifier.value = true;

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

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['status'] == 'success') {
        String token = response.data['access_token'];
        await _storage.write(key: 'auth_token', value: token);

        authStateNotifier.value = false;
        authStateNotifier.value = true;

        return {'success': true};
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Registration failed',
      };
    } catch (e) {
      debugPrint("Register Error: $e");
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        String message = 'Registration failed';
        if (data is Map) {
          if (data.containsKey('errors')) {
            // Get first validation error
            var errors = data['errors'] as Map;
            message = errors.values.first[0].toString();
          } else if (data.containsKey('message')) {
            message = data['message'];
          }
        }
        return {'success': false, 'message': message};
      }
      return {'success': false, 'message': 'Network error during registration'};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      String? token = await getToken();
      if (token != null) {
        await _dio.post('/logout');
      }
      return {'success': true};
    } finally {
      _sessionToken = null;
      await _storage.delete(key: 'auth_token');
      cartCountNotifier.value = 0;
      authStateNotifier.value = false;
    }
  }

  // 新增：检查连接方法
  Future<bool> checkConnection() async {
    try {
      debugPrint("Checking connection to $baseUrl...");
      // 尝试访问一个简单的端点或直接 baseUrl
      final response = await _dio.get('/dashboard');
      debugPrint("Connection check success: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Connection check failed: $e");
      return false;
    }
  }
}
