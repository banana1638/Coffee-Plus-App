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

  // 状态监听器
  final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

  // 内存缓存
  final Map<String, dynamic> _cache = {};

  // ==========================================
  // 0. 初始化与拦截器 (Initialization)
  // ==========================================

  ApiService._internal() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await _storage.delete(key: 'auth_token');
            _sessionToken = null;
            authStateNotifier.value = false;
            cartCountNotifier.value = 0;
          }
          return handler.next(e);
        },
      ),
    );

    // 调试模式日志
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('DEBUG_DIO: $obj'),
        ),
      );
    }
  }

  // ==========================================
  // 1. 身份验证与会话 (Auth & Session)
  // ==========================================

  Future<String?> getToken() async {
    if (_sessionToken != null) return _sessionToken;
    return await _storage.read(key: 'auth_token');
  }

  Future<bool> validateSession() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await _dio.get('/profile');
      if (response.statusCode == 200) {
        updateCartCount();
        authStateNotifier.value = true;
        return true;
      }
      return false;
    } catch (e) {
      authStateNotifier.value = false;
      return false;
    }
  }

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
          _sessionToken = token;
        }
        clearCache(); // 登录后清除旧缓存
        authStateNotifier.value = true;
        return {'success': true};
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Invalid credentials',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
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
      if ((response.statusCode == 200 || response.statusCode == 201)) {
        await _storage.write(
          key: 'auth_token',
          value: response.data['access_token'],
        );
        clearCache();
        authStateNotifier.value = true;
        return {'success': true};
      }
      return {'success': false, 'message': 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      String? token = await getToken();
      if (token != null) await _dio.post('/logout');
      return {'success': true};
    } finally {
      _sessionToken = null;
      await _storage.delete(key: 'auth_token');
      clearCache();
      cartCountNotifier.value = 0;
      authStateNotifier.value = false;
    }
  }

  // ==========================================
  // 2. 核心业务：仪表盘与结账 (Core Business)
  // ==========================================

  Future<Map<String, dynamic>> fetchDashboard({
    String? search,
    String? category,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    final token = await getToken();
    final cacheKey =
        'dashboard_${token == null ? "guest" : "user"}_${search ?? ""}_${category ?? ""}';

    if (!forceRefresh && _cache.containsKey(cacheKey)) return _cache[cacheKey];

    try {
      final response = await _dio.get(
        '/dashboard',
        queryParameters: {'search': search, 'category': category}
          ..removeWhere((k, v) => v == null),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        _cache[cacheKey] = response.data;
        return response.data;
      }
      throw Exception("Status ${response.statusCode}");
    } catch (e) {
      if (token == null) {
        return {
          'menus': [],
          'allCategoryNames': [],
          'user': {'name': 'GUEST', 'oz': 0, 'balance': 0.0},
        };
      }
      rethrow;
    }
  }

  /// 合并后的结账函数：支持普通结账和使用 Oz 抵扣
  Future<Map<String, dynamic>> checkout({List<int>? useOzIds}) async {
    try {
      final Map<String, dynamic>? data =
          (useOzIds != null && useOzIds.isNotEmpty)
          ? {'use_oz': useOzIds}
          : null;

      final response = await _dio.post('/checkout', data: data);

      if (response.statusCode == 200) {
        clearCache(); // 关键：结账后资产状态改变，必须清理首页缓存
        updateCartCount();
        return response.data;
      }
      throw Exception(response.data['message'] ?? 'Checkout Error');
    } catch (e) {
      debugPrint("Checkout API Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkoutWithOz(List<int> useOzIds) async {
    try {
      // 构造请求体，后端通常期望的格式是 use_oz[]: [1, 2, 3]
      final response = await _dio.post('/checkout', data: {'use_oz': useOzIds});

      // 成功后，由于余额和购物车都变了，强制清除缓存
      _cache.remove('/dashboard');
      _cache.remove('/cart');
      _cache.remove('/profile');

      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? "Checkout failed";
    }
  }

  // ==========================================
  // 3. 购物车逻辑 (Cart Logic)
  // ==========================================

  Future<void> updateCartCount() async {
    try {
      final token = await getToken();
      if (token == null) {
        cartCountNotifier.value = 0;
        return;
      }
      final cartData = await fetchCart();
      cartCountNotifier.value = (cartData['cartItems'] as List).length;
    } catch (e) {
      debugPrint("Cart Count Sync Error: $e");
    }
  }

  Future<Map<String, dynamic>> fetchCart() async {
    final response = await _dio.get('/cart');
    if (response.statusCode == 200) return response.data;
    throw Exception('Fetch Cart Error');
  }

  Future<void> addToCart({
    required int productId,
    required int quantity,
    required String size,
    required String temp,
    required List<String> addons,
  }) async {
    await _dio.post(
      '/cart/add',
      data: {
        'product_id': productId,
        'quantity': quantity,
        'size': size,
        'temp': temp,
        'addons': addons,
      },
    );
    updateCartCount();
  }

  Future<Map<String, dynamic>> updateCartItem(
    int productId,
    int quantity,
  ) async {
    final response = await _dio.post(
      '/cart/update',
      data: {'product_id': productId, 'quantity': quantity},
    );
    if (response.statusCode == 200) return response.data;
    throw Exception('Update Cart Error');
  }

  Future<Map<String, dynamic>> removeFromCart(int productId) async {
    final response = await _dio.post(
      '/cart/remove',
      data: {'product_id': productId},
    );
    if (response.statusCode == 200) {
      updateCartCount();
      return response.data;
    }
    throw Exception('Remove Error');
  }

  // ==========================================
  // 4. 用户资产与资料 (User Assets & Profile)
  // ==========================================

  Future<Map<String, dynamic>> fetchTangki() async {
    final response = await _dio.get('/tangki');
    if (response.statusCode == 200) return response.data;
    throw Exception('Tangki Error');
  }

  Future<Map<String, dynamic>> refillTangki(double amount) async {
    final response = await _dio.post(
      '/tangki/refill',
      data: {'amount': amount},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      clearCache(pattern: 'dashboard'); // 清理缓存，确保首页余额更新
      return response.data;
    }
    throw Exception('Refill Error');
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _dio.get('/profile');
    if (response.statusCode == 200) return response.data;
    throw Exception('Profile Error');
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
  }) async {
    final response = await _dio.post(
      '/profile/update',
      data: {'name': name, 'email': email}..removeWhere((_, v) => v == null),
    );
    if (response.statusCode == 200) {
      clearCache(pattern: 'dashboard');
      return response.data;
    }
    throw Exception('Update Error');
  }

  Future<Map<String, dynamic>> deleteAccount(String password) async {
    final response = await _dio.post(
      '/profile/delete',
      data: {'password': password},
    );
    return response.data;
  }

  // ==========================================
  // 5. 工具方法 (Utilities)
  // ==========================================

  /// 清理缓存。pattern 为空则清理全部，传入字符串则清理包含该 Key 的缓存。
  void clearCache({String? pattern}) {
    if (pattern == null) {
      _cache.clear();
      debugPrint("API Cache: All cleared");
    } else {
      _cache.removeWhere((key, value) => key.contains(pattern));
      debugPrint("API Cache: Cleared pattern '$pattern'");
    }
  }

  String getFullImageUrl(dynamic relativePath) {
    if (relativePath == null || relativePath.toString().isEmpty) return "";
    String path = relativePath.toString().trim().replaceAll('\\', '/');
    if (path.contains('/')) path = path.split('/').last;
    return "$baseImageUrl$path";
  }

  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get('/dashboard');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
