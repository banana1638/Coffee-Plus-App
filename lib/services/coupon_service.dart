import 'api_client.dart';

class CouponService {
  final ApiClientContract _client;

  CouponService({ApiClientContract? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required double subtotal,
  })async {
    try {
      final response = await _client.dio.post(
        '/coupon/validate',
        data: {
          'code': code.trim().toUpperCase(),
          'subtotal': subtotal.toStringAsFixed(2),
        },
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return Map<String, dynamic>.from(data);
      }
      throw Exception('Coupon valudation failed');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw Exception(e.response?.data?['message'] ?? 'Invalid coupon code');
      }
      rethrow;
    }
 }
}