// lib/models/product.dart

class Product {
  final int id;
  final String partCode;
  final String name;
  final int quantity;
  final int minLimit;
  bool orderPlaced;

  Product({
    required this.id,
    required this.partCode,
    required this.name,
    required this.quantity,
    required this.minLimit,
    required this.orderPlaced,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    partCode: json['part_code'] as String,
    name: json['name'] as String,
    quantity: json['quantity'] as int,
    minLimit: json['min_limit'] as int,
    orderPlaced: json['order_placed'] as bool,
  );
}
