import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ApiClientContract {
  String get baseUrl;
  String get baseImageUrl;
  Dio get dio;
  ValueNotifier<int> get cartCountNotifier;
  ValueNotifier<int> get notificationCountNotifier;
  ValueNotifier<bool> get authStateNotifier;
  ValueNotifier<ThemeMode> get themeModeNotifier;
  Map<String, dynamic> get cache;
  String? get sessionToken;
  set sessionToken(String? value);

  Future<String?> getToken();
  Future<void> persistAuthToken(String token);
  Future<void> loadThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
  void clearCache({String? pattern});
  Future<void> clearAuthState();
  String getFullImageUrl(dynamic relativePath);
}

class ApiClient implements ApiClientContract {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final String baseUrl = "http://192.168.1.103/coffee_plus/public/api";
  final String baseImageUrl =
      "http://192.168.1.103/coffee_plus/public/images/products/";

  final Dio dio = Dio();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> notificationCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  final Map<String, dynamic> cache = {};
  String? sessionToken;

  ApiClient._internal() {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          options.headers['Accept-Language'] = 'en';
          options.headers['Accept'] = 'application/json';
          options.headers['Content-Type'] = 'application/json';

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await clearAuthState();
          }
          return handler.next(e);
        },
      ),
    );

    loadThemeMode();
  }

  Future<String?> getToken() async {
    if (sessionToken != null) return sessionToken;
    return storage.read(key: 'auth_token');
  }

  Future<void> persistAuthToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
    sessionToken = null;
  }

  Future<void> loadThemeMode() async {
    final String? mode = await storage.read(key: 'theme_mode');
    if (mode == 'light') {
      themeModeNotifier.value = ThemeMode.light;
    } else if (mode == 'dark') {
      themeModeNotifier.value = ThemeMode.dark;
    } else {
      themeModeNotifier.value = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    await storage.write(key: 'theme_mode', value: mode.name);
  }

  void clearCache({String? pattern}) {
    if (pattern == null) {
      cache.clear();
    } else {
      cache.removeWhere((key, value) => key.contains(pattern));
    }
  }

  Future<void> clearAuthState() async {
    sessionToken = null;
    await storage.delete(key: 'auth_token');
    clearCache();
    cartCountNotifier.value = 0;
    notificationCountNotifier.value = 0;
    authStateNotifier.value = false;
  }

  String getFullImageUrl(dynamic relativePath) {
    if (relativePath == null || relativePath.toString().isEmpty) return "";
    String path = relativePath.toString().trim().replaceAll('\\', '/');
    if (path.contains('/')) path = path.split('/').last;
    return "$baseImageUrl$path";
  }
}
