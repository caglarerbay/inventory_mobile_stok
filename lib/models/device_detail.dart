class DeviceDetail {
  final int id;
  final String serialNumber;
  final String deviceType;
  final String? institution;
  final String? connectedCore;
  final String? installDate;
  final String? uninstallDate;
  final int? installationId;
  final bool coreRequired; // ← işte bu

  DeviceDetail({
    required this.id,
    required this.serialNumber,
    required this.deviceType,
    this.institution,
    this.connectedCore,
    this.installDate,
    this.uninstallDate,
    this.installationId,
    required this.coreRequired,
  });

  factory DeviceDetail.fromJson(Map<String, dynamic> json) {
    return DeviceDetail(
      id: json['id'] as int,
      serialNumber: json['serial_number'] as String,
      deviceType: json['device_type'] as String,
      institution: json['institution'] as String?,
      connectedCore: json['connected_core'] as String?,
      installDate: json['install_date'] as String?,
      uninstallDate: json['uninstall_date'] as String?,
      installationId: json['installation_id'] as int?,
      coreRequired: (json['core_required'] as bool?) ?? false,
    );
  }
}
