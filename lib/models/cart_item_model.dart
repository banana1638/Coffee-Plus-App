import 'product_model.dart';

class CartItem {
  final int id;
  final Product product;
  final int quantity;
  final String size;
  final String temp;
  final List<String> addons;
  final double unitPrice;
  final double totalItemPrice;

  // UI ONLY state
  bool isOz;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.size,
    required this.temp,
    required this.addons,
    required this.unitPrice,
    required this.totalItemPrice,
    this.isOz = false,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      product: Product.fromJson(json['product'] ?? {}),
      quantity: json['quantity'] ?? 0,
      size: json['size'] ?? '',
      temp: json['temp'] ?? '',
      addons: List<String>.from(json['addons'] ?? []),
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalItemPrice: (json['total_item_price'] ?? 0).toDouble(),
    );
  }

  int get ozNeeded => (totalItemPrice * 100).toInt();
}
