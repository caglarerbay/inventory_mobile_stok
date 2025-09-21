import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/api_constants.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class AdminUpdateStockScreen extends StatefulWidget {
  @override
  _AdminUpdateStockScreenState createState() => _AdminUpdateStockScreenState();
}

class _AdminUpdateStockScreenState extends State<AdminUpdateStockScreen> {
  String? _token;
  bool _isStaff = false;
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _searchResults = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _token = args["token"];
        _isStaff = args["staff_flag"] ?? false;
      } else {
        setState(() {
          _errorMessage = "Token veya staff_flag alınamadı.";
        });
      }
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 300), () {
      _searchProducts();
    });
  }

  Future<void> _searchProducts() async {
    final query = _searchController.text.trim();
    if (query.length < 5) {
      setState(() {
        _searchResults.clear();
        _errorMessage = null;
      });
      return;
    }

    if (_token == null || _token!.isEmpty) {
      setState(() {
        _errorMessage = "Token yok, arama yapılamaz.";
      });
      return;
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/search_product/?q=$query',
    );

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $_token', // Admin
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _searchResults = data;
          _errorMessage = null;
        });
      } else if (response.statusCode == 400) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _errorMessage = body['detail'] ?? "Hata: 400";
          _searchResults.clear();
        });
      } else {
        setState(() {
          _errorMessage = "Arama hatası: ${response.statusCode}";
          _searchResults.clear();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Sunucuya erişilemedi: $e";
        _searchResults.clear();
      });
    }
  }

  Future<void> _scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode) {
        String scannedCode = result.rawContent;
        if (scannedCode.isNotEmpty) {
          setState(() {
            _searchController.text = scannedCode;
          });
          _searchProducts();
        }
      }
    } catch (e) {
      print("Barkod tarama hatası: $e");
    }
  }

  void _showUpdateDialog(int productId) {
    int arrivedQty = 1;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Stok Güncelle"),
            content: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Gelen Miktar (arrived_quantity)",
              ),
              onChanged: (val) {
                arrivedQty = int.tryParse(val) ?? 1;
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("İptal"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateStock(productId, arrivedQty);
                },
                child: Text("Onayla"),
              ),
            ],
          ),
    );
  }

  Future<void> _updateStock(int productId, int arrivedQty) async {
    if (_token == null || _token!.isEmpty) {
      setState(() {
        _errorMessage = "Token yok, update_stock yapılamaz.";
      });
      return;
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/admin_update_stock/$productId/',
    );
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $_token',
    };

    final body = {"arrived_quantity": arrivedQty};

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _errorMessage = "Başarılı: ${data['detail']}";
        });
        _searchProducts();
      } else {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _errorMessage = data['detail'] ?? 'Hata: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Sunucu hatası: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stok Güncelle (Aramalı)')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Arama kutusu ve barkod tarama butonu + 5 karakter uyarısı
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: "Ürün Kodu / Adı",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _scanBarcode,
                ),
              ],
            ),
            if (_searchController.text.trim().isNotEmpty &&
                _searchController.text.trim().length < 5)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4),
                child: Text(
                  'Lütfen en az 5 karakter girin',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(height: 8),
            if (_errorMessage != null)
              Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 8),
            Expanded(
              child:
                  _searchResults.isEmpty
                      ? Center(child: Text("Ürün araması yapın."))
                      : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final product = _searchResults[index];
                          return ListTile(
                            title: Text(
                              '${product["name"]} (Kod: ${product["part_code"]})',
                            ),
                            subtitle: Text('Ana Stok: ${product["quantity"]}'),
                            trailing: IconButton(
                              icon: Icon(Icons.edit),
                              tooltip: "Stok Güncelle",
                              onPressed: () => _showUpdateDialog(product["id"]),
                            ),
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
