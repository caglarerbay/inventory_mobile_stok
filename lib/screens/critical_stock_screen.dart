// lib/screens/critical_stock_screen.dart

import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class CriticalStockScreen extends StatefulWidget {
  @override
  _CriticalStockScreenState createState() => _CriticalStockScreenState();
}

class _CriticalStockScreenState extends State<CriticalStockScreen> {
  final _svc = ProductService();
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.getCriticalStock();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kritik Stok')),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Hata: ${snap.error}'));
          final list = snap.data!;
          if (list.isEmpty)
            return const Center(child: Text('Kritik stokta ürün yok.'));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (c, i) {
              final p = list[i];
              return CheckboxListTile(
                title: Text('${p.name} (Kod: ${p.partCode})'),
                subtitle: Text('Stok: ${p.quantity}  Min: ${p.minLimit}'),
                value: p.orderPlaced,
                onChanged: (v) async {
                  final newVal = await _svc.toggleOrderPlaced(p.id, v!);
                  setState(() => p.orderPlaced = newVal);
                },
              );
            },
          );
        },
      ),
    );
  }
}
