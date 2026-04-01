/// @file lib/features/wallet/presentation/wallet_screen.dart
/// @description Bakiye yükleme, işlem geçmişi ve dijital cüzdan yönetim arayüzü.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/network/dio_client.dart';

final walletHistoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioClientProvider).dio;
  final response = await dio.get('/api/wallet/history');
  return response.data as List<dynamic>;
});

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  int _currentPage = 0;
  final int _itemsPerPage = 5;

  Future<void> _loadBalance() async {
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir tutar giriniz!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.post('/api/wallet/load', data: {'amount': amount});

      final newBalance = (response.data['new_balance'] as num).toDouble();
      ref.read(authProvider.notifier).updateBalance(newBalance);

      ref.invalidate(walletHistoryProvider);
      setState(() => _currentPage = 0);

      if (mounted) {
        _amountController.clear();
        FocusScope.of(context).unfocus();

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Bakiye başarıyla yüklendi!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yükleme başarısız!'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Widget> _buildHistorySlivers(List<dynamic> transactions) {
    if (transactions.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(child: Text('Henüz işlem geçmişiniz yok.', style: TextStyle(color: Colors.grey.shade500))),
          ),
        )
      ];
    }

    int totalPages = (transactions.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages) _currentPage = totalPages - 1;

    int startIndex = _currentPage * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > transactions.length) endIndex = transactions.length;

    List paginatedTx = transactions.sublist(startIndex, endIndex);

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final tx = paginatedTx[index];
            final isLoad = tx['type'] == 'load';
            final isRefund = tx['type'] == 'refund';
            final amount = (tx['amount'] as num).toDouble();

            String sourceText = 'Uygulama İçi';
            if (tx['source'] == 'admin_panel') sourceText = 'Kantin Kasasından';
            if (tx['source'] == 'order_system') sourceText = 'Kantin Harcaması';

            Color iconColor = isLoad || isRefund ? Colors.green : Colors.orange;
            IconData iconData = isLoad ? Icons.arrow_downward_rounded :
            isRefund ? Icons.keyboard_return_rounded : Icons.shopping_cart_outlined;
            String titleText = isLoad ? 'Bakiye Yüklendi' :
            isRefund ? 'İade Alındı' : 'Kantin Harcaması';

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(iconData, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(tx['created_at'].toString(), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            const SizedBox(width: 8),
                            Expanded(child: Text('• $sourceText', style: TextStyle(color: Colors.blue.shade300, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isLoad || isRefund ? "+" : "-"}₺${amount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isLoad || isRefund ? Colors.green.shade700 : Colors.black87),
                  ),
                ],
              ),
            );
          },
          childCount: paginatedTx.length,
        ),
      ),

      if (totalPages > 1)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                ),
                Text(
                  'Sayfa ${_currentPage + 1} / $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                ),
                ElevatedButton(
                  onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final historyAsyncValue = ref.watch(walletHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Cüzdanım', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade500, Colors.green.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                        ]),
                    child: Column(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 48),
                        const SizedBox(height: 16),
                        const Text('Mevcut Bakiye', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text(
                          '₺${user?.balance.toStringAsFixed(2) ?? "0.00"}',
                          style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text('Bakiye Yükle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Yüklenecek Tutar',
                      hintText: 'Örn: 100.00',
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.green, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _loadBalance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Text('Cüzdanı Doldur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // REVİZE: Altındaki 16px'lik boşluk tamamen kaldırıldı ve buton tekrar köşeye alındı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('İşlem Geçmişi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      IconButton(
                        onPressed: () => ref.invalidate(walletHistoryProvider),
                        icon: const Icon(Icons.refresh, color: Colors.black87),
                        tooltip: 'Geçmişi Yenile',
                      ),
                    ],
                  ),
                  // Tasarım gereği ilgili boşluk kaldırıldı.
                ],
              ),
            ),
          ),

          if (historyAsyncValue.isLoading)
            const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
          else if (historyAsyncValue.hasError)
            SliverToBoxAdapter(child: Center(child: Text('Hata: ${historyAsyncValue.error}')))
          else if (historyAsyncValue.value != null)
              ..._buildHistorySlivers(historyAsyncValue.value!),

          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}