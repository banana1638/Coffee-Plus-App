import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'cart_service.dart';
import 'notification_utils.dart';
import 'profile_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final ApiClient _client = ApiClient();
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  final ProfileService _profileService = ProfileService();

  ApiService._internal();

  String get baseUrl => _client.baseUrl;
  String get baseImageUrl => _client.baseImageUrl;
  Dio get _dio => _client.dio;
  Map<String, dynamic> get _cache => _client.cache;

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
      debugPrint("ApiService.fetchDashboard ERROR: $e");
      if (e is DioException) {
        debugPrint("Dio Error Type: ${e.type}");
        debugPrint("Response Data: ${e.response?.data}");
      }
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

  Future<Map<String, dynamic>> checkoutWithOz(List<int> useOzIds) {
    return _cartService.checkoutWithOz(useOzIds);
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
          .where((notification) => notification['read_at'] == null)
          .length;
      notificationCountNotifier.value = unreadCount;
    } catch (e) {
      // Background count refresh should not interrupt the UI.
    }
  }

  Future<Map<String, dynamic>> fetchNotifications({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'notifications';

    final response = await _dio.get('/profile/notifications');
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = response.data;
      List<dynamic> notifications = List.from(data['notifications'] ?? []);

      if (notifications.isEmpty) {
        _cache[cacheKey] = data;
        return data;
      }

      notifications = NotificationUtils.filterRecentAndPrioritized(
        notifications,
      );

      final filteredData = {...data, 'notifications': notifications};
      _cache[cacheKey] = filteredData;
      return filteredData;
    }
    throw Exception('Fetch Notifications Error');
  }

  Future<void> markNotificationAsRead(String id) async {
    await _dio.post('/profile/notifications/$id/read');
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
    await _dio.post('/profile/notifications/$id/delete');
    updateNotificationCount();
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
