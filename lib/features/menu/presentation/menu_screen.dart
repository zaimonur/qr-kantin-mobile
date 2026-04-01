/// @file lib/features/menu/presentation/menu_screen.dart
/// @description Kategorize edilmiş ürün listesi, akıllı stok takibi ve arama arayüzü.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'menu_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../order/presentation/cart_provider.dart';
import '../domain/product_model.dart';

final menuSearchQueryProvider = StateProvider<String>((ref) => '');

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsyncValue = ref.watch(menuListProvider);
    final user = ref.watch(authProvider);
    final searchQuery = ref.watch(menuSearchQueryProvider).toLowerCase();

    // Cihazın güvenli alan (safe area) üst boşluk değeri hesaplanır.
    final topPadding = MediaQuery.of(context).padding.top;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverPersistentHeader(
                pinned: true,
                delegate: _KantinMenuHeaderDelegate(
                  // ref'i de içeriye gönderiyoruz ki logout çalışsın
                  topBar: _buildTopBar(context, ref, user),
                  searchBar: _buildSearchBar(ref),
                  tabBar: _buildTabBar(),
                  // Değerler
                  topPadding: topPadding, // YENİ
                  topBarHeight: 60.0,
                  searchBarHeight: 65.0,
                  tabBarHeight: 50.0,
                ),
              ),
            ];
          },
          body: menuAsyncValue.when(
            data: (products) {
              if (products.isEmpty) {
                return _buildEmptyState('Menüde henüz ürün yok.');
              }

              final filteredProducts = products.where((p) => p.name.toLowerCase().contains(searchQuery)).toList();

              // Akıllı Sıralama (Tükendi en alta, gerisi A-Z)
              filteredProducts.sort((a, b) {
                if (a.inStock && !b.inStock) return -1;
                if (!a.inStock && b.inStock) return 1;
                return a.name.compareTo(b.name);
              });

              final yemekler = filteredProducts.where((p) => p.category == 'Yemek').toList();
              final atistirmaliklar = filteredProducts.where((p) => p.category == 'Atıştırmalık').toList();
              final icecekler = filteredProducts.where((p) => p.category == 'İçecek').toList();

              return TabBarView(
                children: [
                  _buildProductGrid(yemekler, ref),
                  _buildProductGrid(atistirmaliklar, ref),
                  _buildProductGrid(icecekler, ref),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Hata: $error')),
          ),
        ),
      ),
    );
  }

  // --- Yardımcı Widgetlar ---

  Widget _buildTopBar(BuildContext context, WidgetRef ref, dynamic user) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'QR Kantin',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Text(
                      '₺${user?.balance.toStringAsFixed(2) ?? "0.00"}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.black54, size: 22),
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
      child: TextField(
        onChanged: (value) => ref.read(menuSearchQueryProvider.notifier).state = value,
        decoration: InputDecoration(
          hintText: 'Menüde ürün ara...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent, size: 20),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return const TabBar(
      labelColor: Colors.blueAccent,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.blueAccent,
      indicatorWeight: 3,
      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      tabs: [
        Tab(text: 'Yemekler', icon: Icon(Icons.lunch_dining, size: 20)),
        Tab(text: 'Atıştırmalıklar', icon: Icon(Icons.cookie, size: 20)),
        Tab(text: 'İçecekler', icon: Icon(Icons.local_drink, size: 20)),
      ],
    );
  }

  Widget _buildProductGrid(List<Product> categoryProducts, WidgetRef ref) {
    if (categoryProducts.isEmpty) {
      return _buildEmptyState('Aradığınız ürün bulunamadı.');
    }
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(menuListProvider.future),
      color: Colors.blueAccent,
      backgroundColor: Colors.white,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 0.75,
        ),
        itemCount: categoryProducts.length,
        itemBuilder: (context, index) {
          final product = categoryProducts[index];
          IconData categoryIcon = Icons.fastfood_rounded;
          Color iconColor = Colors.orange.shade400;
          Color bgColor = Colors.orange.shade50;

          if (product.category == 'İçecek') {
            categoryIcon = Icons.local_drink;
            iconColor = Colors.blue.shade400;
            bgColor = Colors.blue.shade50;
          } else if (product.category == 'Yemek') {
            categoryIcon = Icons.lunch_dining;
            iconColor = Colors.red.shade400;
            bgColor = Colors.red.shade50;
          }

          return Opacity(
            opacity: product.inStock ? 1.0 : 0.6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: product.inStock ? bgColor : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(categoryIcon, size: 30, color: product.inStock ? iconColor : Colors.grey.shade400),
                    ),
                    Column(
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: product.inStock ? Colors.black87 : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₺${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: product.inStock ? Colors.blue.shade700 : Colors.grey.shade500,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            decoration: product.inStock ? TextDecoration.none : TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: product.inStock
                            ? () {
                          ref.read(cartProvider.notifier).addProduct(product);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} sepete eklendi!'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green.shade600,
                            ),
                          );
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: product.inStock ? Colors.black87 : Colors.grey.shade300,
                          foregroundColor: product.inStock ? Colors.white : Colors.grey.shade500,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          product.inStock ? 'Ekle' : 'Tükendi',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Delegate Çözümü (Pixel-Perfect) ---

class _KantinMenuHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget topBar;
  final Widget searchBar;
  final PreferredSizeWidget tabBar;

  final double topPadding; // Telefonun üst boşluğu (Saat/Çentik)
  final double topBarHeight;
  final double searchBarHeight;
  final double tabBarHeight;

  _KantinMenuHeaderDelegate({
    required this.topBar,
    required this.searchBar,
    required this.tabBar,
    required this.topPadding,
    required this.topBarHeight,
    required this.searchBarHeight,
    required this.tabBarHeight,
  });

  @override
  double get minExtent => topPadding + topBarHeight; // Sadece sabit alan kalacak

  @override
  double get maxExtent => topPadding + topBarHeight + searchBarHeight + tabBarHeight; // Tamamı

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final shrinkFactor = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return Material(
      color: Colors.white,
      elevation: shrinkFactor > 0.9 ? 2 : 0, // Tam kapandığında hafif gölge
      child: Stack(
        children: [
          // 1. KISIM: Sabit Üst Bar (En Üstteki Beyaz Alan)
          // Background beyazı her zaman topPadding + topBarHeight kadar alanı kaplasın
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding + topBarHeight,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.only(top: topPadding), // İçerik saat altına girmesin!
              alignment: Alignment.center,
              child: topBar,
            ),
          ),

          // 2. KISIM: Kaybolan Arama Çubuğu
          Positioned(
            top: topPadding + topBarHeight,
            left: 0,
            right: 0,
            height: searchBarHeight,
            child: Opacity(
              opacity: (1.0 - shrinkFactor * 2).clamp(0.0, 1.0), // Daha hızlı kaybolsun
              child: Transform.translate(
                offset: Offset(0, -shrinkOffset), // Kaydırma (scroll) miktarına göre arama çubuğunun konumunu günceller.
                child: searchBar,
              ),
            ),
          ),

          // 3. KISIM: Kaybolan Sekmeler (TabBar)
          Positioned(
            top: topPadding + topBarHeight + searchBarHeight,
            left: 0,
            right: 0,
            height: tabBarHeight,
            child: Opacity(
              opacity: (1.0 - shrinkFactor * 2).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -shrinkOffset),
                child: tabBar,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _KantinMenuHeaderDelegate oldDelegate) => true;
}