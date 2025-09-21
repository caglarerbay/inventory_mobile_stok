// lib/screens/stock_movements_screen.dart

import 'package:flutter/material.dart';
import '../models/stock_movement.dart';
import '../services/stock_movement_service.dart';

class StockMovementsScreen extends StatefulWidget {
  final String token;
  const StockMovementsScreen({super.key, required this.token});

  @override
  State<StockMovementsScreen> createState() => _StockMovementsScreenState();
}

class _StockMovementsScreenState extends State<StockMovementsScreen> {
  late Future<List<StockMovement>> _futureMovements;
  late StockMovementService _service;

  @override
  void initState() {
    super.initState();
    _service = StockMovementService(
      baseUrl: 'https://nukstoktakip25.oa.r.appspot.com',
      token: widget.token,
    );
    _futureMovements = _service.fetchStockMovements();
  }

  String _formatTimestamp(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stok Hareketleri')),
      body: FutureBuilder<List<StockMovement>>(
        future: _futureMovements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          final movements = snapshot.data!;

          // Sadece son 200 hareketi göster
          final limited =
              movements.length <= 200 ? movements : movements.sublist(0, 200);

          if (limited.isEmpty) {
            return const Center(child: Text('Henüz hareket yok.'));
          }
          return ListView.separated(
            itemCount: limited.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final m = limited[index];
              return ListTile(
                title: Text('${m.product.partCode} – ${m.product.name}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tip: ${m.transactionType}'),
                    Text('Miktar: ${m.quantity}'),
                    Text('Kullanıcı: ${m.user}'),
                    Text('Zaman: ${_formatTimestamp(m.timestamp.toLocal())}'),
                    Text('Açıklama: ${m.description}'),
                    Text('Stok Sonra: ${m.currentQuantity}'),
                    if (m.currentUserQuantity != null)
                      Text('Kullanıcıda Kalan: ${m.currentUserQuantity}'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
