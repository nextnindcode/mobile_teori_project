import 'package:flutter/material.dart';

import '../../core/local_db.dart';
import '../../core/routes.dart';
import '../../core/api_service.dart';
import '../../core/local_db.dart';

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
    int total = 0;
    for (var item in items) {
      total += (item['price'] as int) * (item['quantity'] as int);
    }
    for (final item in items) {
      total += (item['price'] as int) * (item['quantity'] as int);
    }
    if (!mounted) return;
    setState(() {
      _cartItems = items;
      _totalPrice = total;
    });
  }

  Future<void> _checkout() async {
    // TODO: Panggil API POST /orders di sini nanti
    await LocalDb.clearCart();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pesanan berhasil dibuat!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushReplacementNamed(context, Routes.orders);
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
            'Checkout berhasil! Pesanan #${response['data']?['order_id'] ?? '-'} tersimpan.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout gagal: $e')),
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
          ? const Center(child: Text('Keranjang masih kosong'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return ListTile(
                        leading: const Icon(Icons.shopping_bag),
                        title: Text(item['name']),
                        subtitle: Text(
                          'Rp ${item['price']} x ${item['quantity']}',
                        ),
                        trailing: Text(
                          'Rp ${(item['price'] as int) * (item['quantity'] as int)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 16)),
                          Text(
                            'Rp $_totalPrice',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _checkout,
                          child: const Text(
                            'Bayar Sekarang',
                            style: TextStyle(fontSize: 16),
                          ),
                          onPressed: _isCheckingOut ? null : _checkout,
                          child: _isCheckingOut
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Bayar Sekarang',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
