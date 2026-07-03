import '../models/product_model.dart';
import 'api_client.dart';
import 'api_response.dart';

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

  ProductService({ApiClientContract? client}) : _client = client ?? ApiClient();

  Future<ProductDetailData> fetchProductDetail(int productId) async {
    final response = await _client.dio.get('/products/$productId');
    if (response.statusCode != 200) {
      throw Exception('Fetch Product Detail Error');
    }
    return ProductDetailData.fromResponse(response.data);
  }
}
