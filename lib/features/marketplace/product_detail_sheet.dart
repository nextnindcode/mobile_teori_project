import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/local_db.dart';
import '../../models/products.dart';
import '../../theme/app_theme.dart';

class ProductDetailSheet extends StatefulWidget {
  final Product product;
  const ProductDetailSheet({super.key, required this.product});
  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  String _selectedCurrency = 'IDR';
  double _convertedPrice = 0;
  final Map<String, double> _rates = {'IDR': 1.0, 'USD': 0.000064, 'KRW': 0.088, 'JPY': 0.0095};

  @override
  void initState() { super.initState(); _convertedPrice = widget.product.price.toDouble(); _fetchRates(); }

  Future<void> _fetchRates() async {
    try {
      final res = await ApiService.get('/currency/rates?base=IDR');
      if (res['success'] == true && res['data'] is Map && res['data']['rates'] != null) {
        final apiRates = res['data']['rates'] as Map;
        if (apiRates['USD'] is num) _rates['USD'] = (apiRates['USD'] as num).toDouble();
        if (apiRates['KRW'] is num) _rates['KRW'] = (apiRates['KRW'] as num).toDouble();
        if (apiRates['JPY'] is num) _rates['JPY'] = (apiRates['JPY'] as num).toDouble();
        _convert();
      }
    } catch (_) {}
  }

  void _convert() {
    if (!mounted) return;
    setState(() => _convertedPrice = widget.product.price * (_rates[_selectedCurrency] ?? 1.0));
  }

  Future<void> _addToCart() async {
    await LocalDb.addToCart(productId: widget.product.id, name: widget.product.name, price: widget.product.price);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil ditambahkan ke keranjang!')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
            ? Image.network(widget.product.imageUrl!, height: 200, width: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80))
            : Container(height: 200, width: 200, color: AppTheme.background, child: const Icon(Icons.image, size: 80)))),
        const SizedBox(height: 24),
        Text(widget.product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Rp ${widget.product.price}', style: const TextStyle(fontSize: 18, color: AppTheme.primaryDark, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)), child: Row(children: [
          Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedCurrency, isExpanded: true, items: ['IDR','USD','KRW','JPY'].map((c) => DropdownMenuItem(value: c, child: Text('Ke $c'))).toList(), onChanged: (value) { if (value == null) return; setState(() => _selectedCurrency = value); _convert(); }))),
          const SizedBox(width: 16),
          Text(_selectedCurrency == 'IDR' ? 'Rp ${_convertedPrice.toStringAsFixed(0)}' : '$_selectedCurrency ${_convertedPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ])),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: _addToCart, icon: const Icon(Icons.shopping_cart), label: const Text('Tambah ke Keranjang'))),
      ]),
    );
  }
}
