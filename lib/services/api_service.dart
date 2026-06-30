import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/device_token_model.dart';
import 'api_client.dart';
import 'api_response.dart';
import 'app_config.dart';
import 'app_logger.dart';
import 'auth_service.dart';
import 'cart_service.dart';
import 'coupon_service.dart';
import 'notification_utils.dart';
import 'order_service.dart';
import 'payment_service.dart';
import 'profile_service.dart';
import 'timed_cache.dart';
import 'token_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final ApiClient _client = ApiClient();
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  final CouponService _couponService = CouponService();
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();
  final ProfileService _profileService = ProfileService();
  final TokenService _tokenService = TokenService();
  final _dashboardRequests = <String, Future<Map<String, dynamic>>>{};
  int _dashboardRefreshGeneration = 0;
  Future<Map<String, dynamic>>? _notificationsRequest;
  Future<void>? _notificationCountUpdate;
  int _notificationRefreshGeneration = 0;

  ApiService._internal();

  String get baseUrl => _client.baseUrl;
  String get baseImageUrl => _client.baseImageUrl;
  Dio get _dio => _client.dio;

  TimedCache<Map<String, dynamic>> get _cache => _client.cache;

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
      _clearInFlightRequests();
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
      _clearInFlightRequests();
      updateCartCount();
      updateNotificationCount();
    }
    return result;
  }

  Future<Map<String, dynamic>> logout() async {
    final result = await _authService.logout();
    _clearInFlightRequests();
    return result;
  }

  Future<Map<String, dynamic>> fetchDashboard({
    String? search,
    String? category,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    final token = await getToken();
    final cacheKey =
        'dashboard_${token == null ? "guest" : "user"}_${search ?? ""}_${category ?? ""}';

    if (forceRefresh) {
      _dashboardRefreshGeneration++;
      _dashboardRequests.remove(cacheKey);
    }

    // ✅ [新增] 实际读取缓存（原代码只写不读，缓存完全失效）
    //    forceRefresh=true 时跳过缓存，强制从服务器获取最新数据
    if (!forceRefresh) {
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        AppLogger.debug('fetchDashboard: cache hit for $cacheKey');
        return Map<String, dynamic>.from(cached);
      }

      final pending = _dashboardRequests[cacheKey];
      if (pending != null) {
        AppLogger.debug('fetchDashboard: join in-flight request for $cacheKey');
        return pending;
      }
    }

    final generation = _dashboardRefreshGeneration;
    final Future<Map<String, dynamic>> request = (() async {
      try {
        final response = await _dio.get(
          '/dashboard',
          queryParameters: {'search': search, 'category': category}
            ..removeWhere((k, v) => v == null),
          cancelToken: cancelToken,
        );

        if (response.statusCode == 200) {
          _logDashboardPayload(response.data);
          // ✅ [修改] _cache[key] = value  →  _cache.set(key, value, ttl: ...)
          //    Dashboard 数据 2 分钟后过期（比默认 5 分钟短，因为菜单可能更新）
          if (generation == _dashboardRefreshGeneration) {
            _cache.set(
              cacheKey,
              response.data,
              ttl: const Duration(minutes: 2),
            );
          }
          return requireJsonMap(response.data);
        }
        throw Exception("Status ${response.statusCode}");
      } catch (e) {
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
    })();

    if (!forceRefresh) {
      late Future<Map<String, dynamic>> trackedRequest;
      trackedRequest = request.whenComplete(() {
        if (identical(_dashboardRequests[cacheKey], trackedRequest)) {
          _dashboardRequests.remove(cacheKey);
        }
      });
      _dashboardRequests[cacheKey] = trackedRequest;
      return trackedRequest;
    }

    return request;
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
    String? idempotencyKey,
  }) {
    return _cartService.checkoutWithOz(
      useOzIds,
      couponCode: couponCode,
      idempotencyKey: idempotencyKey,
    );
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

  Future<PaymentStatusSnapshot> fetchPaymentStatus(String sessionId) {
    return _paymentService.fetchPaymentStatus(sessionId);
  }

  Future<PaymentStatusSnapshot> pollPaymentStatus(
    String sessionId, {
    bool Function()? shouldContinue,
  }) {
    return _paymentService.pollUntilProcessed(
      sessionId,
      shouldContinue: shouldContinue,
    );
  }

  String? extractPaymentSessionId(
    Map<String, dynamic> result,
    String redirectUrl,
  ) {
    return PaymentService.extractSessionId(result, redirectUrl);
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

  Future<List<DeviceToken>> fetchDeviceTokens() {
    return _tokenService.fetchTokens();
  }

  Future<bool> revokeDeviceToken(DeviceToken token) async {
    final revokedCurrent = await _tokenService.revokeToken(token.id);
    final shouldClearLocalCredentials = revokedCurrent || token.isCurrent;
    if (shouldClearLocalCredentials) {
      await _tokenService.clearLocalCredentials();
      _clearInFlightRequests();
    }
    return shouldClearLocalCredentials;
  }

  Future<void> revokeAllDeviceTokens() async {
    await _tokenService.revokeAllTokens();
    await _tokenService.clearLocalCredentials();
    _clearInFlightRequests();
  }

  Future<void> updateNotificationCount({bool forceRefresh = false}) {
    if (forceRefresh) {
      _notificationRefreshGeneration++;
      _notificationCountUpdate = null;
      _notificationsRequest = null;
    }

    if (!forceRefresh && _notificationCountUpdate != null) {
      return _notificationCountUpdate!;
    }

    final request = _updateNotificationCount(forceRefresh: forceRefresh);
    if (!forceRefresh) {
      late Future<void> trackedRequest;
      trackedRequest = request.whenComplete(() {
        if (identical(_notificationCountUpdate, trackedRequest)) {
          _notificationCountUpdate = null;
        }
      });
      _notificationCountUpdate = trackedRequest;
      return trackedRequest;
    }
    return request;
  }

  Future<void> _updateNotificationCount({bool forceRefresh = false}) async {
    final generation = _notificationRefreshGeneration;
    try {
      final token = await getToken();
      if (token == null) {
        if (generation == _notificationRefreshGeneration) {
          notificationCountNotifier.value = 0;
        }
        return;
      }
      final data = await fetchNotifications(forceRefresh: forceRefresh);
      final notifications = data['notifications'] as List? ?? [];
      final unreadCount = notifications
          .where((n) => n['read_at'] == null)
          .length;
      if (generation == _notificationRefreshGeneration) {
        notificationCountNotifier.value = unreadCount;
      }
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
        return Map<String, dynamic>.from(cached);
      }
    }

    if (!forceRefresh && _notificationsRequest != null) {
      return _notificationsRequest!;
    }

    final request = _fetchNotificationsFromServer(cacheKey);
    if (!forceRefresh) {
      late Future<Map<String, dynamic>> trackedRequest;
      trackedRequest = request.whenComplete(() {
        if (identical(_notificationsRequest, trackedRequest)) {
          _notificationsRequest = null;
        }
      });
      _notificationsRequest = trackedRequest;
      return trackedRequest;
    }
    return request;
  }

  Future<Map<String, dynamic>> _fetchNotificationsFromServer(
    String cacheKey,
  ) async {
    final response = await _dio.get('/profile/notifications');
    if (response.statusCode != 200) {
      throw Exception('Fetch Notifications Error');
    }

    final data = requireJsonMap(response.data);
    List<dynamic> notifications = List.from(data['notifications'] ?? []);

    if (notifications.isEmpty) {
      // ✅ [修改] _cache[key] = value  →  _cache.set(key, value, ttl: ...)
      _cache.set(cacheKey, data, ttl: const Duration(minutes: 1));
      return data;
    }

    notifications = NotificationUtils.filterRecentAndPrioritized(notifications);

    final filteredData = {...data, 'notifications': notifications};
    // ✅ [修改] _cache[key] = filteredData  →  _cache.set(key, filteredData, ttl: ...)
    _cache.set(cacheKey, filteredData, ttl: const Duration(minutes: 1));
    return filteredData;
  }

  Future<void> markNotificationAsRead(String id) async {
    await _dio.post('/profile/notifications/$id/read');
    // ✅ TimedCache.removeWhere() 签名与原 Map.removeWhere() 相同，无需修改
    _cache.removeWhere((key, value) => key.contains('notifications'));
    _notificationsRequest = null;
    updateNotificationCount(forceRefresh: true);
  }

  Future<void> deleteReadNotifications() async {
    await _dio.post('/profile/notifications/delete-read');
    _cache.removeWhere((key, value) => key.contains('notifications'));
    _notificationsRequest = null;
    updateNotificationCount(forceRefresh: true);
  }

  Future<void> deleteNotifications(List<String> ids) async {
    final response = await _dio.post(
      '/profile/notifications/batch-delete',
      data: {'ids': ids},
    );
    if (response.statusCode == 200) {
      _cache.removeWhere((key, value) => key.contains('notifications'));
      _notificationsRequest = null;
      await updateNotificationCount(forceRefresh: true);
    }
  }

  Future<void> deleteNotification(String id) async {
    await deleteNotifications([id]);
  }

  Future<List<Map<String, dynamic>>> fetchFavorites() async {
    final response = await _dio.get('/favorites');
    if (response.statusCode == 200) {
      final data = response.data;
      final favorites = data is Map ? data['data'] : data;
      return (favorites as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
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
      return unwrapDataMap(response.data);
    }
    throw Exception('Add Favorite Error');
  }

  Future<void> removeFavorite(int favoriteId) async {
    await _dio.delete('/favorites/$favoriteId');
  }

  void _clearInFlightRequests() {
    _dashboardRefreshGeneration++;
    _notificationRefreshGeneration++;
    _dashboardRequests.clear();
    _notificationsRequest = null;
    _notificationCountUpdate = null;
  }

  void clearCache({String? pattern}) {
    _client.clearCache(pattern: pattern);
    if (pattern == null) {
      _clearInFlightRequests();
    } else {
      if ('dashboard'.contains(pattern) || pattern.contains('dashboard')) {
        _dashboardRefreshGeneration++;
        _dashboardRequests.removeWhere((key, _) => key.contains('dashboard'));
      }
      if ('notifications'.contains(pattern) ||
          pattern.contains('notifications')) {
        _notificationsRequest = null;
        _notificationCountUpdate = null;
      }
    }
  }

  String getFullImageUrl(dynamic relativePath) {
    return _client.getFullImageUrl(relativePath);
  }

  void _logDashboardPayload(dynamic data) {
    if (!AppConfig.verboseApiLogs) return;
    if (data is! Map) {
      AppLogger.debug('dashboard payload type=${data.runtimeType}');
      return;
    }

    final menus = data['menus'];
    final categoryCount = menus is Iterable ? menus.length : 0;
    var productCount = 0;
    Map<dynamic, dynamic>? firstProduct;

    if (menus is Iterable) {
      for (final menu in menus) {
        if (menu is! Map) continue;
        final products = menu['products'];
        if (products is Iterable) {
          productCount += products.length;
          if (firstProduct == null && products.isNotEmpty) {
            final first = products.first;
            if (first is Map) firstProduct = first;
          }
        }
      }
    }

    AppLogger.debug(
      'dashboard payload keys=${data.keys.take(12).join(',')} '
      'categories=$categoryCount products=$productCount',
    );

    if (firstProduct != null) {
      AppLogger.debug(
        'dashboard firstProduct keys=${firstProduct.keys.take(16).join(',')} '
        'id=${firstProduct['id']} name=${firstProduct['name']} '
        'image_url=${firstProduct['image_url']} '
        'thumbnail=${firstProduct['thumbnail_image_url']} '
        'detail=${firstProduct['detail_image_url']}',
      );
    }
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
