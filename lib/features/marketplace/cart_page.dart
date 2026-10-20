import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/local_db.dart';
import '../../core/routes.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

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

  Future<void> _checkout() async {
    if (_cartItems.isEmpty || _isCheckingOut) return;
    setState(() => _isCheckingOut = true);

    try {
      // Kirim pesanan terlebih dahulu. Keranjang hanya dikosongkan jika API sukses.
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
      appBar: AppBar(title: const Text('Keranjang')),
      body: _cartItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        size: 68, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('Keranjangmu masih kosong',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    const Text('Yuk, temukan merchandise EclipseVerse favoritmu.',
                        textAlign: TextAlign.center),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final price = (item['price'] as num).toInt();
                      final quantity = (item['quantity'] as num).toInt();
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.10),
                            child: Icon(Icons.shopping_bag_outlined,
                                color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text('${item['name'] ?? 'Produk'}',
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Rp $price × $quantity'),
                          trailing: Text(
                            'Rp ${price * quantity}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 14),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total pesanan'),
                            Text(
                              'Rp $_totalPrice',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.lock_outline),
                            label: Text(_isCheckingOut
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
