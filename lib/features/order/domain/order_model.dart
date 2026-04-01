/// @file lib/features/order/domain/order_model.dart
/// @description Sipariş detayları, ürün kalemleri ve durum takibi için veri modeli.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

// İÇERİDEKİ ÜRÜN MODELİ
class OrderItemModel {
  final String productName;
  final int quantity;
  final double price; // Satın alma anındaki fiyat

  OrderItemModel({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productName: json['product_name'] ?? 'Bilinmeyen Ürün',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ANA SİPARİŞ MODELİ (GÜNCELLENDİ)
class OrderModel {
  final String id;
  final double totalPrice;
  final String status;
  final String note;
  final String qrCodeToken;
  final String createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.totalPrice,
    required this.status,
    required this.note,
    required this.qrCodeToken,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Items listesini parse ediyoruz
    var list = json['items'] as List? ?? [];
    List<OrderItemModel> itemsList = list.map((i) => OrderItemModel.fromJson(i)).toList();

    return OrderModel(
      id: json['id'],
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'],
      note: json['note'] ?? '',
      qrCodeToken: json['qr_code_token'] ?? '',
      createdAt: json['created_at'] ?? '',
      items: itemsList,
    );
  }
}