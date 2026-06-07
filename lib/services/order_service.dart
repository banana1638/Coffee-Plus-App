import 'api_client.dart';

class OrderService {
  final ApiClientContract _client;

  OrderService({ApiClientContract? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> fetchOrders({int page = 1}) async {
    final response = await _client.dio.get(
      '/orders',
      queryParameters: {'page': page},
    );

    if (response.statusCode == 200) return response.data;
    throw Exception('Fetch Orders Error');
  }

  Future<Map<String, dynamic>> fetchOrder(int orderId) async {
    final response = await _client.dio.get('/orders/$orderId');

    if (response.statusCode == 200) return response.data;
    throw Exception('Fetch Order Error');
  }

  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    final response = await _client.dio.post('/orders/$orderId/cancel');

    if (response.statusCode == 200) return response.data;
    throw Exception('Cancel Order Error');
  }
}
