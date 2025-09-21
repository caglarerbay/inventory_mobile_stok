import 'package:flutter/material.dart';
import '../models/institution.dart';
import '../models/institution_note.dart';
import '../models/installation.dart';
import '../services/institution_service.dart';

class InstitutionDetailScreen extends StatefulWidget {
  final int institutionId;

  const InstitutionDetailScreen({Key? key, required this.institutionId})
    : super(key: key);

  @override
  _InstitutionDetailScreenState createState() =>
      _InstitutionDetailScreenState();
}

class _InstitutionDetailScreenState extends State<InstitutionDetailScreen> {
  final _service = InstitutionService();
  Institution? _institution;
  List<InstitutionNote> _notes = [];
  List<Installation> _installs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final inst = await _service.getById(widget.institutionId);
      final notes = await _service.getNotes(widget.institutionId);
      final installs = await _service.getInstallations(widget.institutionId);
      setState(() {
        _institution = inst;
        _notes = notes;
        _installs = installs;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Veri alınırken hata oluştu');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteNote(int noteId) async {
    await _service.deleteNote(noteId);
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_institution?.name ?? 'Kurum Detay'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.pushNamed(
                context,
                '/institutions/edit',
                arguments: widget.institutionId,
              );
              if (updated == true) _loadAll();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _loading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                  child: Text(_error!, style: TextStyle(color: Colors.red)),
                )
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kurum bilgileri
                      Text(
                        'Şehir: ${_institution!.city}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Yetkili: ${_institution!.contactName}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Telefon: ${_institution!.contactPhone}',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),

                      // Kurulu Cihazlar
                      Text('Kurulu Cihazlar', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      if (_installs.isEmpty)
                        Text(
                          'Henüz kurulum yapılmamış.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ..._installs.map(
                        (ins) => Card(
                          child: ListTile(
                            title: Text(
                              '${ins.deviceSerial} (${ins.deviceType})',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Kurulum: ${ins.installDate}' +
                                  (ins.connectedCoreSerial != null
                                      ? ' • Core: ${ins.connectedCoreSerial}'
                                      : ''),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: Colors.grey[600],
                            ), // YENİ
                            onTap: () {
                              // YENİ
                              print('Kurulu cihaz id: ${ins.deviceId}');
                              Navigator.pushNamed(
                                context,
                                '/devices/detail',
                                arguments: ins.deviceId,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(),
                      const SizedBox(height: 16),

                      // Notlar
                      Text('Notlar', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      if (_notes.isEmpty)
                        Text(
                          'Henüz not eklenmemiş.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ..._notes.map(
                        (note) => Card(
                          child: ListTile(
                            title: Text(
                              '${note.noteDate} • ${note.createdBy}',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(note.text),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 20),
                                  onPressed: () async {
                                    final updated = await Navigator.pushNamed(
                                      context,
                                      '/institution-notes/edit',
                                      arguments: {
                                        'institutionId': widget.institutionId,
                                        'noteId': note.id,
                                        'note': note,
                                      },
                                    );
                                    if (updated == true) _loadAll();
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, size: 20),
                                  onPressed:
                                      () => showDialog(
                                        context: context,
                                        builder:
                                            (_) => AlertDialog(
                                              title: Text('Silinsin mi?'),
                                              content: Text(
                                                'Bu not silinecek.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: Text('Hayır'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _deleteNote(note.id);
                                                  },
                                                  child: Text('Evet'),
                                                ),
                                              ],
                                            ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.note_add),
                          label: Text('Yeni Not'),
                          onPressed: () async {
                            final created = await Navigator.pushNamed(
                              context,
                              '/institution-notes/edit',
                              arguments: {
                                'institutionId': widget.institutionId,
                                'noteId': null,
                              },
                            );
                            if (created == true) _loadAll();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
