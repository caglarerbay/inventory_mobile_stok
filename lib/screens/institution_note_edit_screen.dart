import 'package:flutter/material.dart';
import '../models/institution_note.dart';
import '../services/institution_service.dart';

class InstitutionNoteEditScreen extends StatefulWidget {
  final int institutionId;
  final InstitutionNote? note;

  const InstitutionNoteEditScreen({
    Key? key,
    required this.institutionId,
    this.note,
  }) : super(key: key);

  @override
  _InstitutionNoteEditScreenState createState() =>
      _InstitutionNoteEditScreenState();
}

class _InstitutionNoteEditScreenState extends State<InstitutionNoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();
  final _service = InstitutionService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _textCtrl.text = widget.note!.text;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (widget.note == null) {
        await _service.addNote(widget.institutionId, _textCtrl.text.trim());
      } else {
        final updated = widget.note!.copyWith(text: _textCtrl.text.trim());
        await _service.updateNote(updated);
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kayıt hatası: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Notu Düzenle' : 'Yeni Not')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _textCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Not metni',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Not boş olamaz' : null,
              ),
              const SizedBox(height: 20),
              _saving
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _save,
                    child: Text(isEditing ? 'Güncelle' : 'Kaydet'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
