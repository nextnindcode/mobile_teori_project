import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/local_db.dart';
import '../../core/routes.dart';
import '../../theme/app_theme.dart';

class CartPage extends StatefulWidget {
  final bool previewMode;

  const CartPage({super.key, this.previewMode = false});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];
  int _totalPrice = 0;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final items = await LocalDb.getCart();
    final total = items.fold<int>(
      0,
      (sum, item) =>
          sum + ((item['price'] as num).toInt() * (item['quantity'] as num).toInt()),
    );
    if (!mounted) return;
    setState(() {
      _cartItems = items;
      _totalPrice = total;
    });
  }

  String _rupiah(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return 'Rp $buffer';
  }

  Future<void> _changeQuantity(int productId, int quantity) async {
    await LocalDb.updateQuantity(productId, quantity);
    await _loadCart();
  }

  Future<void> _checkout() async {
    if (widget.previewMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout aktif setelah backend dan database online disiapkan.')),
      );
      return;
    }
    if (_cartItems.isEmpty || _isCheckingOut) return;
    setState(() => _isCheckingOut = true);

    try {
      final response = await ApiService.post('/orders', {
        'items': _cartItems
            .map((item) => {
                  'product_id': item['product_id'],
                  'quantity': item['quantity'],
                })
            .toList(),
      });

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Checkout gagal.');
      }

      await LocalDb.clearCart();
      if (!mounted) return;
      await _loadCart();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pesanan #${response['data']?['order_id'] ?? '-'} berhasil dibuat.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pushReplacementNamed(context, Routes.orders);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout gagal. Keranjang tetap tersimpan.\n$e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          IconButton(
            tooltip: 'Riwayat pesanan',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.pushNamed(context, Routes.orders),
          ),
        ],
      ),
      body: _cartItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag_outlined,
                          size: 54, color: AppTheme.primaryDark),
                    ),
                    const SizedBox(height: 18),
                    Text('Keranjangmu masih kosong',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                      'Yuk, temukan merchandise EclipseVerse favoritmu.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(context, Routes.catalog),
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Jelajahi marketplace'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final id = (item['product_id'] as num).toInt();
                      final price = (item['price'] as num).toInt();
                      final quantity = (item['quantity'] as num).toInt();
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 68,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined,
                                  color: AppTheme.primaryDark, size: 28),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${item['name'] ?? 'Produk'}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 5),
                                  Text(_rupiah(price),
                                      style: const TextStyle(
                                          color: AppTheme.primaryDark,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _QuantityButton(
                                        icon: quantity == 1
                                            ? Icons.delete_outline
                                            : Icons.remove,
                                        onTap: () => _changeQuantity(id, quantity - 1),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 13),
                                        child: Text('$quantity',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800)),
                                      ),
                                      _QuantityButton(
                                        icon: Icons.add,
                                        onTap: () => _changeQuantity(id, quantity + 1),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_rupiah(price * quantity),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    decoration: const BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 14)],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total pesanan'),
                            Text(
                              _rupiah(_totalPrice),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.primaryDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isCheckingOut ? null : _checkout,
                            icon: _isCheckingOut
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.lock_outline),
                            label: Text(widget.previewMode
                                ? 'Checkout (mode preview)'
                                : _isCheckingOut
                                    ? 'Memproses pesanan...'
                                    : 'Checkout sekarang'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 17, color: AppTheme.primaryDark),
      ),
    );
  }
}
