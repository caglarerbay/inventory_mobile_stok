class DeviceRecord {
  final int id;
  final String serialNumber;
  final String deviceType;
  final String? institution; // kurum boş olabilir

  DeviceRecord({
    required this.id,
    required this.serialNumber,
    required this.deviceType,
    this.institution,
  });

  factory DeviceRecord.fromJson(Map<String, dynamic> json) {
    return DeviceRecord(
      id: json['id'] as int,
      serialNumber: json['serial_number'] as String,
      deviceType: json['device_type'] as String,
      institution: json['institution'] as String?,
    );
  }
}
