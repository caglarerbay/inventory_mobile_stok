import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_detail.dart';
import '../services/device_service.dart';
import '../services/installation_service.dart';
import '../screens/installation_history_screen.dart';
import 'device_used_parts_screen.dart';

class DeviceDetailScreen extends StatefulWidget {
  final int deviceId;
  const DeviceDetailScreen({Key? key, required this.deviceId})
    : super(key: key);

  @override
  _DeviceDetailScreenState createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  Future<DeviceDetail>? _futureDetail;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _futureDetail = _loadTokenAndFetch();
  }

  Future<DeviceDetail> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    setState(() => _token = token);
    return DeviceService().getDeviceDetail(widget.deviceId, token);
  }

  Future<void> _refreshDetail() async {
    setState(() {
      _futureDetail = _loadTokenAndFetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cihaz Detayı')),
      body: FutureBuilder<DeviceDetail>(
        future: _futureDetail,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Detay yüklenirken hata oluştu: ${snap.error}'),
            );
          }
          if (!snap.hasData) {
            return const Center(child: Text('Detay bulunamadı'));
          }
          final detail = snap.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text(
                  'Seri No: ${detail.serialNumber}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: ${detail.deviceType}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('Kurum: ${detail.institution ?? "Depoda"}'),
                const SizedBox(height: 8),
                Text('Bağlı Core: ${detail.connectedCore ?? "–"}'),
                const Divider(height: 32),
                Text('Kurulum Tarihi: ${detail.installDate ?? "–"}'),
                Text('Söküm Tarihi: ${detail.uninstallDate ?? "–"}'),

                const SizedBox(height: 24),
                // ——— Kur / Sök bloğu ———
                if (detail.institution != null) ...[
                  Text(
                    'Kurulu: ${detail.institution} (${detail.installDate ?? "–"})',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          detail.installationId == null
                              ? null
                              : () async {
                                final yes = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (ctx) => AlertDialog(
                                        title: const Text(
                                          'Cihazı sökmek istediğinize emin misiniz?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(ctx, false),
                                            child: const Text('Vazgeç'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(ctx, true),
                                            child: const Text('Evet'),
                                          ),
                                        ],
                                      ),
                                );
                                if (yes != true) return;

                                final today =
                                    DateTime.now()
                                        .toIso8601String()
                                        .split('T')
                                        .first;
                                try {
                                  await InstallationService().uninstallDevice(
                                    installationId: detail.installationId!,
                                    uninstallDate: today,
                                  );
                                  await _refreshDetail();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Sökme işlemi başarısız: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                      child: const Text('SÖK'),
                    ),
                  ),
                ] else ...[
                  const Text('Depoda', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/devices/installation/create',
                          arguments: widget.deviceId,
                        ).then((_) => _refreshDetail());
                      },
                      child: const Text('KUR'),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/devices/maintenance/list',
                          arguments: widget.deviceId,
                        );
                      },
                      child: const Text('Bakımlar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/devices/fault/list',
                          arguments: widget.deviceId,
                        );
                      },
                      child: const Text('Arızalar'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.build, color: Colors.blue),
                      label: const Text('Kullanılan Parçalar'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => DeviceUsedPartsScreen(
                                  deviceId: widget.deviceId,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                // ——— Kurulum Geçmişi Butonu ———
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('Kurulum Geçmişi'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => InstallationHistoryScreen(
                                deviceId: widget.deviceId,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
