import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_config.dart';
import 'timed_cache.dart';

abstract class ApiClientContract {
  String get baseUrl;
  String get baseImageUrl;
  Dio get dio;
  ValueNotifier<int> get cartCountNotifier;
  ValueNotifier<int> get notificationCountNotifier;
  ValueNotifier<bool> get authStateNotifier;
  ValueNotifier<ThemeMode> get themeModeNotifier;
  TimedCache get cache;

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

  @override
  String get baseUrl => AppConfig.apiBaseUrl;

  @override
  String get baseImageUrl => AppConfig.productImageBaseUrl;

  @override
  final Dio dio = Dio();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);
  @override
  final ValueNotifier<int> notificationCountNotifier = ValueNotifier<int>(0);
  @override
  final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);
  @override
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  @override
  final TimedCache cache = TimedCache(
    maxSize: 50,
    defaultTtl: const Duration(minutes: 5),
  );

  @override
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

  @override
  Future<String?> getToken() async {
    if (sessionToken != null) return sessionToken;
    return storage.read(key: 'auth_token');
  }

  @override
  Future<void> persistAuthToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
    sessionToken = null;
  }

  @override
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

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    await storage.write(key: 'theme_mode', value: mode.name);
  }

  @override
  void clearCache({String? pattern}) {
    if (pattern == null) {
      cache.clear();
    } else {
      cache.removeWhere((key, value) => key.contains(pattern));
    }
  }

  @override
  Future<void> clearAuthState() async {
    sessionToken = null;
    await storage.delete(key: 'auth_token');
    clearCache();
    cartCountNotifier.value = 0;
    notificationCountNotifier.value = 0;
    authStateNotifier.value = false;
  }

  @override
  String getFullImageUrl(dynamic relativePath) {
    if (relativePath == null || relativePath.toString().isEmpty) return "";
    String path = relativePath.toString().trim().replaceAll('\\', '/');
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) return path;
    if (path.startsWith('/storage/')) return '${AppConfig.storageOrigin}$path';
    if (path.startsWith('storage/')) return '${AppConfig.storageOrigin}/$path';
    if (path.contains('/')) path = path.split('/').last;
    return "$baseImageUrl$path";
  }
}
