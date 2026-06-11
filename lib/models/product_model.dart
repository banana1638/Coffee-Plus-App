class Product {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final bool isAvailable;

  final Map<String, dynamic>? options;
  final List<ProductAddon>? addons;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.isAvailable,
    this.options,
    this.addons,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['base_price'] ?? json['price'];

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '0') ?? 0.0,

      isAvailable: json['is_available'] == null
          ? true
          : json['is_available'] == 1 ||
                json['is_available'] == true ||
                json['is_available'].toString() == "1",

      options: json['options'],
      addons: json['addons'] != null
          ? (json['addons'] as List)
                .map((addon) => ProductAddon.fromJson(addon))
                .toList()
          : null,
    );
  }
}

class ProductAddon {
  final int id;
  final String name;
  final double price;

  ProductAddon({required this.id, required this.name, required this.price});

  factory ProductAddon.fromJson(Map<String, dynamic> json) {
    return ProductAddon(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'price': price};
  }
}
