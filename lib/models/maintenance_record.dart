class MaintenanceRecord {
  final int id;
  final String date; // “2025-05-10” gibi ISO tarih
  final String personnel; // “Ahmet, Mehmet”
  final String notes; // bakım notu

  MaintenanceRecord({
    required this.id,
    required this.date,
    required this.personnel,
    required this.notes,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as int,
      date: json['date'] as String,
      personnel: json['personnel'] as String,
      notes: json['notes'] as String,
    );
  }
}
