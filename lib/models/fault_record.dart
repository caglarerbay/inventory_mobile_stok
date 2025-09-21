// lib/models/fault_record.dart

class FaultRecord {
  final int id;
  final int deviceId; // ← Yeni eklenen alan
  final String faultDate; // arıza tarihi
  final String technician; // müdahale eden kişi
  final String initialNotes; // açılış notu
  final String? closingNotes; // kapanış notu nullable
  final String? closedDate; // kapanış tarihi nullable

  FaultRecord({
    required this.id,
    required this.deviceId, // ← constructor’a ekledik
    required this.faultDate,
    required this.technician,
    required this.initialNotes,
    this.closingNotes,
    this.closedDate,
  });

  factory FaultRecord.fromJson(Map<String, dynamic> json) {
    return FaultRecord(
      id: json['id'] as int,
      deviceId: json['device_id'] as int, // ← JSON’dan oku
      faultDate: json['fault_date'] as String,
      technician: json['technician'] as String,
      initialNotes: json['initial_notes'] as String,
      closingNotes: json['closing_notes'] as String?,
      closedDate: json['closed_date'] as String?,
    );
  }
}
