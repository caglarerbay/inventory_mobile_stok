import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_type.dart';
import '../services/device_service.dart';

class DeviceCreateScreen extends StatefulWidget {
  @override
  _DeviceCreateScreenState createState() => _DeviceCreateScreenState();
}

class _DeviceCreateScreenState extends State<DeviceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _token;

  // Form alanları
  int? _selectedDeviceTypeId;
  String _serialNumber = '';

  // Yüklenen cihaz tipleri
  List<DeviceType> _deviceTypes = [];
  bool _loadingTypes = true;
  String? _loadError;

  // Kaydetme durumu
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTokenAndTypes();
  }

  Future<void> _loadTokenAndTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    setState(() => _token = token);

    try {
      final types = await DeviceService().getDeviceTypes(token);
      setState(() {
        _deviceTypes = types;
        _loadingTypes = false;
      });
    } catch (e) {
      setState(() {
        _loadingTypes = false;
        _loadError = 'Cihaz tipleri yüklenemedi';
      });
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await DeviceService().createDevice(
        deviceTypeId: _selectedDeviceTypeId!,
        serialNumber: _serialNumber,
        token: token,
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cihaz eklenirken hata oluştu')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yeni Cihaz Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _loadingTypes
                ? Center(child: CircularProgressIndicator())
                : _loadError != null
                ? Center(
                  child: Text(_loadError!, style: TextStyle(color: Colors.red)),
                )
                : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Cihaz Tipi',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _deviceTypes.map((t) {
                              return DropdownMenuItem<int>(
                                value: t.id,
                                child: Text(t.name),
                              );
                            }).toList(),
                        validator:
                            (v) => v == null ? 'Lütfen cihaz tipi seçin' : null,
                        onChanged:
                            (v) => setState(() => _selectedDeviceTypeId = v),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Seri Numarası',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Seri numarası boş olamaz'
                                    : null,
                        onSaved: (v) => _serialNumber = v!.trim(),
                      ),
                      Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _onSave,
                          child:
                              _isSaving
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text('Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
