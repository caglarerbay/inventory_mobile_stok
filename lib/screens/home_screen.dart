import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../services/api_constants.dart';
import '../services/institution_service.dart';
import '../services/device_service.dart';
import '../models/institution.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  String? _errorMessage;
  Timer? _debounce;
  bool _isStaff = false;
  String? _token;
  List<String> _userList = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _isStaff = args["staff_flag"] ?? false;
        _token = args["token"];
      }
      _token ??= prefs.getString('token');
      _isStaff = prefs.getBool('staffFlag') ?? _isStaff;
      if (_token != null && _token!.isNotEmpty) {
        await _fetchUserList();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = _searchController.text.trim();
      if (q.length < 5) {
        setState(() {
          _errorMessage = 'Lütfen en az 5 karakter girin';
          _searchResults.clear();
        });
      } else {
        _searchProduct();
      }
    });
  }

  Future<void> _searchProduct() async {
    if (_token == null || _token!.isEmpty) {
      setState(() {
        _errorMessage = "Token yok, arama yapılamaz.";
        _searchResults.clear();
      });
      return;
    }
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/search_product/?q=${_searchController.text.trim()}',
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
          _errorMessage = null;
          _searchResults = data;
        });
      } else {
        final body = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _errorMessage = body['detail'] ?? 'Hata: ${response.statusCode}';
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

  Future<void> _fetchUserList() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/user_list/');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $_token',
    };
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _userList = List<String>.from(data['users']);
        });
      }
    } catch (_) {}
  }

  Future<void> _promptTakeProduct(int productId) async {
    int qty = 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Depodan Kendinize Al'),
            content: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Miktar'),
              onChanged: (v) => qty = int.tryParse(v) ?? 1,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Al'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await _takeProduct(productId, qty);
    }
  }

  Future<void> _takeProduct(int productId, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? _token;
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/take_product/$productId/',
    );
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({'quantity': quantity}),
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Depodan ödünç alındı')));
    } else {
      String msg;
      try {
        msg = json.decode(res.body)['detail'] ?? res.body;
      } catch (_) {
        msg = 'Beklenmeyen yanıt (${res.statusCode})';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $msg')));
    }
  }

  Future<void> _promptDirectTransfer(int productId) async {
    if (!_isStaff) return;
    int qty = 1;
    String? targetUser;
    if (_userList.isEmpty) await _fetchUserList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Ana Stoktan Direkt Transfer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Miktar'),
                  onChanged: (v) => qty = int.tryParse(v) ?? 1,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Hedef Kullanıcı',
                  ),
                  items:
                      _userList
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                  onChanged: (v) => targetUser = v,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Gönder'),
              ),
            ],
          ),
    );
    if (confirmed == true && targetUser != null) {
      await _directTransferProduct(productId, qty, targetUser!);
    } else if (confirmed == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen kullanıcı seçin')));
    }
  }

  Future<void> _directTransferProduct(
    int productId,
    int quantity,
    String targetUsername,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? _token;
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/direct_transfer_product/$productId/',
    );
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'quantity': quantity,
        'target_username': targetUsername,
      }),
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrudan transfer başarılı')),
      );
    } else {
      String msg;
      try {
        msg = json.decode(res.body)['detail'] ?? res.body;
      } catch (_) {
        msg = 'Beklenmeyen yanıt (${res.statusCode})';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $msg')));
    }
  }

  Future<void> _scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        _searchController.text = result.rawContent;
        _searchProduct();
      }
    } catch (e) {
      print("Barkod tarama hatası: $e");
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('staffFlag');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Ekran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed:
                () => Navigator.pushNamed(context, '/notification_history'),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Çıkış Yap',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Ürün Kodu/Adı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _scanBarcode,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed:
                  () => Navigator.pushNamed(
                    context,
                    '/manage',
                    arguments: {'token': _token, 'staff_flag': _isStaff},
                  ),
              child: const Text('Genel Panel'),
            ),
            const SizedBox(height: 8),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            Expanded(
              child:
                  _searchResults.isEmpty
                      ? const Center(child: Text('Hiç ürün bulunamadı.'))
                      : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (ctx, i) {
                          final product = _searchResults[i];
                          final partCode = product['part_code'];
                          final name = product['name'];
                          final anaStokQty = product['quantity'];
                          final cabinet = product['cabinet'] ?? '-';
                          final shelf = product['shelf'] ?? '-';
                          return ExpansionTile(
                            title: Row(
                              children: [
                                Expanded(child: Text('$name (Kod: $partCode)')),
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  tooltip: 'Depodan Al',
                                  onPressed:
                                      () => _promptTakeProduct(
                                        product['id'] as int,
                                      ),
                                ),
                                if (_isStaff)
                                  IconButton(
                                    icon: const Icon(Icons.group_add),
                                    tooltip: 'Arkadaşınıza Al',
                                    onPressed:
                                        () => _promptDirectTransfer(
                                          product['id'] as int,
                                        ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              'Ana Stok: $anaStokQty | Dolap: $cabinet | Raf: $shelf',
                            ),
                            children: [
                              if (product['car_stocks'] == null ||
                                  (product['car_stocks'] as List).isEmpty)
                                const ListTile(
                                  title: Text('Bu ürünü tutan kullanıcı yok.'),
                                )
                              else
                                ...(product['car_stocks'] as List).map((cs) {
                                  final username = cs['username'];
                                  final qty = cs['quantity'];
                                  return ListTile(
                                    title: Text('Kullanıcı: $username'),
                                    subtitle: Text('Miktar: $qty'),
                                  );
                                }).toList(),
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
