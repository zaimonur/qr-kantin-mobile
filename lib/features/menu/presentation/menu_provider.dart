/// @file lib/features/menu/presentation/menu_provider.dart
/// @description Menü listesini sağlayan ve arama filtrelerini yöneten sağlayıcılar.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/menu_repository.dart';
import '../domain/product_model.dart';

// Repository Provider'ı
final menuRepositoryProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return MenuRepository(dioClient.dio);
});

// Veriyi asenkron olarak çeken FutureProvider
final menuListProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(menuRepositoryProvider);
  return await repository.getMenu();
});