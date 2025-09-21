// lib/services/device_service.dart

import 'package:dio/dio.dart';
import '../models/device_record.dart';
import '../models/device_type.dart';
import '../models/device_detail.dart';
import '../models/maintenance_record.dart';
import '../models/fault_record.dart';
import '../models/installation.dart'; // ← Yeni ekleme
import 'api_constants.dart';

class DeviceService {
  final Dio _dio;

  DeviceService([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              headers: {'Content-Type': 'application/json'},
            ),
          );

  Future<List<DeviceRecord>> searchDevices(String query, String token) async {
    final response = await _dio.get(
      '/api/device-records/',
      queryParameters: {'q': query},
      options: Options(headers: {'Authorization': 'Token $token'}),
    );
    final data = response.data as List;
    return data
        .map((e) => DeviceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DeviceRecord> createDevice({
    required int deviceTypeId,
    required String serialNumber,
    String? token,
    int? institutionId,
  }) async {
    final body = {
      'device_type_id': deviceTypeId,
      'serial_number': serialNumber,
      if (institutionId != null) 'institution_id': institutionId,
    };
    final response = await _dio.post(
      '/api/device-records/',
      data: body,
      options: Options(
        headers: {if (token != null) 'Authorization': 'Token $token'},
      ),
    );
    return DeviceRecord.fromJson(response.data as Map<String, dynamic>);
  }

  /// Cihaz tiplerini getirir.
  Future<List<DeviceType>> getDeviceTypes(String token) async {
    final response = await _dio.get(
      '/api/device-types/',
      options: Options(headers: {'Authorization': 'Token $token'}),
    );
    final data = response.data as List;
    return data
        .map((e) => DeviceType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DeviceDetail> getDeviceDetail(int id, String token) async {
    final response = await _dio.get(
      '/api/device-records/$id/',
      options: Options(headers: {'Authorization': 'Token $token'}),
    );
    return DeviceDetail.fromJson(response.data as Map<String, dynamic>);
  }

  // ——— Yeni Metot: Bir cihaza ait kurulum/söküm geçmişini getirir ———
  Future<List<Installation>> getInstallationsForDevice(
    int deviceId,
    String token,
  ) async {
    final response = await _dio.get(
      '/api/installations/',
      queryParameters: {'device_id': deviceId},
      options: Options(headers: {'Authorization': 'Token $token'}),
    );
    final data = response.data as List;
    return data
        .map((e) => Installation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Bu cihaza ait bakım kayıtlarını getirir
  Future<List<MaintenanceRecord>> getMaintenanceRecords(
    int deviceId,
    String token,
  ) async {
    final response = await _dio.get(
      '/api/maintenance/', // tekil endpoint
      queryParameters: {'device_id': deviceId},
      options: Options(headers: {'Authorization': 'Token $token'}),
    );
    final data = response.data as List;
    return data
        .map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Yeni bakım kaydı oluşturur.
  /// Yeni bakım kaydı oluşturur
  Future<MaintenanceRecord> createMaintenanceRecord({
    required int deviceId,
    required String date,
    required String personnel,
    required String notes,
    required String token,
  }) async {
    final body = {
      'device_id': deviceId,
      'date': date,
      'personnel': personnel,
      'notes': notes,
    };
    final response = await _dio.post(
      '/api/maintenance/', // tekil endpoint
      data: body,
      options: Options(headers: {'Authorization': 'Token $token'}),
    );
    return MaintenanceRecord.fromJson(response.data as Map<String, dynamic>);
  }

  /// Bu cihaza ait arıza kayıtlarını getirir.
  Future<List<FaultRecord>> getFaultRecords(int deviceId, String token) async {
    final response = await _dio.get(
      '/api/faults/',
      queryParameters: {'device_id': deviceId},
      options: Options(headers: {'Authorization': 'Token $token'}),
    );
    final data = response.data as List;
    return data
        .map((e) => FaultRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Yeni arıza kaydı oluşturur.
  Future<FaultRecord> createFaultRecord({
    required int deviceId,
    required String faultDate,
    required String technician,
    required String initialNotes,
    String? closingNotes,
    String? closedDate,
    required String token,
  }) async {
    final body = {
      'device_id': deviceId,
      'fault_date': faultDate,
      'technician': technician,
      'initial_notes': initialNotes,
      'closing_notes': closingNotes,
      'closed_date': closedDate,
    };
    final response = await _dio.post(
      '/api/faults/',
      data: body,
      options: Options(headers: {'Authorization': 'Token $token'}),
    );
    return FaultRecord.fromJson(response.data as Map<String, dynamic>);
  }

  //arıza güncleleme modeli
  Future<FaultRecord> updateFaultRecord({
    required int id,
    String? closingNotes,
    String? closedDate,
    required String token,
  }) async {
    final body = {
      if (closingNotes != null) 'closing_notes': closingNotes,
      if (closedDate != null) 'closed_date': closedDate,
    };
    final response = await _dio.patch(
      '/api/faults/$id/',
      data: body,
      options: Options(headers: {'Authorization': 'Token $token'}),
    );
    return FaultRecord.fromJson(response.data as Map<String, dynamic>);
  }
}
