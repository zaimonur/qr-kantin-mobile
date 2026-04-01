/// @file lib/features/order/presentation/cart_screen.dart
/// @description Sepet içeriği, sipariş notu ekleme ve ödeme onay ekranı.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/order_repository.dart';
import 'cart_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/network/dio_client.dart';
import 'order_tracking_provider.dart';

// Order Repository için Provider
final orderRepositoryProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return OrderRepository(dioClient.dio);
});

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isLoading = false;

  // Memory leak riskini önlemek için TextEditingController state içinde yönetilir.
  final _noteController = TextEditingController();

  Future<void> _checkout() async {
    final cartItems = ref.read(cartProvider);
    final repository = ref.read(orderRepositoryProvider);
    final note = _noteController.text.trim(); // YENİ: Notu alıyoruz

    if (cartItems.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Siparişi sunucuya gönder ve dönen paketi (orderId + newBalance) al
      // Sipariş oluşturma işlemi gerçekleştirilir.
      final result = await repository.createOrder(cartItems, note);
      final double newBalance = result['newBalance'];

      // Kullanıcı bakiyesi, sunucudan gelen doğrulayıcı veri (Source of Truth) ile senkronize edilir.
      ref.read(authProvider.notifier).updateBalance(newBalance);

      // İşlem başarılı! Şimdi sepeti boşalt.
      ref.read(cartProvider.notifier).clearCart();

      // API'den yeni siparişleri çekmesi için listeyi sıfırla
      ref.invalidate(myOrdersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Siparişiniz başarıyla alındı.'),
            backgroundColor: Colors.green,
          ),
        );
        // Siparişler sayfasına yönlendir
        context.go('/orders');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final totalAmount = ref.watch(cartProvider.notifier).totalAmount;
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Sepetim', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Sepetiniz şu an boş.', style: TextStyle(fontSize: 18, color: Colors.black54)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go('/menu');
              },
              child: const Text('Menüye Dön'),

            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sepetteki Ürünleri Listele
          ...cartItems.map((item) {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.fastfood, color: Colors.orange.shade400),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('₺${item.product.price.toStringAsFixed(2)}', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    // Miktar Ayarlama Butonları
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                          onPressed: () => ref.read(cartProvider.notifier).removeProduct(item.product.id),
                        ),
                        Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                          onPressed: () => ref.read(cartProvider.notifier).addProduct(item.product),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // YENİ: Sipariş Notu Alanı
          const Text(
            'Sipariş Notu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Örn: Tost bol kaşarlı olsun, ketçap olmasın.',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none, // Kenarlık yok, sadece gölge hissiyatı
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
              ),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.done,
          ),
          // Klavye açıldığında en altta kalmaması için ekstra boşluk
          const SizedBox(height: 40),
        ],
      ),

      // Alt Bar (Özet ve Onay)
      bottomNavigationBar: cartItems.isEmpty ? null : Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mevcut Bakiye:', style: TextStyle(color: Colors.black54, fontSize: 16)),
                  Text('₺${user?.balance.toStringAsFixed(2) ?? "0.00"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Toplam Tutar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('₺${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Siparişi Onayla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}