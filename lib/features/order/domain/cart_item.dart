/// @file lib/features/order/domain/cart_item.dart
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import '../../menu/domain/product_model.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  // Mevcut nesneyi kopyalayıp sadece miktarını değiştirmek için (Riverpod'un immutability kuralı)
  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}