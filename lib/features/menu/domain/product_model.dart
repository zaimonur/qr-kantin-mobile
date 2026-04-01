/// @file lib/features/menu/domain/product_model.dart
/// @description Ürün detayları, fiyat ve stok durumunu içeren veri modeli.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool isActive;
  final String imageUrl;
  final bool inStock; // YENİ: Akıllı stok durumunu tutacağımız alan

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.isActive,
    required this.imageUrl,
    required this.inStock, // YENİ
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      // Go'dan int veya double gelebilir, patlamaması için num kullanıyoruz
      price: (json['price'] as num).toDouble(),
      category: json['category'] ?? 'Atıştırmalık',
      isActive: json['is_active'] ?? true,
      imageUrl: json['image_url'] ?? '',
      inStock: json['in_stock'] ?? true, // YENİ: Backend'den gelen veri (Yoksa varsayılan true say)
    );
  }
}