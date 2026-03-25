import 'product_model.dart';

class FavoriteItem {
  final int? id; // Backend ID
  final Product product;
  final String size;
  final String temp;
  final List<String> addons;
  final String remark;
  final DateTime createdAt;

  FavoriteItem({
    this.id,
    required this.product,
    required this.size,
    required this.temp,
    required this.addons,
    required this.remark,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'image_url': product.imageUrl,
        'base_price': product.price,
        'is_available': product.isAvailable,
        'options': product.options,
        'addons': product.addons?.map((a) => a.toJson()).toList(),
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
      id: json['id'],
      product: Product.fromJson(json['product']),
      size: json['size'] ?? 'Regular',
      temp: json['temp'] ?? 'Hot',
      addons: List<String>.from(json['addons'] ?? []),
      remark: json['remark'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get uniqueId => "${product.id}_${size}_${temp}_${addons.join('_')}";
}
