// lib/models/institution.dart

class Institution {
  final int? id;
  final String name;
  final String city;
  final String contactName;
  final String contactPhone;

  Institution({
    this.id,
    required this.name,
    required this.city,
    required this.contactName,
    required this.contactPhone,
  });

  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
    id: json['id'] as int?,
    name: json['name'] as String,
    city: json['city'] as String,
    contactName: json['contact_name'] as String,
    contactPhone: json['contact_phone'] as String,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'city': city,
    'contact_name': contactName,
    'contact_phone': contactPhone,
  };

  Institution copyWith({
    int? id,
    String? name,
    String? city,
    String? contactName,
    String? contactPhone,
  }) {
    return Institution(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }
}
