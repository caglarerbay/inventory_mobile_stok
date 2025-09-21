import 'package:flutter/material.dart';
import '../models/device_part_usage.dart';
import '../services/device_part_usage_service.dart';

class DeviceUsedPartsScreen extends StatefulWidget {
  final int deviceId;
  final String token; // token da ekleyelim
  const DeviceUsedPartsScreen({
    Key? key,
    required this.deviceId,
    required this.token,
  }) : super(key: key);

  @override
  _DeviceUsedPartsScreenState createState() => _DeviceUsedPartsScreenState();
}

class _DeviceUsedPartsScreenState extends State<DeviceUsedPartsScreen> {
  late Future<List<DevicePartUsage>> _futureParts;

  @override
  void initState() {
    super.initState();
    _futureParts = DevicePartUsageService().fetchUsageByDevice(
      widget.deviceId,
      widget.token,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kullanılan Parçalar')),
      body: FutureBuilder<List<DevicePartUsage>>(
        future: _futureParts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          final parts = snapshot.data ?? [];
          if (parts.isEmpty) {
            return Center(child: Text('Bu cihaza ait kullanım kaydı yok.'));
          }
          return ListView.builder(
            itemCount: parts.length,
            itemBuilder: (ctx, i) {
              final p = parts[i];
              return ListTile(
                title: Text('${p.productName} (Kod: ${p.productCode})'),
                subtitle: Text(
                  'Miktar: ${p.quantity}\nKullanıcı: ${p.userUsername}\nTarih: ${p.usedAt.toString().substring(0, 16)}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
