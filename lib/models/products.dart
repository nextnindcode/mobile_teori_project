class Product {
  final int id;
  final String name;
  final String category;
  final String description;
  final int price;
  final int stock;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'] ?? '',
      price: json['price'],
      stock: json['stock'],
      imageUrl: json['image_url'],
    );
  }
}
