class DevicePartUsage {
  final int id;
  final int device;
  final String deviceSerial;
  final int product;
  final String productCode;
  final String productName;
  final int quantity;
  final String userUsername;
  final DateTime usedAt;

  DevicePartUsage({
    required this.id,
    required this.device,
    required this.deviceSerial,
    required this.product,
    required this.productCode,
    required this.productName,
    required this.quantity,
    required this.userUsername,
    required this.usedAt,
  });

  factory DevicePartUsage.fromJson(Map<String, dynamic> json) {
    return DevicePartUsage(
      id: json['id'],
      device: json['device'],
      deviceSerial: json['device_serial'] ?? '',
      product: json['product'],
      productCode: json['product_code'] ?? '',
      productName: json['product_name'] ?? '',
      quantity: json['quantity'],
      userUsername: json['user_username'] ?? '',
      usedAt: DateTime.parse(json['used_at']),
    );
  }
}
