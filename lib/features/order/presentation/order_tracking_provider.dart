/// @file lib/features/order/presentation/order_tracking_provider.dart
/// @description Canlı sipariş durumu takibi ve WebSocket veri senkronizasyonu.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/order_model.dart';

// API'den siparişleri çeken FutureProvider
final myOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final dio = ref.watch(dioClientProvider).dio;

  final response = await dio.get('/api/orders/me');
  final List<dynamic> data = response.data;

  final orders = data.map((json) => OrderModel.fromJson(json)).toList();

  // Backend verisindeki sıralama farkını gidermek için siparişleri tarihe göre yeniden sıralıyoruz.
  // created_at (String) değerine göre Z'den A'ya (en yeni en üstte) sıralıyoruz
  orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return orders;
});

// Canlı WebSocket Dinleyicisi
final orderWebSocketProvider = Provider.autoDispose((ref) {
  final channel = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:1323/ws'));

  channel.stream.listen((message) {
    final data = jsonDecode(message);

    // Backend'den "STATUS_UPDATE" sinyali gelirse (İade, Onay vs.)
    if (data['type'] == 'STATUS_UPDATE') {

      // 1. Sipariş listesini tazeleyelim
      ref.invalidate(myOrdersProvider);

      // 2. İade (Refund) ihtimaline karşı cüzdanı da API'den tazeleyelim
      final dio = ref.read(dioClientProvider).dio;
      dio.get('/api/wallet/balance').then((response) {
        final currentBalance = (response.data['balance'] as num).toDouble();

        // Riverpod ile ekrandaki cüzdanı güncelleyelim
        ref.read(authProvider.notifier).updateBalance(currentBalance);

      }).catchError((_) {
        // Hata durumunda uygulamanın sürekliliğini koru ve logla.
      });
    }
  });

  // Sayfadan çıkıldığında bağlantıyı temizle
  ref.onDispose(() => channel.sink.close());

  return channel;
});