import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/device_part_usage_service.dart';
import '../models/device_part_usage.dart';

class DeviceUsedPartsScreen extends StatefulWidget {
  final int deviceId;

  const DeviceUsedPartsScreen({Key? key, required this.deviceId})
    : super(key: key);

  @override
  State<DeviceUsedPartsScreen> createState() => _DeviceUsedPartsScreenState();
}

class _DeviceUsedPartsScreenState extends State<DeviceUsedPartsScreen> {
  late Future<List<DevicePartUsage>> _futureUsage;

  @override
  void initState() {
    super.initState();
    _futureUsage = _loadUsage();
  }

  Future<List<DevicePartUsage>> _loadUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final service = DevicePartUsageService();
    return service.fetchUsageByDevice(widget.deviceId, token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kullanılan Parçalar")),
      body: FutureBuilder<List<DevicePartUsage>>(
        future: _futureUsage,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Bu cihazda henüz parça kullanılmamış."),
            );
          }

          final usageList = snapshot.data!;
          return ListView.builder(
            itemCount: usageList.length,
            itemBuilder: (context, index) {
              final usage = usageList[index];
              final dateStr = DateFormat(
                'dd.MM.yyyy HH:mm',
              ).format(usage.usedAt);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    "${usage.productName} (${usage.productCode})",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kullanan: ${usage.userUsername}"),
                      Text("Tarih: $dateStr"),
                      Text("Adet: ${usage.quantity}"),
                      Text(
                        "Fiyat: ${usage.productPrice != null ? usage.productPrice.toString() + ' €' : '-'}",
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
