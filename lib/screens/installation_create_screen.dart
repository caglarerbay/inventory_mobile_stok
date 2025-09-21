import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/institution.dart';
import '../models/installation.dart';
import '../services/institution_service.dart';
import '../services/installation_service.dart';
import '../services/device_service.dart';

class InstallationCreateScreen extends StatefulWidget {
  final int deviceId;
  const InstallationCreateScreen({Key? key, required this.deviceId})
    : super(key: key);

  @override
  _InstallationCreateScreenState createState() =>
      _InstallationCreateScreenState();
}

class _InstallationCreateScreenState extends State<InstallationCreateScreen> {
  final _institutionController = TextEditingController();
  Institution? _selectedInstitution;
  List<Map<String, dynamic>> _cores = [];
  int? _selectedCoreId;
  DateTime _installDate = DateTime.now();

  bool _loadingCores = false;
  bool _requiresCore = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _determineIfRequiresCore();
  }

  Future<void> _determineIfRequiresCore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final detail = await DeviceService().getDeviceDetail(
      widget.deviceId,
      token,
    );
    setState(() {
      _requiresCore = detail.coreRequired;
    });
  }

  @override
  void dispose() {
    _institutionController.dispose();
    super.dispose();
  }

  Future<void> _onInstitutionChanged(Institution inst) async {
    setState(() {
      _selectedInstitution = inst;
      _institutionController.text = inst.name;
      _selectedCoreId = null;
      _cores = [];
      _loadingCores = true;
    });
    try {
      final cores = await InstitutionService().getCoresForInstitution(inst.id!);
      setState(() => _cores = cores);
    } finally {
      setState(() => _loadingCores = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _installDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _installDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedInstitution == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen kurum seçin.')));
      return;
    }
    if (_requiresCore && _selectedCoreId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen core seçin.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final dateStr = _installDate.toIso8601String().split('T').first;
      await InstallationService().createInstallation(
        deviceId: widget.deviceId,
        institutionId: _selectedInstitution!.id!,
        connectedCoreId: _selectedCoreId, // artık ID
        installDate: dateStr,
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kurulum başarısız: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cihaz Kurulum')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _institutionController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Kurum',
                hintText: 'Kurum ara ve seç',
                suffixIcon: Icon(Icons.search),
              ),
              onTap: () async {
                final inst = await showSearch<Institution?>(
                  context: context,
                  delegate: _InstitutionSearchDelegate(),
                );
                if (inst != null) {
                  await _onInstitutionChanged(inst);
                }
              },
            ),
            const SizedBox(height: 16),
            if (_requiresCore) ...[
              if (_loadingCores)
                const CircularProgressIndicator()
              else
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Core'),
                  value: _selectedCoreId,
                  items:
                      _cores
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(c['serial'] as String),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selectedCoreId = v),
                ),
              const SizedBox(height: 16),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kurulum Tarihi'),
              subtitle: Text(_installDate.toLocal().toString().split(' ')[0]),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectDate,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child:
                    _submitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Kur'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstitutionSearchDelegate extends SearchDelegate<Institution?> {
  final InstitutionService _service = InstitutionService();

  @override
  String get searchFieldLabel => 'Kurum adı ara';

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Lütfen bir şey yazın'));
    }
    return FutureBuilder<List<Institution>>(
      future: _service.search(query),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Hata: ${snap.error}'));
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return const Center(child: Text('Sonuç bulunamadı'));
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final inst = list[i];
            return ListTile(
              title: Text(inst.name),
              subtitle: Text(inst.city),
              onTap: () => close(context, inst),
            );
          },
        );
      },
    );
  }
}
