import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/maintenance_record.dart';
import '../services/device_service.dart';

class MaintenanceListScreen extends StatefulWidget {
  final int deviceId;
  const MaintenanceListScreen({Key? key, required this.deviceId})
    : super(key: key);

  @override
  _MaintenanceListScreenState createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  late Future<List<MaintenanceRecord>> _futureList;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    setState(() => _token = token);
    _futureList = DeviceService().getMaintenanceRecords(widget.deviceId, token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bakım Kayıtları')),
      body: FutureBuilder<List<MaintenanceRecord>>(
        future: _futureList,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Yüklenirken hata: ${snap.error}'));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('Henüz bakım kaydı yok.'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (c, i) {
              final m = list[i];
              return ListTile(
                title: Text(m.date),
                subtitle: Text('${m.personnel}\n${m.notes}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/devices/maintenance/create', // ← düzeltilmiş route
            arguments: widget.deviceId,
          ).then((_) {
            _loadTokenAndFetch();
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Yeni Bakım Ekle',
      ),
    );
  }
}
