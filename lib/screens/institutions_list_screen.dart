// lib/screens/institutions_list_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_constants.dart';

class InstitutionsListScreen extends StatefulWidget {
  @override
  _InstitutionsListScreenState createState() => _InstitutionsListScreenState();
}

class _InstitutionsListScreenState extends State<InstitutionsListScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _loading = false;
  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onSearchChanged);
    SharedPreferences.getInstance().then((prefs) {
      _token = prefs.getString('token');
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onSearchChanged);
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 300), _searchInstitutions);
  }

  Future<void> _searchInstitutions() async {
    final q = _ctrl.text.trim();
    if (q.length < 5) {
      setState(() {
        _results = [];
        _error = 'Lütfen en az 5 karakter girin';
      });
      return;
    }
    if (_token == null || _token!.isEmpty) {
      setState(() {
        _error = 'Token bulunamadı';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/institutions/?search=$q',
    );
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $_token',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _results = data;
          if (data.isEmpty) _error = 'Sonuç bulunamadı';
        });
      } else {
        final body = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _error = body['detail'] ?? 'Hata: ${response.statusCode}';
          _results = [];
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Sunucuya erişilemedi: $e';
        _results = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kurum Ara')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                labelText: 'Kurum adıyla ara',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (ctx, i) {
                    final inst = _results[i];
                    return ListTile(
                      title: Text(inst['name']),
                      subtitle: Text(inst['city']),
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            '/institutions/detail',
                            arguments: inst['id'] as int,
                          ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: 'Yeni Kurum Ekle',
        onPressed: () async {
          final created = await Navigator.pushNamed(
            context,
            '/institutions/create',
          );
          if (created == true && _ctrl.text.trim().length >= 5) {
            _searchInstitutions();
          }
        },
      ),
    );
  }
}
