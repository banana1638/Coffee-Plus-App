import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app_logger.dart';    // ✅ [新增] 替代 debugPrint
import 'auth_service.dart';
import 'cart_service.dart';
import 'coupon_service.dart';
import 'notification_utils.dart';
import 'order_service.dart';
import 'profile_service.dart';
import 'timed_cache.dart';   // ✅ [新增] 用于 _cache 类型

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final ApiClient _client = ApiClient();
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  final CouponService _couponService = CouponService();
  final OrderService _orderService = OrderService();
  final ProfileService _profileService = ProfileService();

  ApiService._internal();

  String get baseUrl => _client.baseUrl;
  String get baseImageUrl => _client.baseImageUrl;
  Dio get _dio => _client.dio;

  // ✅ [修改] Map<String, dynamic> → TimedCache
  //    原因：与 ApiClient 保持类型一致，解锁 TTL 功能
  TimedCache get _cache => _client.cache;

  ValueNotifier<int> get cartCountNotifier => _client.cartCountNotifier;
  ValueNotifier<int> get notificationCountNotifier =>
      _client.notificationCountNotifier;
  ValueNotifier<bool> get authStateNotifier => _client.authStateNotifier;
  ValueNotifier<ThemeMode> get themeModeNotifier => _client.themeModeNotifier;

  Future<void> loadThemeMode() => _client.loadThemeMode();
  Future<void> setThemeMode(ThemeMode mode) => _client.setThemeMode(mode);
  Future<String?> getToken() => _authService.getToken();

  Future<bool> validateSession() async {
    final isValid = await _authService.validateSession();
    if (isValid) {
      updateCartCount();
      updateNotificationCount();
    }
    return isValid;
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    final result = await _authService.login(
      email,
      password,
      rememberMe: rememberMe,
    );
    if (result['success'] == true) {
      updateCartCount();
      updateNotificationCount();
    }
    return result;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    if (result['success'] == true) {
      updateCartCount();
      updateNotificationCount();
    }
    return result;
  }

  Future<Map<String, dynamic>> logout() => _authService.logout();

  Future<Map<String, dynamic>> fetchDashboard({
    String? search,
    String? category,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    final token = await getToken();
    final cacheKey =
        'dashboard_${token == null ? "guest" : "user"}_${search ?? ""}_${category ?? ""}';

    // ✅ [新增] 实际读取缓存（原代码只写不读，缓存完全失效）
    //    forceRefresh=true 时跳过缓存，强制从服务器获取最新数据
    if (!forceRefresh) {
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        AppLogger.debug('fetchDashboard: cache hit for $cacheKey');
        return Map<String, dynamic>.from(cached as Map);
      }
    }

    try {
      final response = await _dio.get(
        '/dashboard',
        queryParameters: {'search': search, 'category': category}
          ..removeWhere((k, v) => v == null),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        // ✅ [修改] _cache[key] = value  →  _cache.set(key, value, ttl: ...)
        //    Dashboard 数据 2 分钟后过期（比默认 5 分钟短，因为菜单可能更新）
        _cache.set(cacheKey, response.data, ttl: const Duration(minutes: 2));
        return response.data;
      }
      throw Exception("Status ${response.statusCode}");

    } catch (e) {
      // ✅ [修改] debugPrint → AppLogger.error
      //    原因：debugPrint 没有 kDebugMode 检查，在 release 也会输出敏感信息
      AppLogger.error('fetchDashboard failed', error: e);

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

  Future<void> updateCartCount() => _cartService.updateCartCount();
  Future<Map<String, dynamic>> fetchCart() => _cartService.fetchCart();

  Future<void> addToCart({
    required int productId,
    required int quantity,
    required String size,
    required String temp,
    required List<String> addons,
  }) {
    return _cartService.addToCart(
      productId: productId,
      quantity: quantity,
      size: size,
      temp: temp,
      addons: addons,
    );
  }

  Future<Map<String, dynamic>> updateCartItem(int cartItemId, int quantity) {
    return _cartService.updateCartItem(cartItemId, quantity);
  }

  Future<Map<String, dynamic>> removeFromCart(int cartItemId) {
    return _cartService.removeFromCart(cartItemId);
  }

  Future<Map<String, dynamic>> checkoutWithOz(
    List<int> useOzIds, {
    String? couponCode,
  }) {
    return _cartService.checkoutWithOz(useOzIds, couponCode: couponCode);
  }

  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required double subtotal,
  }) {
    return _couponService.validateCoupon(code: code, subtotal: subtotal);
  }

  Future<Map<String, dynamic>> fetchOrders({int page = 1}) {
    return _orderService.fetchOrders(page: page);
  }

  Future<Map<String, dynamic>> fetchOrder(int orderId) {
    return _orderService.fetchOrder(orderId);
  }

  Future<Map<String, dynamic>> cancelOrder(int orderId) {
    return _orderService.cancelOrder(orderId);
  }

  Future<Map<String, dynamic>> fetchTangki() => _profileService.fetchTangki();
  Future<Map<String, dynamic>> refillTangki(double amount) {
    return _profileService.refillTangki(amount);
  }

  Future<Map<String, dynamic>> fetchTransactions({String? type}) {
    return _profileService.fetchTransactions(type: type);
  }

  Future<Map<String, dynamic>> fetchProfile() => _profileService.fetchProfile();

  Future<Map<String, dynamic>> updateProfile({String? name, String? email}) {
    return _profileService.updateProfile(name: name, email: email);
  }

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _profileService.updatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  Future<Map<String, dynamic>> deleteAccount(String password) {
    return _profileService.deleteAccount(password);
  }

  Future<void> updateNotificationCount() async {
    try {
      final token = await getToken();
      if (token == null) {
        notificationCountNotifier.value = 0;
        return;
      }
      final data = await fetchNotifications();
      final notifications = data['notifications'] as List? ?? [];
      final unreadCount = notifications
          .where((n) => n['read_at'] == null)
          .length;
      notificationCountNotifier.value = unreadCount;
    } catch (e) {
      // 后台刷新失败不影响 UI
      AppLogger.warning('updateNotificationCount failed: $e');
    }
  }

  Future<Map<String, dynamic>> fetchNotifications({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'notifications';

    // ✅ [新增] 实际读取缓存（原代码只写不读）
    //    通知数据 1 分钟过期（比 dashboard 更短，因为通知时效性强）
    if (!forceRefresh) {
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        AppLogger.debug('fetchNotifications: cache hit');
        return Map<String, dynamic>.from(cached as Map);
      }
    }

    final response = await _dio.get('/profile/notifications');
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = response.data;
      List<dynamic> notifications = List.from(data['notifications'] ?? []);

      if (notifications.isEmpty) {
        // ✅ [修改] _cache[key] = value  →  _cache.set(key, value, ttl: ...)
        _cache.set(cacheKey, data, ttl: const Duration(minutes: 1));
        return data;
      }

      notifications = NotificationUtils.filterRecentAndPrioritized(
        notifications,
      );

      final filteredData = {...data, 'notifications': notifications};
      // ✅ [修改] _cache[key] = filteredData  →  _cache.set(key, filteredData, ttl: ...)
      _cache.set(cacheKey, filteredData, ttl: const Duration(minutes: 1));
      return filteredData;
    }
    throw Exception('Fetch Notifications Error');
  }

  Future<void> markNotificationAsRead(String id) async {
    await _dio.post('/profile/notifications/$id/read');
    // ✅ TimedCache.removeWhere() 签名与原 Map.removeWhere() 相同，无需修改
    _cache.removeWhere((key, value) => key.contains('notifications'));
    updateNotificationCount();
  }

  Future<void> deleteReadNotifications() async {
    await _dio.post('/profile/notifications/delete-read');
    _cache.removeWhere((key, value) => key.contains('notifications'));
    updateNotificationCount();
  }

  Future<void> deleteNotifications(List<String> ids) async {
    final response = await _dio.post(
      '/profile/notifications/batch-delete',
      data: {'ids': ids},
    );
    if (response.statusCode == 200) {
      _cache.removeWhere((key, value) => key.contains('notifications'));
      await updateNotificationCount();
    }
  }

  Future<void> deleteNotification(String id) async {
    await deleteNotifications([id]);
  }

  Future<List<Map<String, dynamic>>> fetchFavorites() async {
    final response = await _dio.get('/favorites');
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    throw Exception('Fetch Favorites Error');
  }

  Future<Map<String, dynamic>> addFavorite({
    required int productId,
    required String size,
    required String temp,
    required List<String> addons,
    String? remark,
  }) async {
    final response = await _dio.post(
      '/favorites',
      data: {
        'product_id': productId,
        'size': size,
        'temp': temp,
        'addons': addons,
        'remark': remark,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data;
    }
    throw Exception('Add Favorite Error');
  }

  Future<void> removeFavorite(int favoriteId) async {
    await _dio.delete('/favorites/$favoriteId');
  }

  void clearCache({String? pattern}) => _client.clearCache(pattern: pattern);

  String getFullImageUrl(dynamic relativePath) {
    return _client.getFullImageUrl(relativePath);
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
