import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/routes.dart';
import '../../models/products.dart';
import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart';
import 'product_detail_sheet.dart';

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
    return _products.where((product) {
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
      final selectedCategory = _categories[_category] ?? '';
      final matchesCategory =
          selectedCategory.isEmpty || product.category.toLowerCase() == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
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
          Product(
            id: 103,
            name: 'Moonlight Photocard Set',
            category: 'collectible',
            description: 'Satu set photocard edisi Moonlight.',
            price: 79000,
            stock: 50,
            imageUrl: 'https://images.unsplash.com/photo-1572378203089-70a1b2a2d1e1?q=80&w=500',
          ),
          Product(
            id: 104,
            name: 'EclipseVerse Light Keyring',
            category: 'accessory',
            description: 'Aksesori keyring dengan logo EclipseVerse.',
            price: 45000,
            stock: 40,
            imageUrl: 'https://images.unsplash.com/photo-1584268868487-1df0d61c1622?q=80&w=500',
          ),
        ];
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiService.get('/products');
      if (response['success'] != true) {
        throw ApiException(
          response['message']?.toString() ?? 'Gagal memuat daftar produk dari server.',
          'API_ERROR',
        );
      }
      final List data = response['data'] as List? ?? [];
      if (!mounted) return;
      setState(() {
        _products = data
            .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
            .toList();
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
          // 1. Search Bar
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
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                      ),
              ),
            ),
          ),

          // 2. Category Filter Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final label = _categories.keys.elementAt(index);
                final selected = label == _category;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = label),
                  backgroundColor: AppTheme.surfaceElevated,
                  selectedColor: AppTheme.eclipseViolet,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: selected ? AppTheme.eclipseViolet : AppTheme.borderSubtle,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // 3. Status Bar (Count)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            child: Row(
              children: [
                Text(
                  _isLoading
                      ? 'Memuat katalog merchandise...'
                      : '${visibleProducts.length} produk ditemukan',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                if (!_isLoading)
                  GestureDetector(
                    onTap: _loadProducts,
                    child: const Row(
                      children: [
                        Icon(Icons.refresh, size: 14, color: AppTheme.coolCyan),
                        SizedBox(width: 4),
                        Text('Refresh', style: TextStyle(color: AppTheme.coolCyan, fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 4. Products Grid or Explicit Error/Empty State
          Expanded(
            child: _buildContent(visibleProducts),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<Product> visibleProducts) {
    if (_isLoading) {
      return const CosmicLoading(message: 'Menghubungkan ke Eclipse Store...');
    }

    // Notice: if API actually failed, show ErrorView with Retry, NEVER show a fake successful empty state!
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
          final product = visibleProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ProductDetailSheet(product: product),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with resolved URL & Category Badge
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CosmicNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  if (product.stock <= 5)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.stock == 0 ? 'HABIS' : 'Sisa ${product.stock}',
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

            // Product Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatRupiah(product.price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.coronaGold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        product.stock > 0 ? Icons.check_circle_outline : Icons.cancel_outlined,
                        size: 12,
                        color: product.stock > 0 ? AppTheme.success : AppTheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.stock > 0 ? 'Stok: ${product.stock}' : 'Stok habis',
                        style: TextStyle(
                          fontSize: 11,
                          color: product.stock > 0 ? AppTheme.textSecondary : AppTheme.error,
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
