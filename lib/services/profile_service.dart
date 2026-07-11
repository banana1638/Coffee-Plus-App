import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_response.dart';
import 'timed_cache.dart';

class ProfileService {
  final ApiClientContract _client;
  final TimedCache<Map<String, dynamic>> _transactionDetailCache = TimedCache(
    maxSize: 30,
    defaultTtl: const Duration(minutes: 10),
  );

  ProfileService({ApiClientContract? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> fetchTangki() async {
    final response = await _client.dio.get('/tangki');
    if (response.statusCode == 200) return response.data;
    throw Exception('Tangki Error');
  }

  Future<Map<String, dynamic>> refillTangki(double amount) async {
    final response = await _client.dio.post(
      '/tangki/refill',
      data: {'amount': amount},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      _client.clearCache(pattern: 'dashboard');
      return response.data;
    }
    throw Exception('Refill Error');
  }

  Future<Map<String, dynamic>> fetchTransactions({String? type}) async {
    final Map<String, dynamic> queryParams = {};
    if (type != null && type != 'all') {
      queryParams['type'] = type;
    }

    final response = await _client.dio.get(
      '/transactions',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) return response.data;
    throw Exception('Transactions Error');
  }

  Future<Map<String, dynamic>> fetchRefunds() async {
    final response = await _client.dio.get('/refunds');

    if (response.statusCode == 200) return requireJsonMap(response.data);
    throw Exception('Refunds Error');
  }

  Future<Map<String, dynamic>> fetchTransactionDetail(String billId) async {
    final trimmedBillId = billId.trim();
    final cached = _transactionDetailCache.get(trimmedBillId);
    if (cached != null) return cached;

    final encodedBillId = Uri.encodeComponent(trimmedBillId);
    final response = await _client.dio.get('/transactions/$encodedBillId');

    if (response.statusCode == 200) {
      final data = requireJsonMap(response.data);
      final order = data['order'];
      if (order is Map) {
        final normalized = Map<String, dynamic>.from(order);
        _transactionDetailCache.set(trimmedBillId, normalized);
        return normalized;
      }

      throw const FormatException('Transaction detail response missing order.');
    }

    throw Exception('Transaction Detail Error');
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _client.dio.get('/profile');
    if (response.statusCode == 200) return response.data;
    throw Exception('Profile Error');
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
  }) async {
    final response = await _client.dio.post(
      '/profile/update',
      data: {'name': name, 'email': email}..removeWhere((_, v) => v == null),
    );
    if (response.statusCode == 200) {
      _client.clearCache(pattern: 'dashboard');
      return response.data;
    }
    throw Exception('Update Error');
  }

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _client.dio.post(
        '/profile/password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      final data = requireJsonMap(response.data);
      final token = _extractAccessToken(data);
      if (token != null) {
        await _client.persistAuthToken(token);
      }
      return data;
    } on DioException {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      final response = await _client.dio.post(
        '/profile/delete',
        data: {'password': password},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        await _client.clearAuthState();
      }

      return response.data ?? {};
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ??
          e.response?.data['error'] ??
          "Account deletion failed";
      throw Exception(message);
    }
  }

  String? _extractAccessToken(Map<String, dynamic> data) {
    final directToken = data['access_token'];
    if (directToken is String && directToken.trim().isNotEmpty) {
      return directToken.trim();
    }

    final nestedData = data['data'];
    if (nestedData is Map) {
      final nestedToken = nestedData['access_token'];
      if (nestedToken is String && nestedToken.trim().isNotEmpty) {
        return nestedToken.trim();
      }
    }

    return null;
  }

  void clearTransactionDetailCache() {
    _transactionDetailCache.clear();
  }
}
