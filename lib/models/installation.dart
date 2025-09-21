class Installation {
  final int id;
  final int deviceId;
  final String deviceSerial;
  final String deviceType;
  final String institutionName;
  final int institutionId;
  final int? connectedCoreId; // ID olarak tutuyoruz
  final String? connectedCoreSerial; // Seri numarası
  final String installDate;
  final String? uninstallDate;

  Installation({
    required this.id,
    required this.deviceId,
    required this.deviceSerial,
    required this.deviceType,
    required this.institutionName,
    required this.institutionId,
    this.connectedCoreId,
    this.connectedCoreSerial,
    required this.installDate,
    this.uninstallDate,
  });

  factory Installation.fromJson(Map<String, dynamic> json) {
    return Installation(
      id: json['id'] as int,
      deviceId: json['device_id'] as int,
      deviceSerial: json['device_serial'] as String,
      deviceType: json['device_type'] as String,
      institutionName: json['institution'] as String,
      institutionId: json['institution_id'] as int,
      connectedCoreId: json['connected_core_id'] as int?,
      connectedCoreSerial: json['connected_core_serial'] as String?,
      installDate: json['install_date'] as String,
      uninstallDate: json['uninstall_date'] as String?,
    );
  }
}
