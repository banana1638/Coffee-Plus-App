import 'package:dio/dio.dart';

import 'api_client.dart';

class AuthService {
  final ApiClientContract _client;

  AuthService({ApiClientContract? client}) : _client = client ?? ApiClient();

  Future<String?> getToken() => _client.getToken();

  Future<bool> validateSession() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await _client.dio.get('/profile');
      if (response.statusCode == 200) {
        _client.authStateNotifier.value = true;
        return true;
      }
      return false;
    } catch (e) {
      _client.authStateNotifier.value = false;
      return false;
    }
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    try {
      final response = await _client.dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final String token = response.data['access_token'];
        if (rememberMe) {
          await _client.persistAuthToken(token);
        } else {
          _client.sessionToken = token;
        }
        _client.clearCache();
        _client.authStateNotifier.value = true;
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
      final response = await _client.dio.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _client.persistAuthToken(response.data['access_token']);
        _client.clearCache();
        _client.authStateNotifier.value = true;
        return {'success': true};
      }
      return {'success': false, 'message': 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await getToken();
      if (token != null) await _client.dio.post('/logout');
      return {'success': true};
    } finally {
      await _client.clearAuthState();
    }
  }
}
