import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../services/api_constants.dart';

class AdminMinLimitScreen extends StatefulWidget {
  @override
  _AdminMinLimitScreenState createState() => _AdminMinLimitScreenState();
}

class _AdminMinLimitScreenState extends State<AdminMinLimitScreen> {
  String? _token;
  String? _errorMessage;
  List<dynamic> _products = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _token = args["token"];
        _fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = _searchController.text.trim();
      setState(() {
        _searchQuery = q.toLowerCase();
      });
    });
  }

  Future<void> _scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        _searchController.text = result.rawContent;
      }
    } catch (e) {
      print("Barkod tarama hatası: $e");
    }
  }

  Future<void> _fetchProducts() async {
    if (_token == null || _token!.isEmpty) return;
    final url = Uri.parse('${ApiConstants.baseUrl}/api/products/');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $_token',
    };
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _products = data;
        });
      } else {
        setState(() {
          _errorMessage = "Ürünler alınamadı, status: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Hata: $e";
      });
    }
  }

  void _updateMinLimit(int productId, String partCode, int currentMinLimit) {
    int newLimit = currentMinLimit;
    final controller = TextEditingController(text: currentMinLimit.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Min Limit Güncelle ($partCode)"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Yeni Min Limit"),
            onChanged: (val) {
              newLimit = int.tryParse(val) ?? currentMinLimit;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("İptal"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _sendMinLimitUpdate(productId, newLimit);
                _fetchProducts();
              },
              child: Text("Güncelle"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendMinLimitUpdate(int productId, int newLimit) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/admin_update_min_limit/$productId/',
    );
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $_token',
    };
    final body = json.encode({"new_min_limit": newLimit});
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Min limit güncellendi.")));
      } else {
        final data = json.decode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['detail'] ?? "Hata: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts =
        _searchQuery.length < 5
            ? []
            : _products.where((product) {
              final name = (product['name'] ?? "").toString().toLowerCase();
              final partCode =
                  (product['part_code'] ?? "").toString().toLowerCase();
              return name.contains(_searchQuery) ||
                  partCode.contains(_searchQuery);
            }).toList();

    return Scaffold(
      appBar: AppBar(title: Text("Min Limit Ayarla")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: "Ürün Ara (Adı veya Kod)",
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
            _errorMessage != null
                ? Text(_errorMessage!, style: TextStyle(color: Colors.red))
                : SizedBox.shrink(),
            Expanded(
              child:
                  filteredProducts.isEmpty
                      ? Center(
                        child: Text(
                          _searchQuery.length < 5
                              ? "En az 5 karakter girin veya barkod okutun."
                              : "Ürün bulunamadı.",
                        ),
                      )
                      : ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final productName = product['name'];
                          final partCode = product['part_code'];
                          final minLimit = product['min_limit'] ?? 0;
                          return ListTile(
                            title: Text("$productName (Kod: $partCode)"),
                            subtitle: Text("Mevcut Min Limit: $minLimit"),
                            trailing: IconButton(
                              icon: Icon(Icons.edit),
                              onPressed:
                                  () => _updateMinLimit(
                                    product['id'],
                                    partCode,
                                    minLimit,
                                  ),
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
