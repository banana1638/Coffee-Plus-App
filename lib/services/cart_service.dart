import 'dart:math';

import 'package:dio/dio.dart';

import 'api_client.dart';

class CartService {
  final ApiClientContract _client;
  Future<void>? _countUpdate;
  int _countRefreshGeneration = 0;

  CartService({ApiClientContract? client}) : _client = client ?? ApiClient();

  Future<void> updateCartCount({bool forceRefresh = false}) {
    if (forceRefresh) {
      _countRefreshGeneration++;
      _countUpdate = null;
    }

    if (!forceRefresh && _countUpdate != null) return _countUpdate!;

    final request = _updateCartCount();
    late Future<void> trackedRequest;
    trackedRequest = request.whenComplete(() {
      if (identical(_countUpdate, trackedRequest)) {
        _countUpdate = null;
      }
    });
    _countUpdate = trackedRequest;
    return trackedRequest;
  }

  Future<void> _updateCartCount() async {
    final generation = _countRefreshGeneration;
    try {
      final token = await _client.getToken();
      if (token == null) {
        if (generation == _countRefreshGeneration) {
          _client.cartCountNotifier.value = 0;
        }
        return;
      }
      final cartData = await fetchCart();
      if (generation == _countRefreshGeneration) {
        _client.cartCountNotifier.value =
            (cartData['cartItems'] as List? ?? []).length;
      }
    } catch (e) {
      // Background count refresh should not interrupt the UI.
    }
  }

  Future<Map<String, dynamic>> fetchCart() async {
    final response = await _client.dio.get('/cart');
    if (response.statusCode == 200) return _responseData(response.data);
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
    await updateCartCount(forceRefresh: true);
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
      updateCartCount(forceRefresh: true);
      return response.data;
    }
    throw Exception('Remove Error');
  }

  Future<Map<String, dynamic>> checkoutWithOz(
    List<int> useOzIds, {
    String? couponCode,
  }) async {
    try {
      final response = await _client.dio.post(
        '/checkout',
        options: Options(headers: {'Idempotency-Key': _idempotencyKey()}),
        data: {
          'use_oz': useOzIds,
          if (couponCode != null && couponCode.trim().isNotEmpty)
            'coupon_code': couponCode.trim(),
        },
      );
      _client.clearCache();
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? "Checkout failed");
    }
  }

  String _idempotencyKey() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    final nonce = values.map(
      (value) => value.toRadixString(16).padLeft(2, '0'),
    );
    return 'checkout-${DateTime.now().microsecondsSinceEpoch}-${nonce.join()}';
  }

  Map<String, dynamic> _responseData(dynamic responseData) {
    final data = Map<String, dynamic>.from(responseData as Map);
    return Map<String, dynamic>.from((data['data'] as Map?) ?? data);
  }
}
