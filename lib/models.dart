class Product {
  final int id; // Now strictly an int to match your database
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final int stockQuantity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stockQuantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      // Safely handle ID whether it comes as int or string
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['product_name'] ?? 'Unknown Product',
      description: json['description'] ?? '',
      price: (json['selling_price'] is int)
          ? (json['selling_price'] as int).toDouble()
          : (json['selling_price']?.toDouble() ?? 0.0),
      imageUrl: json['image_urls'] ?? '',
      category: json['category'] ?? 'General',
      stockQuantity: json['current_stock'] ?? 0,
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}