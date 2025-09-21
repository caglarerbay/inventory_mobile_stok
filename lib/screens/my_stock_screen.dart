import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_constants.dart';

class MyStockScreen extends StatefulWidget {
  @override
  _MyStockScreenState createState() => _MyStockScreenState();
}

class _MyStockScreenState extends State<MyStockScreen> {
  String? _token;
  bool _isStaff = false;
  List<dynamic> _myStocks = [];
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _token = args["token"];
        _isStaff = args["staff_flag"] ?? false;
      }
      if (_token == null || _token!.isEmpty) {
        _token = prefs.getString('token');
      }
      await _fetchMyStocks();
    });
  }

  Future<void> _fetchMyStocks() async {
    if (_token == null || _token!.isEmpty) {
      setState(() {
        _errorMessage = "Token yok, stoğunuzu çekemiyoruz.";
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final url = Uri.parse('${ApiConstants.baseUrl}/api/my_stock/');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $_token',
    };
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final stocks = List<dynamic>.from(data["stocks"] ?? []);
        final filtered = stocks.where((i) => (i["quantity"] ?? 0) > 0).toList();
        setState(() {
          _myStocks = filtered;
          _isLoading = false;
        });
      } else {
        final body = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _errorMessage = body['detail'] ?? 'Hata: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Sunucuya erişilemedi: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _returnProduct(int productId, int quantity) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/return_product/$productId/',
    );
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $_token',
    };
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'quantity': quantity}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Depoya iade başarılı')));
        await _fetchMyStocks();
      } else {
        final body = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _errorMessage = body['detail'] ?? 'Hata: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Sunucuya erişilemedi: $e";
      });
    }
  }

  void _showReturnDialog(int productId) {
    int tempQty = 1;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Depoya Bırak'),
            content: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Miktar'),
              onChanged: (val) => tempQty = int.tryParse(val) ?? 1,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _returnProduct(productId, tempQty);
                },
                child: const Text('Onayla'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kişisel Stok')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
              : _myStocks.isEmpty
              ? const Center(child: Text('Stokta ürün bulunamadı.'))
              : ListView.builder(
                itemCount: _myStocks.length,
                itemBuilder: (ctx, i) {
                  final item = _myStocks[i];
                  final productId = item["product_id"] as int;
                  final name = item["product_name"];
                  final code = item["part_code"];
                  final qty = item["quantity"];
                  final cabinet = item["cabinet"] ?? '-';
                  final shelf = item["shelf"] ?? '-';
                  return ListTile(
                    title: Text('$name (Kod: $code)'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Miktar: $qty'),
                        Text('Dolap: $cabinet   •   Raf: $shelf'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.upload),
                      tooltip: 'Depoya Bırak',
                      onPressed: () => _showReturnDialog(productId),
                    ),
                  );
                },
              ),
    );
  }
}
