import 'package:dio/dio.dart';

import 'api_client.dart';

class CartService {
  final ApiClientContract _client;

  CartService({ApiClientContract? client}) : _client = client ?? ApiClient();

  Future<void> updateCartCount() async {
    try {
      final token = await _client.getToken();
      if (token == null) {
        _client.cartCountNotifier.value = 0;
        return;
      }
      final cartData = await fetchCart();
      _client.cartCountNotifier.value = (cartData['cartItems'] as List).length;
    } catch (e) {
      // Background count refresh should not interrupt the UI.
    }
  }

  Future<Map<String, dynamic>> fetchCart() async {
    final response = await _client.dio.get('/cart');
    if (response.statusCode == 200) return response.data;
    throw Exception('Fetch Cart Error');
  }

  Future<void> addToCart({
    required int productId,
    required int quantity,
    required String size,
    required String temp,
    required List<String> addons,
  }) async {
    await _client.dio.post(
      '/cart/add',
      data: {
        'product_id': productId,
        'quantity': quantity,
        'size': size,
        'temp': temp,
        'addons': addons,
      },
    );
    updateCartCount();
  }

  Future<Map<String, dynamic>> updateCartItem(
    int cartItemId,
    int quantity,
  ) async {
    final response = await _client.dio.post(
      '/cart/update',
      data: {'cart_item_id': cartItemId, 'quantity': quantity},
    );
    if (response.statusCode == 200) return response.data;
    throw Exception('Update Cart Error');
  }

  Future<Map<String, dynamic>> removeFromCart(int cartItemId) async {
    final response = await _client.dio.post(
      '/cart/remove',
      data: {'cart_item_id': cartItemId},
    );
    if (response.statusCode == 200) {
      updateCartCount();
      return response.data;
    }
    throw Exception('Remove Error');
  }

  Future<Map<String, dynamic>> checkoutWithOz(List<int> useOzIds) async {
    try {
      final response = await _client.dio.post(
        '/checkout',
        data: {'use_oz': useOzIds},
      );
      _client.clearCache();
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? "Checkout failed";
    }
  }
}
