import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/local_db.dart';
import '../../models/products.dart';
import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart';

class ProductDetailSheet extends StatefulWidget {
  final Product product;

  const ProductDetailSheet({super.key, required this.product});

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  String _selectedCurrency = 'IDR';
  double _convertedPrice = 0;
  bool _isAdding = false;

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

  Future<void> _fetchRates() async {
    try {
      final rows = await Supabase.instance.client.from('currency_rates')
          .select('target_code,rate')
          .eq('base_code', 'USD')
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        for (final row in rows) {
          final code = '${row['target_code']}';
          if (_rates.containsKey(code)) _rates[code] = (row['rate'] as num).toDouble();
        }
      });
    } catch (_) {}
  }

  void _convert(String currency) {
    setState(() {
      _selectedCurrency = currency;
      _convertedPrice =
          (widget.product.price / (_rates['IDR'] ?? 16250.0)) *
          (_rates[_selectedCurrency] ?? 1.0);
    });
  }

  Future<void> _addToCart() async {
    if (widget.product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maaf, stok produk ini sedang habis.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isAdding = true);
    await LocalDb.addToCart(
      productId: widget.product.id,
      name: widget.product.name,
      price: widget.product.price,
    );
    if (!mounted) return;
    setState(() => _isAdding = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} ditambahkan ke keranjang!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // 1. Gambar Produk
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CosmicNetworkImage(
                imageUrl: widget.product.imageUrl,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2. Kategori & Stok
          Row(
            children: [
              CosmicBadge(
                text: widget.product.category.toUpperCase(),
                color: AppTheme.coolCyan,
                textColor: AppTheme.coolCyan,
              ),
              const Spacer(),
              Icon(
                widget.product.stock > 0 ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 14,
                color: widget.product.stock > 0 ? AppTheme.success : AppTheme.error,
              ),
              const SizedBox(width: 4),
              Text(
                widget.product.stock > 0 ? 'Tersedia: ${widget.product.stock} pcs' : 'Stok habis',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.product.stock > 0 ? AppTheme.success : AppTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Nama Produk
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // 4. Harga Terpilih
          Text(
            _selectedCurrency == 'IDR'
                ? 'Rp ${widget.product.price}'
                : '$_selectedCurrency ${_convertedPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.coronaGold,
            ),
          ),
          const SizedBox(height: 10),

          // 5. Konversi Mata Uang Cepat
          Row(
            children: [
              const Text('Konversi:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(width: 8),
              ...['IDR', 'USD', 'KRW', 'JPY'].map((c) {
                final isSelected = _selectedCurrency == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => _convert(c),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.eclipseViolet : AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppTheme.eclipseViolet : AppTheme.borderSubtle,
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),

          // 6. Deskripsi
          const Text(
            'Deskripsi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.product.description.isEmpty ? 'Tidak ada deskripsi.' : widget.product.description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // 7. Tombol Masukkan Keranjang
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.product.stock > 0 ? AppTheme.eclipseViolet : AppTheme.surfaceSecondary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
            ),
            onPressed: widget.product.stock > 0 && !_isAdding ? _addToCart : null,
            icon: _isAdding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add_shopping_cart, size: 20),
            label: Text(
              widget.product.stock > 0 ? 'Tambah ke Keranjang' : 'Stok Tidak Tersedia',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
