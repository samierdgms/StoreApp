class Product {
  final String id;
  final String name;
  final String imageUrl;
  final String unit;
  final double price;
  final bool inStock;
  final String category;
  final String description;
  final bool hasDiscount; // Yeni özellik

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.unit,
    required this.price,
    required this.inStock,
    required this.category,
    required this.description,
    required this.hasDiscount,  // Yeni özellik
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'],
      imageUrl: json['image_url'],
      unit: json['unit'].toString(),
      price: double.parse(json['price'].toString()),
      inStock: json['in_stock'] == true,
      category: json['category'],
      description: json['description'] ?? '',
      hasDiscount: json['has_discount'] ?? false,
    );
  }
}
