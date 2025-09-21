// lib/models/stock_movement.dart

class StockMovement {
  final int id;
  final String transactionType;
  final ProductInfo product;
  final int quantity;
  final String user; // kullanıcı adı
  final DateTime timestamp;
  final String description;
  final int currentQuantity; // ana stokta işlem sonrası miktar
  final int? currentUserQuantity; // kullanıcı stokunda işlem sonrası miktar
  final int? currentReceiverQuantity;

  StockMovement({
    required this.id,
    required this.transactionType,
    required this.product,
    required this.quantity,
    required this.user,
    required this.timestamp,
    required this.description,
    required this.currentQuantity,
    this.currentUserQuantity,
    this.currentReceiverQuantity,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'],
      transactionType: json['transaction_type'],
      product: ProductInfo.fromJson(json['product']),
      quantity: json['quantity'],
      user: json['user'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'] ?? '',
      currentQuantity: json['current_quantity'] ?? 0,
      currentUserQuantity: json['current_user_quantity'],
      currentReceiverQuantity: json['current_receiver_quantity'],
    );
  }
}

class ProductInfo {
  final int id;
  final String partCode;
  final String name;
  final int quantity; // ana stok son miktar
  final int minLimit;
  final bool orderPlaced;
  final String? cabinet;
  final String? shelf;

  ProductInfo({
    required this.id,
    required this.partCode,
    required this.name,
    required this.quantity,
    required this.minLimit,
    required this.orderPlaced,
    this.cabinet,
    this.shelf,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'],
      partCode: json['part_code'],
      name: json['name'],
      quantity: json['quantity'],
      minLimit: json['min_limit'],
      orderPlaced: json['order_placed'],
      cabinet: json['cabinet'],
      shelf: json['shelf'],
    );
  }
}
