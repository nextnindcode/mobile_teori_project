import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';

class OrdersPage extends StatefulWidget {
  final bool previewMode;

  const OrdersPage({super.key, this.previewMode = false});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Silakan login kembali.');

      // Tarik data order_items sekalian nama produk & gambar dari tabel products
      final rows = await Supabase.instance.client
          .from('orders')
          .select('''
            id, status, created_at, total_idr, 
            order_items(
              quantity, 
              unit_price_idr, 
              products(name, cover_image_path)
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(100)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() {
        _orders = rows.map((item) {
          final row = Map<String, dynamic>.from(item);
          final List itemsList = row['order_items'] as List? ?? [];

          // Hitung total qty (bukan cuma jumlah baris)
          int totalQty = 0;
          for (var i in itemsList) {
            totalQty += (i['quantity'] as num?)?.toInt() ?? 0;
          }

          row['item_count'] = totalQty;
          row['total'] = row['total_idr'];
          row['items'] = itemsList; // Simpan list barang buat ditampilin
          return row;
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _rupiah(dynamic value) {
    final digits = (value as num? ?? 0).toInt().toString();
    final result = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      result.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) result.write('.');
    }
    return 'Rp $result';
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse('$value');
    if (parsed == null) return '$value';
    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year} • ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat Pesanan'),
          actions: [
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 52),
                      const SizedBox(height: 12),
                      const Text(
                        'Riwayat belum bisa dimuat',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadOrders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadOrders,
                child: _orders.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
                        children: [
                          const SizedBox(height: 90),
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 72,
                            color: AppTheme.primaryDark,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada pesanan',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AppTheme.surfaceSecondary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pesanan yang berhasil kamu checkout akan muncul di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final List items = order['items'] ?? [];
                          // Paksa nampilin 'PAID' kalau statusnya paid atau completed
                          final String rawStatus =
                              '${order['status'] ?? 'PAID'}'.toUpperCase();
                          final status = (rawStatus == 'COMPLETED')
                              ? 'PAID'
                              : rawStatus;

                          // Potong UUID biar cuma 8 karakter
                          final String fullId = order['id']?.toString() ?? '';
                          final String shortId = fullId.length > 8
                              ? fullId.substring(0, 8)
                              : fullId;

                          return Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header (ID & Status)
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.primaryLight
                                            .withValues(alpha: 0.45),
                                        child: const Icon(
                                          Icons.receipt_long_outlined,
                                          color: AppTheme.primaryDark,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Pesanan #$shortId',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color:
                                                    AppTheme.surfaceSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _date(order['created_at']),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryLight
                                              .withValues(alpha: 0.45),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.surfaceSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),

                                  // List Produk yang dibeli
                                  if (items.isNotEmpty)
                                    ...items.map((item) {
                                      final prod = item['products'] ?? {};
                                      final qty = item['quantity'] ?? 1;
                                      final prodName = prod['name'] ?? 'Produk';
                                      final imagePath =
                                          prod['cover_image_path'];

                                      // Gambar dari Supabase Storage
                                      final imageUrl =
                                          (imagePath != null &&
                                              imagePath.isNotEmpty)
                                          ? Supabase.instance.client.storage
                                                .from('eclipseverse-media')
                                                .getPublicUrl(imagePath)
                                          : null;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            // Gambar kecil
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                image: imageUrl != null
                                                    ? DecorationImage(
                                                        image: NetworkImage(
                                                          imageUrl,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                              ),
                                              child: imageUrl == null
                                                  ? const Icon(
                                                      Icons.shopping_bag,
                                                      color: Colors.grey,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            // Nama produk & qty
                                            Expanded(
                                              child: Text(
                                                '$qty x $prodName',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppTheme.surfaceSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                  // Footer (Total)
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${order['item_count'] ?? 0} item',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.surfaceSecondary, // 👈 Warnanya diubah
                                        ),
                                      ),
                                      Text(
                                        _rupiah(order['total']),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.surfaceSecondary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
