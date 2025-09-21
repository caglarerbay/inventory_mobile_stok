import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device_part_usage.dart';
import 'api_constants.dart';

class DevicePartUsageService {
  // Bir cihaza ait kullanılan parçaları listele
  Future<List<DevicePartUsage>> fetchUsageByDevice(
    int deviceId,
    String token,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/device-part-usage/?device=$deviceId',
    );
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonList.map((json) => DevicePartUsage.fromJson(json)).toList();
    } else {
      throw Exception('Cihazda kullanılan parçalar getirilemedi');
    }
  }

  // Parça kullanım kaydı ekle (cihaz ile)
  Future<DevicePartUsage> createUsage({
    required int device,
    required int product,
    required int quantity,
    required String token,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/device-part-usage/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode({
        'device': device,
        'product': product,
        'quantity': quantity,
      }),
    );
    if (response.statusCode == 201) {
      return DevicePartUsage.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception('Parça kullanımı kaydedilemedi: ${response.body}');
    }
  }
}
