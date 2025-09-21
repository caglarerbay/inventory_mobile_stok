class DeviceType {
  final int id;
  final String name;

  DeviceType({required this.id, required this.name});

  factory DeviceType.fromJson(Map<String, dynamic> json) {
    return DeviceType(id: json['id'] as int, name: json['name'] as String);
  }
}
