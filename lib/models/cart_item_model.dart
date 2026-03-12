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
    int parseId = json['id'] is int
        ? json['id']
        : int.tryParse(json['id']?.toString() ?? '') ?? 0;

    int parseQuantity = json['quantity'] is int
        ? json['quantity']
        : int.tryParse(json['quantity']?.toString() ?? '') ?? 1;

    Product parsedProduct = Product.fromJson(json['product'] ?? {});

    return CartItem(
      id: parseId,
      product: parsedProduct,
      quantity: parseQuantity,
      size: json['size']?.toString() ?? '',
      temp: json['temp']?.toString() ?? '',
      addons: List<String>.from(json['addons'] ?? []),
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '') ?? 0.0,
      totalItemPrice:
          double.tryParse(json['total_item_price']?.toString() ?? '') ?? 0.0,
    );
  }

  int get ozNeeded => (totalItemPrice * 100).toInt();
}
