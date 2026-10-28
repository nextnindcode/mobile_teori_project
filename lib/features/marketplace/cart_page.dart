import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/local_db.dart';
import '../../core/routes.dart';
import '../../theme/app_theme.dart';
import '../notification/notification_service.dart';
import '../../models/products.dart';
import '../marketplace/product_detail_sheet.dart';

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
  Set<int> _selectedIds = {};

  @override
  void initState() { super.initState(); _loadCart(); }

  Future<void> _loadCart() async {
    final items = await LocalDb.getCart();
    final productIds = items.map((e) => e['product_id']).toList();
    final stocks = <int, int>{};
    final imageUrls = <int, String?>{};
    if (productIds.isNotEmpty) {
      try {
        final res = await Supabase.instance.client.from('products').select('id, stock, cover_image_path').inFilter('id', productIds);
        for (var row in res) {
          final id = row['id'] as int;
          stocks[id] = (row['stock'] as num).toInt();
          final path = row['cover_image_path']?.toString();
          imageUrls[id] = path != null && path.isNotEmpty
              ? Supabase.instance.client.storage.from('eclipseverse-media').getPublicUrl(path)
              : null;
        }
      } catch (e) { debugPrint('Gagal ambil stok/gambar: $e'); }
    }
    final updatedItems = items.map((item) {
      final id = (item['product_id'] as num).toInt();
      return {...item, 'stock': stocks[id] ?? 0, 'image_url': imageUrls[id]};
    }).toList();
    if (!mounted) return;
    setState(() {
      _cartItems = updatedItems;
      final currentIds = updatedItems.map((e) => (e['product_id'] as num).toInt()).toSet();
      _selectedIds = _selectedIds.intersection(currentIds);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _totalPrice = _cartItems.fold(0, (total, item) {
      final id = (item['product_id'] as num).toInt();
      return _selectedIds.contains(id)
          ? total + (item['price'] as num).toInt() * (item['quantity'] as num).toInt()
          : total;
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
    final itemsToCheckout = _cartItems.where((item) => _selectedIds.contains((item['product_id'] as num).toInt())).toList();
    if (itemsToCheckout.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 barang untuk di-checkout!')));
      return;
    }
    if (widget.previewMode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil! Pesanan telah selesai.'), backgroundColor: Colors.green));
      return;
    }
    if (_isCheckingOut) return;
    setState(() => _isCheckingOut = true);
    try {
      final response = await Supabase.instance.client.rpc('checkout_merchandise', params: {
        'p_items': itemsToCheckout.map((item) => {'product_id': item['product_id'], 'quantity': item['quantity']}).toList(),
      }).timeout(const Duration(seconds: 15));
      final result = Map<String, dynamic>.from(response as Map);
      final orderId = result['order_id'] ?? 0;
      await NotificationService.showOrderConfirmed(orderId);
      for (var item in itemsToCheckout) { await LocalDb.updateQuantity((item['product_id'] as num).toInt(), 0); }
      if (!mounted) return;
      await _loadCart();
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Expanded(child: Text('Pembayaran Berhasil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dialogContext)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text('Pesanan #$orderId berhasil dibuat.\nTerima kasih telah berbelanja!', textAlign: TextAlign.center),
          ]),
          actions: [
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDark),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OKE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout gagal. Keranjang tetap tersimpan.\n$e'), backgroundColor: Colors.red.shade700));
    } finally { if (mounted) setState(() => _isCheckingOut = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [IconButton(tooltip: 'Riwayat pesanan', icon: const Icon(Icons.receipt_long_outlined), onPressed: () => Navigator.pushNamed(context, Routes.orders))],
      ),
      body: _cartItems.isEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: AppTheme.primaryLight.withValues(alpha: .35), shape: BoxShape.circle), child: const Icon(Icons.shopping_bag_outlined, size: 54, color: AppTheme.primaryDark)),
              const SizedBox(height: 18),
              Text('Keranjangmu masih kosong', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Yuk, temukan merchandise EclipseVerse favoritmu.', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(onPressed: () => Navigator.pushNamed(context, Routes.catalog), icon: const Icon(Icons.storefront_outlined), label: const Text('Jelajahi marketplace')),
            ])))
          : Column(children: [
              Expanded(child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _cartItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _cartItems[index];
                  final id = (item['product_id'] as num).toInt();
                  final price = (item['price'] as num).toInt();
                  final quantity = (item['quantity'] as num).toInt();
                  final isSelected = _selectedIds.contains(id);
                  final imageUrl = item['image_url'] as String?;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      final product = Product(id: id, name: '${item['name'] ?? 'Produk'}', category: 'Merchandise', description: '', price: price, stock: (item['stock'] as num?)?.toInt() ?? 0, imageUrl: imageUrl);
                      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => ProductDetailSheet(product: product, isFromCart: true, initialQuantity: quantity, onQuantityChanged: (newQty) { _changeQuantity(id, newQty); }));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? AppTheme.primaryDark : AppTheme.borderSubtle, width: isSelected ? 2 : 1)),
                      child: Row(children: [
                        Container(margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(border: Border.all(color: AppTheme.primaryDark, width: 1.5), borderRadius: BorderRadius.circular(6)), child: SizedBox(width: 24, height: 24, child: Checkbox(value: isSelected, activeColor: AppTheme.primaryDark, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, side: BorderSide.none, onChanged: (val) { setState(() { if (val == true) { _selectedIds.add(id); } else { _selectedIds.remove(id); } _calculateTotal(); }); }))),
                        const SizedBox(width: 4),
                        ClipRRect(borderRadius: BorderRadius.circular(14), child: Container(width: 60, height: 60, decoration: BoxDecoration(color: AppTheme.primaryLight.withValues(alpha: .35)), child: imageUrl != null ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryDark)) : const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryDark))),
                        const SizedBox(width: 13),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${item['name'] ?? 'Produk'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          const SizedBox(height: 5),
                          Text(_rupiah(price), style: const TextStyle(color: AppTheme.coronaGold, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            _QuantityButton(icon: quantity == 1 ? Icons.delete_outline : Icons.remove, onTap: () => _changeQuantity(id, quantity - 1)),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 13), child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary))),
                            _QuantityButton(icon: Icons.add, isDisabled: quantity >= ((item['stock'] as num?)?.toInt() ?? 0), onTap: () {
                              final maxStock = (item['stock'] as num?)?.toInt() ?? 0;
                              if (quantity >= maxStock) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stok maksimal hanya $maxStock'))); return; }
                              _changeQuantity(id, quantity + 1);
                            }),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            'Subtotal: ${_rupiah(price * quantity)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.coronaGold),
                          ),
                        ])),
                      ]),
                    ),
                  );
                },
              )),
              SafeArea(top: false, child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 14)]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total pesanan', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                    Text(_rupiah(_totalPrice), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    onPressed: _isCheckingOut ? null : () { if (_selectedIds.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 barang untuk di-checkout!'), backgroundColor: Colors.red)); return; } _checkout(); },
                    style: ElevatedButton.styleFrom(backgroundColor: _selectedIds.isEmpty ? Colors.grey.shade400 : AppTheme.primaryDark, foregroundColor: Colors.white),
                    icon: _isCheckingOut ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.payment_outlined),
                    label: Text(widget.previewMode ? 'Checkout (mode preview)' : _isCheckingOut ? 'Memproses pesanan...' : 'Checkout sekarang'),
                  )),
                ]),
              )),
            ]),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDisabled;
  const _QuantityButton({required this.icon, required this.onTap, this.isDisabled = false});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: isDisabled ? null : onTap, borderRadius: BorderRadius.circular(9), child: Container(width: 30, height: 30, decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade300 : AppTheme.primaryLight.withValues(alpha: .35), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 17, color: isDisabled ? Colors.grey : AppTheme.primaryDark)));
  }
}
