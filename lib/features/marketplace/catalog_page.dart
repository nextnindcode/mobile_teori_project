import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/routes.dart';
import '../../models/products.dart';
import '../../theme/app_theme.dart';
import 'product_detail_sheet.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  List<Product> _products = [];
  bool _isLoading = true;
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
    try {
      final response = await ApiService.get('/products');
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Produk tidak dapat dimuat.');
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
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat produk: $e')),
      );
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
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            tooltip: 'Buka keranjang',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.pushNamed(context, Routes.cart),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ECLIPSEVERSE STORE',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text('A little piece of your universe.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Temukan album dan merchandise favoritmu.',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value),
              decoration: InputDecoration(
                hintText: 'Cari album, apparel, merchandise...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
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
                  selectedColor: AppTheme.primaryLight,
                  labelStyle: TextStyle(
                    color: selected ? AppTheme.primaryDark : AppTheme.black,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide.none,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Text(
              _isLoading ? 'Memuat koleksi...' : '${visibleProducts.length} produk ditemukan',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : visibleProducts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off, size: 54),
                              const SizedBox(height: 12),
                              Text('Belum ada produk yang cocok',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              const Text('Coba kata kunci atau kategori lain.',
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.62,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: visibleProducts.length,
                        itemBuilder: (context, index) {
                          final product = visibleProducts[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 1,
                            color: AppTheme.white,
                            child: InkWell(
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    ProductDetailSheet(product: product),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (product.imageUrl != null &&
                                            product.imageUrl!.isNotEmpty)
                                          Image.network(
                                            product.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const ColoredBox(
                                              color: AppTheme.surface,
                                              child: Icon(Icons.image_not_supported_outlined,
                                                  size: 42),
                                            ),
                                          )
                                        else
                                          const ColoredBox(
                                            color: AppTheme.surface,
                                            child: Icon(Icons.image_outlined,
                                                size: 42),
                                          ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.92),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              product.category.toUpperCase(),
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.primaryDark),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                height: 1.2)),
                                        const SizedBox(height: 7),
                                        Text(_formatRupiah(product.price),
                                            style: const TextStyle(
                                                color: AppTheme.primaryDark,
                                                fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Text('Stok: ${product.stock}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
