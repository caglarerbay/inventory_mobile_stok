import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/installation.dart';
import '../services/device_service.dart';

class InstallationHistoryScreen extends StatefulWidget {
  final int deviceId;
  const InstallationHistoryScreen({Key? key, required this.deviceId})
    : super(key: key);

  @override
  _InstallationHistoryScreenState createState() =>
      _InstallationHistoryScreenState();
}

class _InstallationHistoryScreenState extends State<InstallationHistoryScreen> {
  late Future<List<Installation>> _futureHistory;
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
    _futureHistory = DeviceService().getInstallationsForDevice(
      widget.deviceId,
      token,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kurulum Geçmişi')),
      body: FutureBuilder<List<Installation>>(
        future: _futureHistory,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Yüklenirken hata: ${snap.error}'));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Text('Bu cihaza ait kurulum kaydı yok.'),
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (c, i) {
              final rec = list[i];
              return ListTile(
                leading: Text(rec.installDate),
                title: Text(rec.institutionName),
                subtitle: Text(
                  rec.uninstallDate != null
                      ? 'Söküm: ${rec.uninstallDate}'
                      : 'Halen kurulu',
                ),
                trailing:
                    rec.connectedCoreSerial != null
                        ? Text('Core: ${rec.connectedCoreSerial}')
                        : null,
              );
            },
          );
        },
      ),
    );
  }
}
