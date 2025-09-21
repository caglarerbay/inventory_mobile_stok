import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_record.dart';
import '../services/device_service.dart';

class DevicesListScreen extends StatefulWidget {
  @override
  _DevicesListScreenState createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final DeviceService _service = DeviceService();

  List<DeviceRecord> _devices = [];
  String? _errorMessage;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token') ?? '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = text.trim();
      if (query.length >= 4) {
        _searchDevices(query);
      } else {
        setState(() {
          _devices.clear();
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _searchDevices(String query) async {
    try {
      final results = await _service.searchDevices(query, _token);
      setState(() {
        _devices = results;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _devices.clear();
        _errorMessage = 'Arama sırasında hata oluştu';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cihazlar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cihaz Ara (en az 4 karakter)',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _devices.isEmpty
                      ? Center(
                        child: Text(
                          _errorMessage ?? 'Henüz sonuç yok.',
                          style: TextStyle(
                            color:
                                _errorMessage != null
                                    ? Colors.red
                                    : Colors.black54,
                          ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final dev = _devices[index];
                          return ListTile(
                            title: Text(dev.serialNumber),
                            subtitle: Text(dev.deviceType),
                            onTap: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/devices/detail',
                                arguments: dev.id,
                              );
                              if (result == true) {
                                final q = _searchController.text.trim();
                                if (q.length >= 4) {
                                  _searchDevices(q);
                                } else {
                                  setState(() {
                                    _devices.clear();
                                    _errorMessage = null;
                                  });
                                }
                              }
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/devices/create');
          if (result == true) {
            final q = _searchController.text.trim();
            if (q.length >= 4) {
              _searchDevices(q);
            } else {
              setState(() {
                _devices.clear();
                _errorMessage = null;
              });
            }
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Yeni Cihaz Ekle',
      ),
    );
  }
}
