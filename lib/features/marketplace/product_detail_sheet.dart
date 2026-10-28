import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/products.dart';
import '../../theme/app_theme.dart';
import '../../core/local_db.dart';
import '../notification/notification_service.dart';
import '../tools/currency_service.dart';

class ProductDetailSheet extends StatefulWidget {
  final Product product;
  final bool isFromCart;
  final int initialQuantity;
  final Function(int newQty)? onQuantityChanged;

  const ProductDetailSheet({
    super.key,
    required this.product,
    this.isFromCart = false,
    this.initialQuantity = 1,
    this.onQuantityChanged,
  });

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  int _quantity = 1;
  bool _isProcessing = false;
  String _selectedCurrency = 'IDR';
  CurrencyRates? _currencyRates;
  bool _loadingRates = true;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _loadCurrencyRates();
  }

  Future<void> _loadCurrencyRates() async {
    try {
      final rates = await CurrencyService.fetchRates();
      if (!mounted) return;
      setState(() {
        _currencyRates = rates;
        _loadingRates = false;
        if (!CurrencyService.codesFor(rates).contains(_selectedCurrency)) {
          _selectedCurrency = 'IDR';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRates = false);
    }
  }

  String _formatRupiah(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return 'Rp $buffer';
  }

  String _formatDisplayPrice(int amountIdr) {
    if (_selectedCurrency == 'IDR' || _currencyRates == null) {
      return _formatRupiah(amountIdr);
    }
    try {
      final converted = _currencyRates!.convert(amountIdr.toDouble(), 'IDR', _selectedCurrency);
      return '${CurrencyService.flag(_selectedCurrency)} $_selectedCurrency ${CurrencyService.format(_selectedCurrency, converted)}';
    } catch (_) {
      return 'Kurs belum tersedia';
    }
  }

  Future<Map<String, dynamic>?> _prosesBeliLangsung(Product product, int qty) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return {'error': 'User belum login'};
      final response = await Supabase.instance.client.rpc(
        'checkout_merchandise',
        params: {'p_items': [{'product_id': product.id, 'quantity': qty}]},
      ).timeout(const Duration(seconds: 15));
      final result = Map<String, dynamic>.from(response as Map);
      return {'order_id': result['order_id']};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isOutOfStock = product.stock <= 0;
    final totalPriceIDR = product.price * _quantity;
    double convertedPrice = totalPriceIDR.toDouble();
    if (_currencyRates != null) {
      try {
        convertedPrice = _currencyRates!.convert(
          totalPriceIDR.toDouble(),
          'IDR',
          _selectedCurrency,
        );
      } catch (e) {
        _selectedCurrency = 'IDR';
      }
    }

    final displayPrice = _selectedCurrency == 'IDR'
        ? _formatRupiah(totalPriceIDR)
        : _formatCurrency(convertedPrice, _selectedCurrency);
    // final convertedPrice =
    //     totalPriceIDR.toDouble() * (_rates[_selectedCurrency] ?? 1.0);
    // final displayPrice = _selectedCurrency == 'IDR'
    //     ? _formatRupiah(totalPriceIDR)
    //     : _formatCurrency(convertedPrice, _selectedCurrency);
    final availableCodes = _currencyRates == null ? <String>[] : CurrencyService.codesFor(_currencyRates!);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.deepSpace,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: product.imageUrl != null
                            ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                            : Container(color: AppTheme.surfaceSecondary, child: const Icon(Icons.image_outlined, color: AppTheme.textSecondary, size: 48)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.eclipseViolet.withValues(alpha: .2), borderRadius: BorderRadius.circular(8)),
                        child: Text(product.category.toUpperCase(), style: const TextStyle(color: AppTheme.eclipseViolet, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      Text(isOutOfStock ? 'Stok habis' : 'Tersedia: ${product.stock} pcs', style: TextStyle(color: isOutOfStock ? AppTheme.error : AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 12),
                    Text(product.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Expanded(child: Text(_formatDisplayPrice(totalPriceIDR), style: const TextStyle(color: AppTheme.coronaGold, fontSize: 21, fontWeight: FontWeight.w900))),
                      if (_loadingRates)
                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.coolCyan))
                      else if (availableCodes.isNotEmpty)
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: availableCodes.contains(_selectedCurrency) ? _selectedCurrency : availableCodes.first,
                            dropdownColor: AppTheme.surfaceElevated,
                            iconEnabledColor: AppTheme.coolCyan,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            items: availableCodes.map((code) => DropdownMenuItem(value: code, child: Text('${CurrencyService.flag(code)} $code'))).toList(),
                            onChanged: (value) { if (value != null) setState(() => _selectedCurrency = value); },
                          ),
                        )
                      else
                        const Text('Kurs belum tersedia', style: TextStyle(color: AppTheme.error, fontSize: 11)),
                    ]),
                    const SizedBox(height: 8),
                    const Text('Harga mengikuti jumlah item di bawah. Kurs diambil dari layanan currency aplikasi.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 16),
                    const Text('Deskripsi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(product.description.isNotEmpty ? product.description : 'Tidak ada deskripsi.', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 20),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: BoxDecoration(color: AppTheme.surfaceElevated, border: Border(top: BorderSide(color: AppTheme.borderSubtle))),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(children: [
                        IconButton(onPressed: _quantity > 1 && !_isProcessing ? () { setState(() => _quantity--); widget.onQuantityChanged?.call(_quantity); } : null, icon: const Icon(Icons.remove_circle_outline), color: Colors.white),
                        Text('$_quantity', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: _quantity < product.stock && !_isProcessing ? () { setState(() => _quantity++); widget.onQuantityChanged?.call(_quantity); } : null, icon: const Icon(Icons.add_circle_outline), color: Colors.white),
                      ]),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        const Text('Subtotal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text(_formatDisplayPrice(totalPriceIDR), style: const TextStyle(color: AppTheme.coronaGold, fontSize: 18, fontWeight: FontWeight.bold)),
                      ]),
                    ]),
                    const SizedBox(height: 16),
                    if (widget.isFromCart)
                      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20), label: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))))
                    else
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: isOutOfStock || _isProcessing ? null : () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            await LocalDb.addToCart(productId: product.id, name: product.name, price: product.price, quantity: _quantity);
                            if (!mounted) return;
                            navigator.pop();
                            messenger.showSnackBar(const SnackBar(content: Text('Masuk ke keranjang!')));
                          },
                          icon: const Icon(Icons.shopping_bag_outlined, size: 18), label: const Text('Keranjang'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.eclipseViolet, side: const BorderSide(color: AppTheme.eclipseViolet), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: ElevatedButton(
                          onPressed: isOutOfStock || _isProcessing ? null : () async {
                            setState(() => _isProcessing = true);
                            final result = await _prosesBeliLangsung(product, _quantity);
                            if (!mounted) return;
                            setState(() => _isProcessing = false);
                            if (result == null || result.containsKey('error')) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result?['error'] ?? 'Gagal'}'), backgroundColor: AppTheme.error));
                            } else {
                              final orderId = result['order_id'];
                              await NotificationService.showOrderConfirmed(orderId);
                              if (!mounted) return;
                              final parentContext = Navigator.of(context, rootNavigator: true).context;
                              Navigator.pop(context);
                              showDialog(context: parentContext, barrierDismissible: false, builder: (dialogContext) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Row(children: [const Expanded(child: Text('Pembayaran Berhasil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dialogContext))]),
                                content: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 60), const SizedBox(height: 16), Text('Pesanan #$orderId berhasil dibuat.\nTerima kasih telah berbelanja!', textAlign: TextAlign.center)]),
                                actions: [SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDark), onPressed: () => Navigator.pop(dialogContext), child: const Text('OKE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))],
                              ));
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.eclipseViolet, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Beli Langsung', style: TextStyle(fontWeight: FontWeight.bold)),
                        )),
                      ]),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
