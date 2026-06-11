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
        final dynamic rawToken = response.data['access_token'];
        if (rawToken == null || rawToken.toString().isEmpty) {
          return {'success': false, 'message': 'Token not provided'};
        }
        final String token = rawToken.toString();
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
    } on DioException catch (e){ 
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {'success': false, 'message': 'Connection timed out'};
      }
      final serverMsg = e.response?.data['message'];
      return {'success': false, 'message': serverMsg ?? 'Login failed'};
    }catch (e) {
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
        final dynamic rawToken = response.data['access_token'];
        if (rawToken == null || rawToken.toString().isEmpty){
          return {'success': false, 'message': 'Registration error: no token'};
        }
        await _client.persistAuthToken(rawToken.toString());
        _client.clearCache();
        _client.authStateNotifier.value = true;
        return {'success': true};
      }
      return {'success': false, 'message': 'Registration failed'};
      } on DioException catch (e) {
        if (e.response?.statusCode == 422) {
          final errors = e.response?.data?['errors'];
          if (errors is Map) {
            final firstError = errors.values.first;
            return {'success': false, 'message': firstError is List ? firstError.first : firstError.toString(),};
          }
        }
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
