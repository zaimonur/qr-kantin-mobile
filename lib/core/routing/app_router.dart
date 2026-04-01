/// @file lib/core/routing/app_router.dart
/// @description GoRouter tabanlı sayfa yönlendirme, korumalı rotalar ve navigasyon mantığı.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'main_layout.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/order/presentation/cart_screen.dart';
import '../../features/order/presentation/order_tracking_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authProvider.select((user) => user != null));

  return GoRouter(
    initialLocation: '/menu',
    redirect: (context, state) {
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';

      // Giriş yapmadıysa ve login/register harici bir yere gitmeye çalışıyorsa login'e at
      if (!isLoggedIn && !isGoingToLogin && !isGoingToRegister) return '/login';

      // Giriş yaptıysa ama login/register'a girmeye çalışıyorsa menüye yolla
      if (isLoggedIn && (isGoingToLogin || isGoingToRegister)) return '/menu';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Navigasyon Yapısı: Alt bar sekmeleri ve branch'ler burada tanımlanır.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/menu', builder: (context, state) => const MenuScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/orders', builder: (context, state) => const OrderTrackingScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/wallet', builder: (context, state) => const WalletScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/cart', builder: (context, state) => const CartScreen())]),
        ],
      ),
    ],
  );
});