import '../models/product_model.dart';
import 'api_client.dart';
import 'api_response.dart';
import 'timed_cache.dart';

class ProductDetailData {
  final Product product;
  final Map<String, dynamic> options;

  const ProductDetailData({required this.product, required this.options});

  factory ProductDetailData.fromResponse(dynamic responseData) {
    final response = requireJsonMap(responseData);
    final rawProduct = response['product'];
    if (rawProduct is! Map) {
      throw const FormatException('Product detail response is missing product');
    }

    final rawOptions = response['options'];
    return ProductDetailData(
      product: Product.fromJson(Map<String, dynamic>.from(rawProduct)),
      options: rawOptions is Map
          ? Map<String, dynamic>.from(rawOptions)
          : const {},
    );
  }
}

class ProductService {
  final ApiClientContract _client;
  final TimedCache<ProductDetailData> _detailCache = TimedCache(
    maxSize: 24,
    defaultTtl: const Duration(minutes: 5),
  );
  final Map<int, Future<ProductDetailData>> _detailRequests = {};

  ProductService({ApiClientContract? client}) : _client = client ?? ApiClient();

  Future<ProductDetailData> fetchProductDetail(int productId) async {
    final cached = _detailCache.get(productId.toString());
    if (cached != null) return cached;

    final pending = _detailRequests[productId];
    if (pending != null) return pending;

    final request = () async {
      final response = await _client.dio.get('/products/$productId');
      if (response.statusCode != 200) {
        throw Exception('Fetch Product Detail Error');
      }
      final detail = ProductDetailData.fromResponse(response.data);
      _detailCache.set(productId.toString(), detail);
      return detail;
    }();

    late Future<ProductDetailData> trackedRequest;
    trackedRequest = request.whenComplete(() {
      if (identical(_detailRequests[productId], trackedRequest)) {
        _detailRequests.remove(productId);
      }
    });

    _detailRequests[productId] = trackedRequest;
    return trackedRequest;
  }

  void clearCache() {
    _detailCache.clear();
    _detailRequests.clear();
  }
}
