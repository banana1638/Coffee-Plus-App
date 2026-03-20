import 'product_model.dart';

class FavoriteItem {
  final Product product;
  final String size;
  final String temp;
  final List<String> addons;
  final String remark;
  final DateTime createdAt;

  FavoriteItem({
    required this.product,
    required this.size,
    required this.temp,
    required this.addons,
    required this.remark,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'product': {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'image_url': product.imageUrl,
        'base_price': product.price,
        'is_available': product.isAvailable,
        'options': product.options,
      },
      'size': size,
      'temp': temp,
      'addons': addons,
      'remark': remark,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      product: Product.fromJson(json['product']),
      size: json['size'] ?? 'Regular',
      temp: json['temp'] ?? 'Hot',
      addons: List<String>.from(json['addons'] ?? []),
      remark: json['remark'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Create a unique ID for this specific combination
  String get uniqueId => "${product.id}_${size}_${temp}_${addons.join('_')}";
}
