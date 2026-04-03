/// @file lib/features/order/presentation/order_tracking_provider.dart
/// @description Canlı sipariş durumu takibi ve WebSocket veri senkronizasyonu.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/order_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
final orderWebSocketProvider = StreamProvider.autoDispose<dynamic>((ref) async* {
  const storage = FlutterSecureStorage();

  // Anahtar 'jwt_token'
  final token = await storage.read(key: 'jwt_token') ?? '';

  if (token.isEmpty) return;

  // Token dolu geldiği zaman kapı açılacak
  final wsUrlWithToken = '${AppConstants.wsUrl}?token=$token';
  final channel = WebSocketChannel.connect(Uri.parse(wsUrlWithToken));

  ref.onDispose(() => channel.sink.close());

  await for (final message in channel.stream) {
    final data = jsonDecode(message);

    if (data['type'] == 'STATUS_UPDATE') {
      // Siparişleri ve bakiyeyi anlık tazele
      ref.invalidate(myOrdersProvider);

      final dio = ref.read(dioClientProvider).dio;
      dio.get('/api/wallet/balance').then((response) {
        final currentBalance = (response.data['balance'] as num).toDouble();
        ref.read(authProvider.notifier).updateBalance(currentBalance);
      });
    }
    yield data;
  }
});