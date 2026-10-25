import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../membership/membership_service.dart';
import '../../core/routes.dart';
import '../../core/local_db.dart';
import '../../models/products.dart';
import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart';
import '../tools/currency_service.dart';

class CatalogPage extends StatefulWidget {
  final bool previewMode;

  const CatalogPage({super.key, this.previewMode = false});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _search = '';
  String _category = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  static const Map<String, String> _categories = {
    'Semua': '',
    'Album': 'album',
    'Apparel': 'apparel',
    'Aksesoris': 'accessory',
    'Koleksi': 'collectible',
  };

  List<Product> get _filteredProducts {
    final query = _search.trim().toLowerCase();
    final filtered = _products.where((product) {
      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
      final selectedCategory = _categories[_category] ?? '';
      final matchesCategory =
          selectedCategory.isEmpty ||
          product.category.toLowerCase() == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    filtered.sort((a, b) {
      final aOut = a.stock <= 0 ? 1 : 0;
      final bOut = b.stock <= 0 ? 1 : 0;
      return aOut.compareTo(bOut);
    });

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.previewMode) {
      setState(() {
        _products = [
          Product(
            id: 101,
            name: 'Eclipse: First Light Album',
            category: 'album',
            description: 'Album debut EclipseVerse dengan photobook dan collectible card.',
            price: 189000,
            stock: 25,
            imageUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500',
          ),
          Product(
            id: 102,
            name: 'Lunar Wave Hoodie',
            category: 'apparel',
            description: 'Hoodie nyaman dengan desain Lunar Wave.',
            price: 325000,
            stock: 12,
            imageUrl: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?q=80&w=500',
          ),
        ];
        _isLoading = false;
      });
      return;
    }

    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select(
            'id,name,description,price_idr,stock,cover_image_path,categories!inner(slug)',
          )
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(100)
          .timeout(const Duration(seconds: 10));
      final isMember = await MembershipService.isActive();
      final products = <Product>[];
      for (final item in rows) {
        final row = Map<String, dynamic>.from(item);
        final category = Map<String, dynamic>.from(row['categories'] as Map);
        final slug = '${category['slug']}';
        if (slug == 'collectible' && !isMember) continue;
        final imagePath = row['cover_image_path']?.toString();
        final imageUrl = (imagePath == null || imagePath.isEmpty)
            ? null
            : Supabase.instance.client.storage
                  .from('eclipseverse-media')
                  .getPublicUrl(imagePath);
        products.add(
          Product(
            id: (row['id'] as num).toInt(),
            name: '${row['name']}',
            category: slug,
            description: '${row['description'] ?? ''}',
            price: (row['price_idr'] as num).toInt(),
            stock: (row['stock'] as num).toInt(),
            imageUrl: imageUrl,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
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
    if (currency == 'IDR') {
      symbol = 'Rp ';
    } else if (currency == 'USD') {
      symbol = '\$ ';
      decimals = 2;
    } else if (currency == 'KRW') {
      symbol = '₩ ';
    } else if (currency == 'JPY') {
      symbol = '¥ ';
    }

    final formatted = amount
        .toStringAsFixed(decimals)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '$symbol$formatted';
  }

  // ===== FUNGSI SIMULASI BELI LANGSUNG KE SUPABASE =====
  Future<String?> _prosesBeliLangsung(Product product, int qty) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return "User belum login";

      final totalIdr = product.price * qty;

      // 1. Insert ke tabel 'orders'
      final orderResponse = await Supabase.instance.client
          .from('orders')
          .insert({'user_id': user.id, 'total_idr': totalIdr, 'status': 'confirmed'})
          .select('id')
          .single();

      final orderId = orderResponse['id'];

      // 2. Insert ke tabel 'order_items'
      await Supabase.instance.client.from('order_items').insert({
        'order_id': orderId,
        'product_id': product.id,
        'product_name_snapshot': product.name,
        'quantity': qty,
        'unit_price_idr': product.price,
      });

      return null; // Kalau sukses, return null (berarti gak ada error)
    } catch (e) {
      debugPrint('Error saat beli langsung: $e');
      return e.toString(); // Kembalikan pesan error aslinya
    }
  }

  // ===== FUNGSI BOTTOM SHEET =====
  Future<void> _showProductSheet(BuildContext context, Product product) async {
    int qty = 1;
    String selectedCurrency = 'IDR';
    bool isProcessing = false;

    CurrencyRates? liveRates;
    try {
      liveRates = await CurrencyService.fetchRates();
    } catch (e) {
      debugPrint('Kurs live belum tersedia: $e');
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isOutOfStock = product.stock <= 0;
            final totalPriceIDR = product.price * qty;

            final convertedPrice = selectedCurrency == 'IDR'
                ? totalPriceIDR.toDouble()
                : (liveRates == null
                    ? null
                    : liveRates.convert(
                        totalPriceIDR.toDouble(),
                        'IDR',
                        selectedCurrency,
                      ));

            final displayPrice = selectedCurrency == 'IDR'
                ? _formatRupiah(totalPriceIDR)
                : convertedPrice == null
                    ? 'Kurs tidak tersedia'
                    : _formatCurrency(convertedPrice, selectedCurrency);

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
                                child: CosmicNetworkImage(
                                  imageUrl: product.imageUrl,
                                  fit: BoxFit.cover,
                                ),
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
                                  children: ['IDR', 'USD', 'KRW', 'JPY'].map((
                                    curr,
                                  ) {
                                    final isSelected = selectedCurrency == curr;
                                    return GestureDetector(
                                      onTap: (curr != 'IDR' && liveRates == null)
                                          ? null
                                          : () => setSheetState(
                                                () => selectedCurrency = curr,
                                              ),
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
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          border: Border(
                            top: BorderSide(color: AppTheme.borderSubtle),
                          ),
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
                                      onPressed: (qty > 1 && !isProcessing)
                                          ? () => setSheetState(() => qty--)
                                          : null,
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      color: Colors.white,
                                    ),
                                    Text(
                                      '$qty',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed:
                                          (qty < product.stock && !isProcessing)
                                          ? () => setSheetState(() => qty++)
                                          : null,
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
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
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: (isOutOfStock || isProcessing)
                                        ? null
                                        : () async {
                                            await LocalDb.addToCart(
                                              productId: product.id,
                                              name: product.name,
                                              price: product.price,
                                              quantity: qty,
                                            );
                                            if (!mounted ||
                                                !sheetContext.mounted) {
                                              return;
                                            }

                                            Navigator.pop(sheetContext);

                                            ScaffoldMessenger.of(this.context)
                                                .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Berhasil ditambahkan ke keranjang!',
                                                    ),
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
                                    onPressed: (isOutOfStock || isProcessing)
                                        ? null
                                        : () async {
                                            setSheetState(
                                              () => isProcessing = true,
                                            );

                                            // Panggil fungsi insert ke Supabase
                                            // Ubah 'success' jadi 'errorMessage'
                                            final errorMessage =
                                                await _prosesBeliLangsung(
                                                  product,
                                                  qty,
                                                );

                                            if (!mounted ||
                                                !sheetContext.mounted) {
                                              return;
                                            }

                                            setSheetState(() {
                                              isProcessing = false;
                                            });

                                            if (errorMessage == null) {
                                              Navigator.pop(sheetContext);

                                              ScaffoldMessenger.of(this.context)
                                                  .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Transaksi Berhasil! Pesanan sedang diproses.',
                                                      ),
                                                      backgroundColor:
                                                          AppTheme.success,
                                                    ),
                                                  );
                                            } else {
                                              ScaffoldMessenger.of(this.context)
                                                  .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Error: $errorMessage',
                                                      ),
                                                      backgroundColor:
                                                          AppTheme.error,
                                                    ),
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
                                    child: isProcessing
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleProducts = _filteredProducts;

    return Scaffold(
      backgroundColor: AppTheme.deepSpace,
      appBar: AppBar(
        title: const Text('Eclipse Store'),
        actions: [
          IconButton(
            tooltip: 'Riwayat pesanan',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.pushNamed(context, Routes.orders),
          ),
          IconButton(
            tooltip: 'Keranjang',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.pushNamed(context, Routes.cart),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari album, hoodie, photocard...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.coolCyan),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final label = _categories.keys.elementAt(index);
                final selected = label == _category;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) async {
                    if (label == 'Koleksi') {
                      final isMember = await MembershipService.isActive();

                      if (!context.mounted) return;

                      if (!isMember) {
                        Navigator.pushNamed(context, Routes.membership);
                        return;
                      }
                    }

                    if (!context.mounted) return;

                    setState(() {
                      _category = label;
                    });
                  },
                  backgroundColor: AppTheme.surfaceElevated,
                  selectedColor: AppTheme.eclipseViolet,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: selected
                        ? AppTheme.eclipseViolet
                        : AppTheme.borderSubtle,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            child: Row(
              children: [
                Text(
                  _isLoading
                      ? 'Memuat katalog merchandise...'
                      : '${visibleProducts.length} produk ditemukan',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (!_isLoading)
                  GestureDetector(
                    onTap: _loadProducts,
                    child: const Row(
                      children: [
                        Icon(Icons.refresh, size: 14, color: AppTheme.coolCyan),
                        SizedBox(width: 4),
                        Text(
                          'Refresh',
                          style: TextStyle(
                            color: AppTheme.coolCyan,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: _buildContent(visibleProducts)),
        ],
      ),
    );
  }

  Widget _buildContent(List<Product> visibleProducts) {
    if (_isLoading) {
      return const CosmicLoading(message: 'Menghubungkan ke Eclipse Store...');
    }
    if (_errorMessage != null) {
      return CosmicErrorView(
        message: _errorMessage!,
        onRetry: _loadProducts,
        icon: Icons.cloud_off_rounded,
      );
    }
    if (visibleProducts.isEmpty) {
      return CosmicEmptyView(
        title: 'Tidak Ada Produk Ditemukan',
        subtitle: 'Coba ubah kata kunci pencarian atau ganti kategori filter.',
        icon: Icons.search_off_rounded,
        action: OutlinedButton(
          onPressed: () {
            _searchController.clear();
            setState(() {
              _search = '';
              _category = 'Semua';
            });
          },
          child: const Text('Reset Filter'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppTheme.eclipseViolet,
      backgroundColor: AppTheme.surfaceElevated,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: visibleProducts.length,
        itemBuilder: (context, index) {
          return _buildProductCard(visibleProducts[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isOutOfStock = product.stock <= 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (isOutOfStock) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maaf, stok produk ini sedang habis.'),
              ),
            );
            return;
          }
          _showProductSheet(context, product);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CosmicNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  if (isOutOfStock)
                    Container(
                      color: Colors.black.withValues(alpha: 0.6),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Text(
                            'HABIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!isOutOfStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.deepSpace.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Text(
                          product.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.coolCyan,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  if (!isOutOfStock && product.stock <= 5)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Sisa ${product.stock}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isOutOfStock
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatRupiah(product.price),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isOutOfStock
                          ? AppTheme.textSecondary
                          : AppTheme.coronaGold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isOutOfStock
                            ? Icons.cancel_outlined
                            : Icons.check_circle_outline,
                        size: 12,
                        color: isOutOfStock ? AppTheme.error : AppTheme.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOutOfStock ? 'Stok habis' : 'Stok: ${product.stock}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isOutOfStock
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isOutOfStock
                              ? AppTheme.error
                              : AppTheme.textSecondary,
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
    );
  }
}
