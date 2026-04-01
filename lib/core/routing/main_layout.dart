/// @file lib/core/routing/main_layout.dart
/// @description Uygulama ana şablonu ve alt navigasyon barı (BottomNavigationBar) yönetimi.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/order/presentation/cart_provider.dart';

class MainLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sepetteki toplam ürün sayısını Badge (Rozet) için dinliyoruz
    final cartItemCount = ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      body: navigationShell, // Aktif olan sekmenin içeriği buraya gelir
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // Sekmeye tıklandığında GoRouter'ın o sayfaya geçmesini sağlar
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: Colors.blue.shade100,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu, color: Colors.blueAccent),
            label: 'Menü',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Colors.blueAccent),
            label: 'Siparişler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: Colors.blueAccent),
            label: 'Cüzdan',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$cartItemCount'),
              isLabelVisible: cartItemCount > 0, // Sepet boşsa rozeti gizle
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              label: Text('$cartItemCount'),
              isLabelVisible: cartItemCount > 0,
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.shopping_cart, color: Colors.blueAccent),
            ),
            label: 'Sepet',
          ),
        ],
      ),
    );
  }
}