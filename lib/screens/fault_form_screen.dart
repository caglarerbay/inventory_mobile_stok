// lib/screens/fault_form_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fault_record.dart';
import '../services/device_service.dart';

class FaultFormScreen extends StatefulWidget {
  final int deviceId;
  final FaultRecord? fault;

  /// Eğer fault==null ise yeni kayıt, değilse güncelleme (kapatma)
  const FaultFormScreen({Key? key, required this.deviceId, this.fault})
    : super(key: key);

  @override
  _FaultFormScreenState createState() => _FaultFormScreenState();
}

class _FaultFormScreenState extends State<FaultFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _faultDate;
  DateTime? _closedDate;
  String _technician = '';
  String _initialNotes = '';
  String? _closingNotes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.fault != null) {
      final f = widget.fault!;
      _faultDate = DateTime.parse(f.faultDate);
      _closedDate = f.closedDate != null ? DateTime.parse(f.closedDate!) : null;
      _technician = f.technician;
      _initialNotes = f.initialNotes;
      _closingNotes = f.closingNotes;
    }
  }

  Future<void> _pickDate(bool isFault) async {
    final now = DateTime.now();
    final dt = await showDatePicker(
      context: context,
      initialDate: isFault ? (_faultDate ?? now) : (_closedDate ?? now),
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (dt != null) {
      setState(() {
        if (isFault)
          _faultDate = dt;
        else
          _closedDate = dt;
      });
    }
  }

  Future<void> _onSave() async {
    // Açılış tarihi seçilmezse şimdi ata
    if (_faultDate == null) _faultDate = DateTime.now();
    // Kapatma modunda ve kapanış tarihi seçilmezse şimdi ata
    if (widget.fault != null && _closedDate == null) {
      _closedDate = DateTime.now();
    }

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final faultDateStr = _faultDate!.toIso8601String().split('T').first;
      final closedDateStr = _closedDate?.toIso8601String().split('T').first;

      if (widget.fault == null) {
        // Yeni kayıt
        await DeviceService().createFaultRecord(
          deviceId: widget.deviceId,
          faultDate: faultDateStr,
          technician: _technician,
          initialNotes: _initialNotes,
          closingNotes: _closingNotes,
          closedDate: closedDateStr,
          token: token,
        );
      } else {
        // Var olan kaydı kapatma
        await DeviceService().updateFaultRecord(
          id: widget.fault!.id,
          closingNotes: _closingNotes,
          closedDate: closedDateStr,
          token: token,
        );
      }
      Navigator.pop(context, true);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kaydetme hatası')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.fault != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Arıza Kapat' : 'Yeni Arıza Kaydı')),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Müdahale Tarihi
                ListTile(
                  title: Text(
                    _faultDate == null
                        ? 'Müdahale tarihi seçin'
                        : 'Tarih: ${_faultDate!.toIso8601String().split('T').first}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDate(true),
                ),
                const SizedBox(height: 8),

                // Teknisyen
                TextFormField(
                  initialValue: _technician,
                  decoration: const InputDecoration(labelText: 'Müdahale Eden'),
                  textInputAction: TextInputAction.next,
                  validator:
                      (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
                  onSaved: (v) => _technician = v!.trim(),
                  enabled: !isEdit,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 8),

                // Açılış Notu
                TextFormField(
                  initialValue: _initialNotes,
                  decoration: const InputDecoration(labelText: 'Açılış Notu'),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                  validator:
                      (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
                  onSaved: (v) => _initialNotes = v!.trim(),
                  enabled: !isEdit,
                ),
                const SizedBox(height: 16),

                // Kapanış Notu
                TextFormField(
                  initialValue: _closingNotes,
                  decoration: const InputDecoration(
                    labelText: 'Kapanış Notu (opsiyonel)',
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                  onSaved: (v) => _closingNotes = v?.trim(),
                ),
                const SizedBox(height: 16),

                // Kapanış Tarihi
                ListTile(
                  title: Text(
                    _closedDate == null
                        ? 'Kapanış tarihi seçin (opsiyonel)'
                        : 'Kapanış: ${_closedDate!.toIso8601String().split('T').first}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDate(false),
                ),
                const SizedBox(height: 24),

                // Kaydet / Kapat
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
                            : Text(isEdit ? 'Kapat' : 'Kaydet'),
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
