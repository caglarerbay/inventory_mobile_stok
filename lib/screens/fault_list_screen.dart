// lib/screens/fault_list_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fault_record.dart';
import '../services/device_service.dart';

class FaultListScreen extends StatefulWidget {
  final int deviceId;
  const FaultListScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  _FaultListScreenState createState() => _FaultListScreenState();
}

class _FaultListScreenState extends State<FaultListScreen> {
  late Future<List<FaultRecord>> _futureList;
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
    _futureList = DeviceService().getFaultRecords(widget.deviceId, token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arıza Kayıtları')),
      body: FutureBuilder<List<FaultRecord>>(
        future: _futureList,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Yüklenirken hata: ${snap.error}'));
          }
          final list = snap.data ?? [];

          // 1) Open ve Closed listelerini ayır
          final openList = <FaultRecord>[];
          final closedList = <FaultRecord>[];
          for (var f in list) {
            if (f.closedDate == null) {
              openList.add(f);
            } else {
              closedList.add(f);
            }
          }
          // 2) Tarihe göre (faultDate) descending sıralama
          int _compareByFaultDateDesc(FaultRecord a, FaultRecord b) =>
              DateTime.parse(
                b.faultDate,
              ).compareTo(DateTime.parse(a.faultDate));

          openList.sort(_compareByFaultDateDesc);
          closedList.sort(_compareByFaultDateDesc);

          // 3) Open önce, sonra Closed
          final combined = [...openList, ...closedList];

          if (combined.isEmpty) {
            return const Center(child: Text('Henüz arıza kaydı yok.'));
          }
          return ListView.separated(
            itemCount: combined.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final f = combined[i];
              final isOpen = f.closedDate == null;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text('Açılış tarihi: ${f.faultDate}'),
                subtitle: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Müdahale Eden: ${f.technician}'),
                    const SizedBox(height: 4),
                    Text('Sorun: ${f.initialNotes}'),
                    if (!isOpen) ...[
                      const SizedBox(height: 8),
                      Text('Kapanış tarihi: ${f.closedDate}'),
                      Text('Çözüm: ${f.closingNotes}'),
                    ],
                  ],
                ),
                isThreeLine: !isOpen,
                trailing: Text(
                  isOpen ? 'OPEN' : 'CLOSED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOpen ? Colors.red : Colors.green,
                  ),
                ),
                onTap:
                    isOpen
                        ? () => Navigator.pushNamed(
                          context,
                          '/devices/fault/form',
                          arguments: f,
                        ).then((_) => _loadTokenAndFetch())
                        : null,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.pushNamed(
              context,
              '/devices/fault/form',
              arguments: widget.deviceId,
            ).then((_) => _loadTokenAndFetch()),
        child: const Icon(Icons.add),
        tooltip: 'Yeni Arıza Kaydı',
      ),
    );
  }
}
