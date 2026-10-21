import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../theme/app_theme.dart';
import '../../core/local_db.dart';
import '../../models/products.dart';

class ProductDetailSheet extends StatefulWidget {
  final Product product;

  const ProductDetailSheet({super.key, required this.product});

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  String _selectedCurrency = 'IDR';
  double _convertedPrice = 0;

  final Map<String, double> _rates = {
    'IDR': 16250.0,
    'USD': 1.0,
    'KRW': 1380.0,
    'JPY': 155.0,
  };

  @override
  void initState() {
    super.initState();
    _convertedPrice = widget.product.price.toDouble();
    _fetchRates();
  }

  // Ambil kurs dari API
  Future<void> _fetchRates() async {
    try {
      final res = await ApiService.get('/currency/rates?base=USD');
      if (res['success'] == true && res['data']['rates'] != null) {
        setState(() {
          final apiRates = res['data']['rates'];
          _rates['IDR'] = (apiRates['IDR'] as num).toDouble();
          _rates['USD'] = (apiRates['USD'] as num).toDouble();
          _rates['KRW'] = (apiRates['KRW'] as num).toDouble();
          _rates['JPY'] = (apiRates['JPY'] as num).toDouble();
        });
      }
    } catch (e) {
      // Kalau API error, biarin pakai rate default
    }
  }

  // Hitung harga konversi
  void _convert() {
    setState(() {
      _convertedPrice =
          (widget.product.price / (_rates['IDR'] ?? 16250.0)) *
          (_rates[_selectedCurrency] ?? 1.0);
    });
  }

  // Simpan ke Cart
  Future<void> _addToCart() async {
    await LocalDb.addToCart(
      productId: widget.product.id,
      name: widget.product.name,
      price: widget.product.price,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Berhasil ditambahkan ke keranjang!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. GAMBAR PRODUK
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child:
                  widget.product.imageUrl != null &&
                      widget.product.imageUrl!.isNotEmpty
                  ? Image.network(
                      widget.product.imageUrl!,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 200,
                      width: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 80),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. NAMA & HARGA
          Text(
            widget.product.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Rp ${widget.product.price}',
            style: const TextStyle(
              fontSize: 18,
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // 3. KOTAK KONVERSI
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCurrency,
                      isExpanded: true,
                      items: ['IDR', 'USD', 'KRW', 'JPY'].map((c) {
                        return DropdownMenuItem(value: c, child: Text('Ke $c'));
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCurrency = val!);
                        _convert();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _selectedCurrency == 'IDR'
                      ? 'Rp ${_convertedPrice.toStringAsFixed(0)}'
                      : '$_selectedCurrency ${_convertedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. TOMBOL TAMBAH KE KERANJANG
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _addToCart,
              icon: const Icon(Icons.shopping_cart),
              label: const Text(
                'Tambah ke Keranjang',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
