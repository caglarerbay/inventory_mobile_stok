// lib/screens/external_list_screen.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_constants.dart';

class ExternalListScreen extends StatefulWidget {
  @override
  _ExternalListScreenState createState() => _ExternalListScreenState();
}

class _ExternalListScreenState extends State<ExternalListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  String? _token;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
  }

  Future<void> _searchExternal() async {
    final query = _searchController.text.trim();

    // Sadece 11 haneli kod kabul edilsin
    if (query.length != 11) {
      setState(() {
        _error = "Ürün kodu 11 haneli olmalıdır.";
        _results.clear();
      });
      return;
    }

    if (_token == null || _token!.isEmpty) {
      setState(() {
        _error = "Token bulunamadı.";
        _results.clear();
      });
      return;
    }

    setState(() {
      _error = null;
      _results.clear();
    });

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/external-products/?search=$query',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $_token'},
      );
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _results = data;
        });
      } else {
        setState(() {
          _error = 'Sunucu hatası: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Bağlantı hatası: $e';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PPL Listesi')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Ürün Kodu (11 hane)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 8),
            ElevatedButton(onPressed: _searchExternal, child: Text('Ara')),
            SizedBox(height: 8),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 8),
            Expanded(
              child:
                  _results.isEmpty
                      ? Center(child: Text('Sonuç yok.'))
                      : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final code = item['part_code'];
                          final name = item['name'];
                          final devices = item['devices'];
                          final price = item['unit_price'];
                          return ExpansionTile(
                            title: Text('$name (Kod: $code)'),
                            children: [
                              ListTile(
                                title: Text('Cihazlar: $devices'),
                                subtitle: Text('Fiyat: €${price.toString()}'),
                              ),
                            ],
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
