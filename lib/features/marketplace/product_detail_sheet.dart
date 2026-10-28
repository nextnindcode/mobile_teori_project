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

  // final Map<String, double> _rates = {
  //   'IDR': 1.0,
  //   'USD': 0.000063,
  //   'KRW': 0.085,
  //   'JPY': 0.0095,
  // };

  @override
  void initState() {
    super.initState();
    // Kalau dibuka dari keranjang, set Qty awal sesuai yang ada di cart (biasanya 1)
    // (Biar lebih akurat, kamu bisa passing quantity dari cart ke sini)
    _quantity = widget.initialQuantity;
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    try {
      final rates = await CurrencyService.fetchRates();
      if (mounted) {
        setState(() {
          _currencyRates = rates;
        });
      }
    } catch (e) {
      debugPrint('Gagal ambil kurs: $e');
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

  String _formatCurrency(double amount, String currency) {
    String symbol = '';
    int decimals = 0;
    if (currency == 'IDR')
      symbol = 'Rp ';
    else if (currency == 'USD') {
      symbol = '\$ ';
      decimals = 2;
    } else if (currency == 'KRW')
      symbol = '₩ ';
    else if (currency == 'JPY')
      symbol = '¥ ';

    final formatted = amount
        .toStringAsFixed(decimals)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '$symbol$formatted';
  }

  Future<Map<String, dynamic>?> _prosesBeliLangsung(
    Product product,
    int qty,
  ) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return {'error': 'User belum login'};

      // GUNAKAN RPC YANG SAMA DENGAN CART
      final response = await Supabase.instance.client
          .rpc(
            'checkout_merchandise',
            params: {
              'p_items': [
                {'product_id': product.id, 'quantity': qty},
              ],
            },
          )
          .timeout(const Duration(seconds: 15));

      final result = Map<String, dynamic>.from(response as Map);

      // Kembalikan order_id dari RPC agar notifikasi bisa muncul
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

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.deepSpace,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: product.imageUrl != null
                            ? Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.eclipseViolet.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.category.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.eclipseViolet,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          isOutOfStock
                              ? 'Stok habis'
                              : 'Tersedia: ${product.stock} pcs',
                          style: TextStyle(
                            color: isOutOfStock
                                ? AppTheme.error
                                : AppTheme.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          displayPrice,
                          style: const TextStyle(
                            color: AppTheme.coronaGold,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Row(
                          children: ['IDR', 'USD', 'KRW', 'JPY'].map((curr) {
                            final isSelected = _selectedCurrency == curr;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCurrency = curr),
                              child: Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.eclipseViolet
                                      : AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.eclipseViolet
                                        : AppTheme.borderSubtle,
                                  ),
                                ),
                                child: Text(
                                  curr,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description.isNotEmpty
                          ? product.description
                          : 'Tidak ada deskripsi.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: (_quantity > 1 && !_isProcessing)
                                  ? () {
                                      setState(() => _quantity--);
                                      // Panggil callback tiap qty berubah
                                      widget.onQuantityChanged?.call(_quantity);
                                    }
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.white,
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  (_quantity < product.stock && !_isProcessing)
                                  ? () {
                                      setState(() => _quantity++);
                                      // Panggil callback tiap qty berubah
                                      widget.onQuantityChanged?.call(_quantity);
                                    }
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                              color: Colors.white,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Subtotal',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              displayPrice,
                              style: const TextStyle(
                                color: AppTheme.coronaGold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (widget.isFromCart)
                      // Kalau dari keranjang, cuma nampilin tombol X (Tutup)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 20),
                          label: const Text(
                            'Tutup',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (isOutOfStock || _isProcessing)
                                  ? null
                                  : () async {
                                      final navigator = Navigator.of(context);
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      await LocalDb.addToCart(
                                        productId: product.id,
                                        name: product.name,
                                        price: product.price,
                                        quantity: _quantity,
                                      );
                                      if (!mounted) return;
                                      navigator.pop();
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Masuk ke keranjang!'),
                                        ),
                                      );
                                    },
                              icon: const Icon(
                                Icons.shopping_bag_outlined,
                                size: 18,
                              ),
                              label: const Text('Keranjang'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.eclipseViolet,
                                side: const BorderSide(
                                  color: AppTheme.eclipseViolet,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (isOutOfStock || _isProcessing)
                                  ? null
                                  : () async {
                                      setState(() => _isProcessing = true);
                                      final result = await _prosesBeliLangsung(
                                        product,
                                        _quantity,
                                      );
                                      if (!mounted) return;
                                      setState(() => _isProcessing = false);

                                      if (result == null ||
                                          result.containsKey('error')) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error: ${result?['error'] ?? 'Gagal'}',
                                            ),
                                            backgroundColor: AppTheme.error,
                                          ),
                                        );
                                      } else {
                                        final orderId = result['order_id'];
                                        await NotificationService.showOrderConfirmed(
                                          orderId,
                                        );
                                        await Future.delayed(
                                          const Duration(milliseconds: 500),
                                        );
                                        if (!mounted) return;

                                        final parentContext = Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).context;
                                        Navigator.pop(context);

                                        showDialog(
                                          context: parentContext,
                                          barrierDismissible: false,
                                          builder: (dialogContext) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              title: Row(
                                                children: [
                                                  const Expanded(
                                                    child: Text(
                                                      'Pembayaran Berhasil',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          dialogContext,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 60,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'Pesanan #$orderId berhasil dibuat.\nTerima kasih telah berbelanja!',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          AppTheme.primaryDark,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          dialogContext,
                                                        ),
                                                    child: const Text(
                                                      'OKE',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.eclipseViolet,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Beli Langsung',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
