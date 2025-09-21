import 'package:flutter/material.dart';
import '../models/institution.dart';
import '../services/institution_service.dart';

class InstitutionEditScreen extends StatefulWidget {
  final int institutionId;

  const InstitutionEditScreen({Key? key, required this.institutionId})
    : super(key: key);

  @override
  _InstitutionEditScreenState createState() => _InstitutionEditScreenState();
}

class _InstitutionEditScreenState extends State<InstitutionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _service = InstitutionService();
  bool _loading = true, _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInstitution();
  }

  Future<void> _loadInstitution() async {
    try {
      final inst = await _service.getById(widget.institutionId);
      _nameCtrl.text = inst.name;
      _cityCtrl.text = inst.city;
      _contactNameCtrl.text = inst.contactName;
      _contactPhoneCtrl.text = inst.contactPhone;
      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = 'Veri alınırken hata oluştu');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = Institution(
        id: widget.institutionId,
        name: _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        contactName: _contactNameCtrl.text.trim(),
        contactPhone: _contactPhoneCtrl.text.trim(),
      );
      await _service.update(updated);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Güncellerken hata: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kurum Düzenle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _loading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                  child: Text(_error!, style: TextStyle(color: Colors.red)),
                )
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
                      _saving
                          ? Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                            onPressed: _save,
                            child: Text('Kaydet'),
                          ),
                    ],
                  ),
                ),
      ),
    );
  }
}
