/// @file lib/features/order/presentation/order_tracking_screen.dart
/// @description Aktif ve geçmiş siparişlerin QR kod ile takip edildiği kullanıcı arayüzü.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'order_tracking_provider.dart';
import '../domain/order_model.dart';
import '../../auth/presentation/auth_provider.dart';

final expandedOrdersProvider = StateProvider<Map<String, bool>>((ref) => {});

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(orderWebSocketProvider);
    final ordersAsyncValue = ref.watch(myOrdersProvider);
    final user = ref.watch(authProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Siparişlerim', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(text: 'Aktif Siparişler'),
              Tab(text: 'Geçmiş'),
            ],
          ),
        ),
        body: ordersAsyncValue.when(
          data: (orders) {
            final activeOrders = orders.where((o) => ['pending', 'approved', 'ready'].contains(o.status)).toList();
            final pastOrders = orders.where((o) => ['completed', 'cancelled'].contains(o.status)).toList();

            return TabBarView(
              children: [
                _buildOrderList(activeOrders, ref, user?.fullName ?? 'Bilinmeyen Öğrenci', isEmptyText: 'Aktif siparişiniz bulunmuyor.'),
                _buildOrderList(pastOrders, ref, user?.fullName ?? 'Bilinmeyen Öğrenci', isEmptyText: 'Geçmiş siparişiniz bulunmuyor.'),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Hata: $error')),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, WidgetRef ref, String userName, {required String isEmptyText}) {
    if (orders.isEmpty) {
      return Center(child: Text(isEmptyText, style: const TextStyle(fontSize: 16, color: Colors.black54)));
    }
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myOrdersProvider.future),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final isExpanded = ref.watch(expandedOrdersProvider)[order.id] ?? false;
          return _buildExpandableOrderCard(context, ref, order, isExpanded, userName);
        },
      ),
    );
  }

  Widget _buildExpandableOrderCard(BuildContext context, WidgetRef ref, OrderModel order, bool isExpanded, String userName) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (order.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Kantinci Onay Bekliyor';
        statusIcon = Icons.access_time_filled;
        break;
      case 'approved':
        statusColor = Colors.blue;
        statusText = 'Hazırlanıyor';
        statusIcon = Icons.soup_kitchen;
        break;
      case 'ready':
        statusColor = Colors.green;
        statusText = 'Teslimata Hazır (QR)';
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'İptal Edildi (İade Yapıldı)';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Teslim Edildi';
        statusIcon = Icons.inventory_2;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          final currentMap = ref.read(expandedOrdersProvider);
          ref.read(expandedOrdersProvider.notifier).state = {
            ...currentMap,
            order.id: !isExpanded,
          };
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                userName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tutar: ₺${order.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              statusText,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: isExpanded ? null : 0,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 8),
                        child: Divider(),
                      ),

                      // Siparişin oluşturulma zamanı.
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 16, color: Colors.blue.shade600),
                          const SizedBox(width: 6),
                          Text(
                            'Sipariş Zamanı: ${order.createdAt}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Sipariş Detayı:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.items.length,
                        itemBuilder: (context, iIndex) {
                          final item = order.items[iIndex];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  flex: 3,
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Flexible(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'x${item.quantity}',
                                        style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₺${(item.price * item.quantity).toStringAsFixed(2)}',
                                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w800, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      if (order.note.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.speaker_notes, size: 20, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Özel Not: ${order.note}',
                                  style: TextStyle(color: Colors.orange.shade900, fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (order.status == 'ready') ...[
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.shade200, width: 2),
                              boxShadow: [
                                BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
                              ],
                            ),
                            child: QrImageView(
                              data: order.qrCodeToken,
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}