/// @file lib/features/order/presentation/cart_provider.dart
/// @description Sepet mantığı, miktar hesaplamaları ve ürün yönetimi sağlayıcısı.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/cart_item.dart';
import '../../menu/domain/product_model.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]); // Başlangıçta sepet bomboş

  // Sepete ürün ekle
  void addProduct(Product product) {
    // Ürün sepette zaten var mı diye bakıyoruz
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // Varsa miktarını 1 artır
      final newState = [...state];
      newState[existingIndex] = newState[existingIndex].copyWith(
        quantity: newState[existingIndex].quantity + 1,
      );
      state = newState;
    } else {
      // Yoksa listeye yeni bir eleman olarak ekle
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  // Sepetten ürün çıkar (veya miktarını azalt)
  void removeProduct(String productId) {
    final existingIndex = state.indexWhere((item) => item.product.id == productId);

    if (existingIndex >= 0) {
      if (state[existingIndex].quantity > 1) {
        // Miktar 1'den büyükse sadece eksilt
        final newState = [...state];
        newState[existingIndex] = newState[existingIndex].copyWith(
          quantity: newState[existingIndex].quantity - 1,
        );
        state = newState;
      } else {
        // Miktar 1 ise ürünü sepet listesinden kaldır.
        state = state.where((item) => item.product.id != productId).toList();
      }
    }
  }

  // Sepeti tamamen boşalt (Sipariş onaylanınca kullanacağız)
  void clearCart() {
    state = [];
  }

  // Sepetin Toplam Tutarı (Dinamik hesaplanır)
  double get totalAmount {
    return state.fold(0, (total, item) => total + (item.product.price * item.quantity));
  }

  // Sepetteki Toplam Ürün Adedi (Örn: 2 Tost + 1 Çay = 3)
  int get itemCount {
    return state.fold(0, (total, item) => total + item.quantity);
  }
}

// UI katmanından erişeceğimiz ana Provider
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});