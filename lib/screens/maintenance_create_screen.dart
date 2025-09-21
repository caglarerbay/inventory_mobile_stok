// lib/screens/maintenance_create_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/device_service.dart';
import '../models/maintenance_record.dart';

class MaintenanceCreateScreen extends StatefulWidget {
  final int deviceId;
  const MaintenanceCreateScreen({Key? key, required this.deviceId})
    : super(key: key);

  @override
  _MaintenanceCreateScreenState createState() =>
      _MaintenanceCreateScreenState();
}

class _MaintenanceCreateScreenState extends State<MaintenanceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String _personnel = '';
  String _notes = '';
  bool _isSaving = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final dt = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (dt != null) {
      setState(() => _selectedDate = dt);
    }
  }

  Future<void> _onSave() async {
    // tarih seçilmediyse o anki tarihi ata
    if (_selectedDate == null) {
      _selectedDate = DateTime.now();
    }
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final dateStr = _selectedDate!.toIso8601String().split('T').first;
      await DeviceService().createMaintenanceRecord(
        deviceId: widget.deviceId,
        date: dateStr,
        personnel: _personnel,
        notes: _notes,
        token: token,
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bakım eklenirken hata oluştu')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // klavye varken kaydırır
      appBar: AppBar(title: const Text('Yeni Bakım Ekle')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Tarih seçici
                ListTile(
                  title: Text(
                    _selectedDate == null
                        ? 'Tarih seçin'
                        : 'Tarih: ${_selectedDate!.toIso8601String().split('T').first}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),

                // Müdahale Edenler
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Müdahale Edenler',
                  ),
                  textInputAction: TextInputAction.next,
                  validator:
                      (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
                  onSaved: (v) => _personnel = v!.trim(),
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 16),

                // Notlar
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Notlar'),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  validator:
                      (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
                  onSaved: (v) => _notes = v!.trim(),
                  onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                ),
                const SizedBox(height: 24),

                // Kaydet düğmesi
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _onSave,
                    child:
                        _isSaving
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
