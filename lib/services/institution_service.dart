import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_mobile/models/institution.dart';
import 'package:inventory_mobile/models/institution_note.dart';
import 'package:inventory_mobile/models/installation.dart';
import 'package:inventory_mobile/services/api_constants.dart';

class InstitutionService {
  final Dio _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        contentType: 'application/json',
      ),
    )
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token') ?? '';
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Token $token';
          }
          handler.next(options);
        },
      ),
    );

  Future<List<Institution>> getAllInstitutions() async {
    final res = await _dio.get('/api/institutions/');
    return (res.data as List)
        .map((e) => Institution.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Institution>> search(String q) async {
    final res = await _dio.get(
      '/api/institutions/',
      queryParameters: {'search': q},
    );
    return (res.data as List)
        .map((e) => Institution.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Institution> getById(int id) async {
    final res = await _dio.get('/api/institutions/$id/');
    return Institution.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Institution> update(Institution inst) async {
    final res = await _dio.patch(
      '/api/institutions/${inst.id}/',
      data: inst.toJson(),
    );
    return Institution.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Institution> createInstitution(Institution inst) async {
    final res = await _dio.post('/api/institutions/', data: inst.toJson());
    return Institution.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<InstitutionNote>> getNotes(int institutionId) async {
    final res = await _dio.get(
      '/api/institution-notes/',
      queryParameters: {'institution_id': institutionId},
    );
    return (res.data as List)
        .map((e) => InstitutionNote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InstitutionNote> addNote(int institutionId, String text) async {
    final res = await _dio.post(
      '/api/institution-notes/',
      data: {'institution_id': institutionId, 'text': text},
    );
    return InstitutionNote.fromJson(res.data as Map<String, dynamic>);
  }

  Future<InstitutionNote> updateNote(InstitutionNote note) async {
    final res = await _dio.patch(
      '/api/institution-notes/${note.id}/',
      data: {'text': note.text},
    );
    return InstitutionNote.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteNote(int noteId) async {
    await _dio.delete('/api/institution-notes/$noteId/');
  }

  Future<List<Map<String, dynamic>>> getCoresForInstitution(
    int institutionId,
  ) async {
    final path = '/api/institutions/$institutionId/installations/';
    final res = await _dio.get(path);
    final installs = res.data as List;
    return installs
        .where((i) => i['device_type'] == 'CORE' && i['uninstall_date'] == null)
        .map(
          (i) => {
            'id': i['device_id'] as int,
            'serial': i['device_serial'] as String,
          },
        )
        .toList();
  }

  Future<List<Installation>> getInstallations(int institutionId) async {
    final path = '/api/institutions/$institutionId/installations/';
    final res = await _dio.get(path);
    return (res.data as List)
        .map((e) => Installation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
