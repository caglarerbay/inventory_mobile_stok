// lib/screens/fault_create_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/device_service.dart';

class FaultCreateScreen extends StatefulWidget {
  final int deviceId;
  const FaultCreateScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  _FaultCreateScreenState createState() => _FaultCreateScreenState();
}

class _FaultCreateScreenState extends State<FaultCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _faultDate;
  String _technician = '';
  String _initialNotes = '';
  String? _closingNotes;
  DateTime? _closedDate;
  bool _isSaving = false;

  Future<void> _pickFaultDate() async {
    final now = DateTime.now();
    final dt = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (dt != null) setState(() => _faultDate = dt);
  }

  Future<void> _pickClosedDate() async {
    final now = DateTime.now();
    final dt = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (dt != null) setState(() => _closedDate = dt);
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate() || _faultDate == null) return;
    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      await DeviceService().createFaultRecord(
        deviceId: widget.deviceId,
        faultDate: _faultDate!.toIso8601String().split('T').first,
        technician: _technician,
        initialNotes: _initialNotes,
        closingNotes: _closingNotes,
        closedDate: _closedDate?.toIso8601String().split('T').first,
        token: token,
      );
      Navigator.pop(context, true);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arıza kaydı eklenirken hata oluştu')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Klavye için body’yi yukarı iter
      appBar: AppBar(title: const Text('Yeni Arıza Kaydı')),
      body: GestureDetector(
        onTap:
            () =>
                FocusScope.of(
                  context,
                ).unfocus(), // Dışarı tıklayınca klavye kapanır
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Arıza tarihi
                ListTile(
                  title: Text(
                    _faultDate == null
                        ? 'Arıza tarihi seçin'
                        : 'Arıza Tarihi: ${_faultDate!.toIso8601String().split('T').first}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickFaultDate,
                ),

                const SizedBox(height: 16),

                // Müdahale Eden
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Müdahale Eden'),
                  textInputAction: TextInputAction.next,
                  validator:
                      (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
                  onSaved: (v) => _technician = v!.trim(),
                ),

                const SizedBox(height: 16),

                // Açılış Notu
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Açılış Notu'),
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                  validator:
                      (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
                  onSaved: (v) => _initialNotes = v!.trim(),
                ),

                const SizedBox(height: 16),

                // Kapanış Notu
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Kapanış Notu (opsiyonel)',
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                  onSaved: (v) => _closingNotes = v?.trim(),
                ),

                const SizedBox(height: 16),

                // Kapanış tarihi
                ListTile(
                  title: Text(
                    _closedDate == null
                        ? 'Kapanış tarihi seçin (opsiyonel)'
                        : 'Kapanış Tarihi: ${_closedDate!.toIso8601String().split('T').first}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickClosedDate,
                ),

                const SizedBox(height: 24),

                // Kaydet butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _onSave,
                    child:
                        _isSaving
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
