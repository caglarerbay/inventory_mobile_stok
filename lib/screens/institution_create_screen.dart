import 'package:flutter/material.dart';
import '../models/institution.dart';
import '../services/institution_service.dart';

class InstitutionCreateScreen extends StatefulWidget {
  @override
  _InstitutionCreateScreenState createState() =>
      _InstitutionCreateScreenState();
}

class _InstitutionCreateScreenState extends State<InstitutionCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _service = InstitutionService();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final inst = Institution(
        name: _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        contactName: _contactNameCtrl.text.trim(),
        contactPhone: _contactPhoneCtrl.text.trim(),
      );
      await _service.createInstitution(inst);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Oluşturma hatası: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yeni Kurum')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _saving
                ? Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(labelText: 'Adı'),
                        validator: (v) => v!.trim().isEmpty ? 'Gerekli' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cityCtrl,
                        decoration: InputDecoration(labelText: 'Şehir'),
                        validator: (v) => v!.trim().isEmpty ? 'Gerekli' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactNameCtrl,
                        decoration: InputDecoration(labelText: 'Kontak Kişi'),
                        validator: (v) => v!.trim().isEmpty ? 'Gerekli' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactPhoneCtrl,
                        decoration: InputDecoration(
                          labelText: 'Kontak Telefon',
                        ),
                        validator: (v) => v!.trim().isEmpty ? 'Gerekli' : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: _save, child: Text('Kaydet')),
                    ],
                  ),
                ),
      ),
    );
  }
}
