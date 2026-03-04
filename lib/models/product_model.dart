class Product {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final bool isAvailable;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.isAvailable,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      price: (json['base_price'] ?? 0).toDouble(),
      isAvailable: json['is_available'] ?? true,
    );
  }
}
