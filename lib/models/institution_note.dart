// lib/models/institution_note.dart

class InstitutionNote {
  final int id;
  final String text;
  final String noteDate;
  final String createdBy;

  InstitutionNote({
    required this.id,
    required this.text,
    required this.noteDate,
    required this.createdBy,
  });

  factory InstitutionNote.fromJson(Map<String, dynamic> json) {
    return InstitutionNote(
      id: json['id'] as int,
      text: json['text'] as String,
      noteDate: json['note_date'] as String,
      createdBy: json['created_by'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'text': text};

  /// Yeni bir kopya oluşturmak için kullanılır,
  /// örn. düzenleme formunda önceki verilerinizi korumak için.
  InstitutionNote copyWith({
    int? id,
    String? text,
    String? noteDate,
    String? createdBy,
  }) {
    return InstitutionNote(
      id: id ?? this.id,
      text: text ?? this.text,
      noteDate: noteDate ?? this.noteDate,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
