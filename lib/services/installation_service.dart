import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/installation.dart';
import 'api_constants.dart';

class InstallationService {
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

  Future<List<Installation>> getInstallationHistory(int deviceId) async {
    final res = await _dio.get(
      '/api/installations/',
      queryParameters: {'device_id': deviceId},
    );
    return (res.data as List)
        .map((e) => Installation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Installation> createInstallation({
    required int deviceId,
    required int institutionId,
    int? connectedCoreId, // artık ID olarak alıyoruz
    required String installDate,
    String? uninstallDate,
  }) async {
    final data = <String, dynamic>{
      'device_id': deviceId,
      'institution_id': institutionId,
      'install_date': installDate,
      if (connectedCoreId != null)
        'connected_core_id': connectedCoreId, // ← burası
      if (uninstallDate != null) 'uninstall_date': uninstallDate,
    };
    final res = await _dio.post('/api/installations/', data: data);
    return Installation.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> uninstallDevice({
    required int installationId,
    required String uninstallDate,
  }) async {
    await _dio.patch(
      '/api/installations/$installationId/',
      data: {'uninstall_date': uninstallDate},
    );
  }
}
