/// @file lib/features/order/data/order_repository.dart
/// @description Sipariş oluşturma ve sunucu iletişimini sağlayan veri deposu.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'package:dio/dio.dart';
import '../domain/cart_item.dart';

class OrderRepository {
  final Dio _dio;

  OrderRepository(this._dio);

  Future<Map<String, dynamic>> createOrder(List<CartItem> cartItems, String note) async {
    try {
      final payload = {
        "items": cartItems.map((item) => {
          "product_id": item.product.id,
          "quantity": item.quantity,
        }).toList(),
        "note": note // YENİ: Notu backend'e gönderiyoruz
      };

      final response = await _dio.post('/api/order', data: payload); // Yolun /api/order olduğuna dikkat et

      if (response.statusCode == 201) {
        return {
          'orderId': response.data['order_id'],
          'newBalance': (response.data['new_balance'] as num).toDouble(),
        };
      }
      throw Exception('Beklenmeyen bir hata oluştu.');
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Sipariş oluşturulamadı.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}