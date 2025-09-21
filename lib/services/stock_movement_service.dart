// lib/services/stock_movement_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock_movement.dart';

class StockMovementService {
  final String baseUrl;
  final String token;

  StockMovementService({required this.baseUrl, required this.token});

  Future<List<StockMovement>> fetchStockMovements() async {
    final url = Uri.parse('$baseUrl/api/stock-movements/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final decodedString = utf8.decode(response.bodyBytes);
      final data = json.decode(decodedString);
      final List movementsJson = data['transactions'];
      return movementsJson
          .map((jsonItem) => StockMovement.fromJson(jsonItem))
          .toList();
    } else {
      throw Exception(
        'Sunucudan hareket verisi alınamadı: ${response.statusCode}',
      );
    }
  }
}
