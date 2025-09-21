// lib/services/product_service.dart

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import 'api_constants.dart';

class ProductService {
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

  /// Kritik stokta olan ürünleri getirir.
  /// Backend endpoint: GET /api/critical_stock_api/
  Future<List<Product>> getCriticalStock() async {
    final res = await _dio.get('/api/critical_stock_api/');

    // res.data muhtemelen şöyle bir Map: { "critical_products": [ {...}, {...} ] }
    final raw = res.data as Map<String, dynamic>;

    // raw['critical_products'] listesini alıyoruz:
    final list = raw['critical_products'] as List<dynamic>;

    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Belirli bir ürünün order_placed durumunu toggle eder.
  /// Backend endpoint: PATCH /api/critical_stock_api/{product_id}/toggle_order/
  Future<bool> toggleOrderPlaced(int productId, bool orderPlaced) async {
    final res = await _dio.patch(
      '/api/critical_stock_api/$productId/toggle_order/',
      data: {'order_placed': orderPlaced},
    );
    // res.data muhtemelen bir Map: { "detail":"OK", "order_placed": true }
    final raw = res.data as Map<String, dynamic>;
    return raw['order_placed'] as bool;
  }
}
