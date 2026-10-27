import 'dart:io';

import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/local_db.dart';
import '../../core/routes.dart';
import '../../models/products.dart';
import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart';
import '../event/event_model.dart';
import '../event/event_page.dart' show formatEventDate;
// ignore: unused_import
import '../event/event_service.dart';
import '../marketplace/product_detail_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = 'Eclipse Lovers';
  String? _avatarPath;
  int _userPoints = 0;
  bool _isLoadingPoints = true;

  List<Event> _upcomingEvents = [];
  bool _isLoadingEvents = true;

  List<Product> _featuredProducts = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    _loadProfile();
    _loadPoints();
    _loadEvents();
    _loadProducts();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      final cached = user == null
          ? null
          : await LocalDb.getUserProfile(user.id);

      final avatar = user == null
          ? await LocalDb.getPref('avatar_path')
          : await LocalDb.getPref('avatar_path_${user.id}');

      if (mounted) {
        setState(() {
          if (cached?['name'] != null &&
              cached!['name'].toString().trim().isNotEmpty) {
            _userName = cached['name'].toString();
          }

          _avatarPath = avatar;
        });
      }

      if (user == null) return;

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('display_name, avatar_path')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      final name = profile?['display_name']?.toString().trim() ?? '';
      final remoteAvatar = profile?['avatar_path']?.toString().trim() ?? '';
      final avatarUrl = remoteAvatar.isEmpty
          ? null
          : (remoteAvatar.startsWith('http')
              ? remoteAvatar
              : Supabase.instance.client.storage.from('eclipseverse-media').getPublicUrl(remoteAvatar));

      if (mounted) {
        setState(() {
          if (name.isNotEmpty) _userName = name;
          if (avatarUrl != null && avatarUrl.isNotEmpty) _avatarPath = avatarUrl;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPoints() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoadingPoints = false);
        return;
      }
      final stats = await Supabase.instance.client
          .from('user_points')
          .select('total_points')
          .eq('user_id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() {
          _userPoints = (stats?['total_points'] as num?)?.toInt() ?? 0;
          _isLoadingPoints = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPoints = false);
    }
  }

  Future<void> _loadEvents() async {
    try {
      final rows = await Supabase.instance.client
          .from('events')
          .select(
            'id, title, description, event_date, venue, city, latitude, longitude',
          )
          .eq('status', 'scheduled')
          .order('event_date')
          .limit(3)
          .timeout(const Duration(seconds: 8));
      final events = (rows as List)
          .map((row) => Event.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      if (mounted) {
        setState(() {
          _upcomingEvents = events;
          _isLoadingEvents = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select(
            'id, name, description, price_idr, stock, cover_image_path, categories(name)',
          )
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(6)
          .timeout(const Duration(seconds: 8));

      final list = (rows as List).map((item) {
        final row = Map<String, dynamic>.from(item);
        final rawCategory = row['categories'];
        final category = rawCategory is Map
            ? (rawCategory['name']?.toString() ?? 'Merchandise')
            : 'Merchandise';
        final imagePath = row['cover_image_path']?.toString();
        String? imageUrl;
        if (imagePath != null && imagePath.trim().isNotEmpty) {
          imageUrl = imagePath.startsWith('http')
              ? imagePath
              : Supabase.instance.client.storage
                    .from('eclipseverse-media')
                    .getPublicUrl(imagePath);
        }
        return Product(
          id: (row['id'] as num).toInt(),
          name: row['name']?.toString() ?? 'Produk',
          category: category,
          description: row['description']?.toString() ?? '',
          price: (row['price_idr'] as num?)?.toInt() ?? 0,
          stock: (row['stock'] as num?)?.toInt() ?? 0,
          imageUrl: imageUrl,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _featuredProducts = list;
          _isLoadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  void _open(String route, {Object? arguments}) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }

  ImageProvider? get _avatarImage {
    final p = _avatarPath;
    if (p == null) return null;
    if (p.startsWith('https://') || p.startsWith('http://')) {
      return NetworkImage(p);
    }
    final f = File(p);
    return f.existsSync() ? FileImage(f) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepSpace,
      floatingActionButton: _buildFloatingMiniGameButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
              ),
              child: const Icon(
                Icons.nightlight_round,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'EclipseVerse',
              style: TextStyle(letterSpacing: 0.8, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Riwayat pesanan',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => _open(Routes.orders),
          ),
          IconButton(
            tooltip: 'Keranjang',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => _open(Routes.cart),
          ),
          IconButton(
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _open(Routes.notifications),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: AppTheme.eclipseViolet,
        backgroundColor: AppTheme.surfaceElevated,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 36),
          children: [
            _buildHeroHeader(),

            const SizedBox(height: 24),

            // 2. Cosmic Quick Actions (Grid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    // <--- FIX OVERFLOW 1
                    child: Text(
                      'Jelajahi Universe',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: AppTheme.textPrimary),
                    ),
                  ),
                  const Text(
                    'Fitur Utama',
                    style: TextStyle(
                      color: AppTheme.coolCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildQuickActionGrid(),

            const SizedBox(height: 28),

            // Mini game dipindahkan ke tombol melayang agar beranda tidak terlalu padat.
            const SizedBox(height: 28),

            // Upcoming Events from Real API
            _buildUpcomingEventsSection(),

            const SizedBox(height: 28),

            // 5. Featured Products from Real API
            _buildFeaturedProductsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.cosmicHeroGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.eclipseViolet.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.eclipseViolet.withValues(alpha: 0.35),
                    AppTheme.coolCyan.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.surfaceSecondary,
                    backgroundImage: _avatarImage,
                    child: _avatarImage == null
                        ? Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'E',
                            style: const TextStyle(
                              color: AppTheme.coolCyan,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $_userName ✨',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Selamat datang di semesta Eclipse',
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _open(Routes.redeem),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.coronaGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.coronaGold.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            size: 14,
                            color: AppTheme.deepSpace,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isLoadingPoints ? '...' : '$_userPoints PTS',
                            style: const TextStyle(
                              color: AppTheme.deepSpace,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'A Little Piece of Your Universe',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pantau jadwal tur, merchandise eksklusif, hingga asisten AI dalam satu platform terpadu.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    // <--- FIX OVERFLOW 2
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.eclipseViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _open(Routes.catalog),
                      icon: const Icon(Icons.storefront_rounded, size: 16),
                      label: const Text(
                        'Beli Merch',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    // <--- FIX OVERFLOW 2
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.coolCyan,
                        side: const BorderSide(color: AppTheme.borderSubtle),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _open(Routes.ai),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text(
                        'Tanya AI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    final actions = [
      {
        'label': 'Nearby',
        'icon': Icons.near_me_outlined,
        'color': AppTheme.coronaGold,
        'route': Routes.nearby,
      },
      {
        'label': 'Eclipse AI',
        'icon': Icons.auto_awesome_outlined,
        'color': AppTheme.eclipseViolet,
        'route': Routes.ai,
      },
      {
        'label': 'Kurs & Waktu',
        'icon': Icons.currency_exchange_rounded,
        'color': AppTheme.coolCyan,
        'route': Routes.tools,
      },
      {
        'label': 'Redeem Poin',
        'icon': Icons.card_giftcard_rounded,
        'color': AppTheme.coronaGold,
        'route': Routes.redeem,
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.88,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final item = actions[index];
          final color = item['color'] as Color;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _open(item['route'] as String),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      item['label'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
             Widget _buildFloatingMiniGameButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(Routes.game),
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.textPrimary.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.eclipseViolet.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_esports_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Mini Games',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.auto_awesome_rounded, color: AppTheme.coronaGold, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

              size: 14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                // <--- FIX OVERFLOW 4
                child: Text(
                  'Event Mendatang',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: AppTheme.textPrimary),
                ),
              ),
              TextButton(
                onPressed: () => _open(Routes.events),
                child: const Text(
                  'Semua →',
                  style: TextStyle(color: AppTheme.coolCyan),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingEvents)
          const Padding(
            padding: EdgeInsets.all(24),
            child: CosmicLoading(message: 'Memuat event...'),
          )
        else if (_upcomingEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CosmicCard(
              child: const Text(
                'Belum ada jadwal event terdekat.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          SizedBox(
            height: 165,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _upcomingEvents.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final e = _upcomingEvents[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _open(Routes.eventDetail, arguments: e.id),
                  child: Container(
                    width: 260,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CosmicBadge(
                              text: e.city.toUpperCase(),
                              color: AppTheme.coolCyan,
                              textColor: AppTheme.coolCyan,
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          e.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 13,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                e.venue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatEventDate(e.eventDate),
                          style: const TextStyle(
                            color: AppTheme.coronaGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildFeaturedProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                // <--- FIX OVERFLOW 5
                child: Text(
                  'Merchandise Pilihan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: AppTheme.textPrimary),
                ),
              ),
              TextButton(
                onPressed: () => _open(Routes.catalog),
                child: const Text(
                  'Katalog →',
                  style: TextStyle(color: AppTheme.coolCyan),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingProducts)
          const Padding(
            padding: EdgeInsets.all(24),
            child: CosmicLoading(message: 'Memuat merchandise...'),
          )
        else if (_featuredProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CosmicCard(
              child: const Text(
                'Belum ada produk merchandise.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _featuredProducts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final p = _featuredProducts[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ProductDetailSheet(product: p),
                    );
                  },
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CosmicNetworkImage(
                            imageUrl: p.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.category.toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.coolCyan,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rp ${p.price}',
                                style: const TextStyle(
                                  color: AppTheme.coronaGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
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
    );
  }
}
