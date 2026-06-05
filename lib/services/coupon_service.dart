import 'api_client.dart';

class CouponService {
  final ApiClientContract _client;

  CouponService({ApiClientContract? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required double subtotal,
  }) async {
    final response = await _client.dio.get(
      '/coupons/validate',
      queryParameters: {
        'code': code.trim(),
        'subtotal': subtotal.toStringAsFixed(2),
      },
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    }

    throw Exception('Coupon validation failed');
  }
}
