import 'product_model.dart';

class Category {
  final int id;
  final String name;
  final List<Product> products;
  final int productCount;

  Category({
    required this.id,
    required this.name,
    required this.products,
    required this.productCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final dynamic productListData = json['products'];
    List<Product> products = [];
    if (productListData is Iterable) {
      products = productListData.map((i) => Product.fromJson(i)).toList();
    }

    return Category(
      id: json['category_id'] ?? 0,
      name: json['category_name'] ?? '',
      products: products,
      productCount: json['product_count'] ?? 0,
    );
  }
}
