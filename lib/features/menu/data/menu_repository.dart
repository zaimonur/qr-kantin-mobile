/// @file lib/features/menu/data/menu_repository.dart
/// @description Kantin menü verilerini sunucudan çeken veri deposu.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'package:dio/dio.dart';
import '../domain/product_model.dart';

class MenuRepository {
  final Dio _dio;

  MenuRepository(this._dio);

  Future<List<Product>> getMenu() async {
    try {
      final response = await _dio.get('/api/menu');
      final List<dynamic> data = response.data;

      // Gelen JSON listesini Dart nesnelerine çevir
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Menü yüklenirken bir hata oluştu: $e');
    }
  }
}