// lib/screens/manage_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageScreen extends StatefulWidget {
  @override
  _ManageScreenState createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  String? _token;
  bool _isStaff = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFlag();
  }

  Future<void> _loadTokenAndFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final staffFlag = prefs.getBool('staffFlag') ?? false;
    setState(() {
      _token = token;
      _isStaff = staffFlag;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Genel Panel')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_token == null || _token!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Genel Panel')),
        body: Center(
          child: Text(
            'Token alınamadı. Lütfen tekrar giriş yapın.',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    // arguments olarak göndereceğimiz ortak map
    final args = {'token': _token, 'staff_flag': _isStaff};

    return Scaffold(
      appBar: AppBar(title: Text('Genel Panel')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed:
                  () => Navigator.pushNamed(
                    context,
                    '/my_stock_screen',
                    arguments: args,
                  ),
              child: Text('Kişisel Stok'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  () => Navigator.pushNamed(
                    context,
                    '/transfer_usage',
                    arguments: args,
                  ),
              child: Text('Transfer / Kullanım'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  () => Navigator.pushNamed(
                    context,
                    '/external_products',
                    arguments: args,
                  ),
              child: Text('PPL Listesi'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  () => Navigator.pushNamed(
                    context,
                    '/devices/list',
                    arguments: args,
                  ),
              child: Text('Cihazlar'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  () => Navigator.pushNamed(
                    context,
                    '/institutions',
                    arguments: args,
                  ),
              child: Text('Kurumlar'),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.warning, color: Colors.red),
              label: const Text('Kritik Stok'),
              onPressed:
                  () => Navigator.pushNamed(
                    context,
                    '/critical_stock',
                    arguments: {'token': _token, 'staff_flag': _isStaff},
                  ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  () => Navigator.pushNamed(
                    context,
                    '/admin_panel',
                    arguments: args,
                  ),
              child: Text('Admin Paneli'),
            ),
          ],
        ),
      ),
    );
  }
}
