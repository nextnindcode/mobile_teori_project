import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _open(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTheme.textTheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('EclipseVerse'),
        actions: [
          IconButton(
            tooltip: 'Keranjang',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => _open(context, Routes.cart),
          ),
          IconButton(
            tooltip: 'Riwayat pesanan',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => _open(context, Routes.orders),
          ),
          IconButton(
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _open(context, Routes.notifications),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          // Hero area: satu fokus utama, bukan deretan kotak menu.
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            padding: const EdgeInsets.fromLTRB(22, 24, 18, 22),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -18,
                  child: Icon(Icons.nightlight_round,
                      size: 112, color: Colors.white.withValues(alpha: 0.10)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'YOUR LITTLE UNIVERSE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 1.7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Halo, Eclipse Lovers ✨',
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 23,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Temukan kabar, teman, dan momen favoritmu dalam satu semesta.',
                      style: TextStyle(color: Colors.white70, height: 1.45),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryDark,
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => _open(context, Routes.events),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Jelajahi event'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Shortcut horizontal lebih ringan dan terasa seperti aplikasi.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text('Akses cepat', style: textTheme.titleLarge),
                ),
                Text('Geser →', style: textTheme.bodySmall?.copyWith(color: AppTheme.grey)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 100,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              children: [
                _QuickAction(label: 'Store', icon: Icons.storefront_outlined,
                    tint: const Color(0xFFE8DFFF), onTap: () => _open(context, Routes.catalog)),
                _QuickAction(label: 'Notifikasi', icon: Icons.notifications_outlined,
                    tint: const Color(0xFFF5DCEB), onTap: () => _open(context, Routes.notifications)),
                _QuickAction(label: 'Eclipse AI', icon: Icons.auto_awesome_outlined,
                    tint: const Color(0xFFE1E7FF), onTap: () => _open(context, Routes.ai)),
                _QuickAction(label: 'Nearby', icon: Icons.near_me_outlined,
                    tint: const Color(0xFFDDF3EB), onTap: () => _open(context, Routes.nearby)),
                _QuickAction(label: 'Tools', icon: Icons.handyman_outlined,
                    tint: const Color(0xFFFFE9D6), onTap: () => _open(context, Routes.tools)),
                _QuickAction(label: 'Redeem', icon: Icons.card_giftcard_outlined,
                    tint: const Color(0xFFE9E0F5), onTap: () => _open(context, Routes.redeem)),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: Text('Saatnya bermain', style: textTheme.titleLarge)),
                TextButton(
                  onPressed: () => _open(context, Routes.game),
                  child: const Text('Buka game'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _open(context, Routes.game),
              child: Ink(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.sports_esports_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Guess the Member', style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                          const SizedBox(height: 4),
                          Text('Tebak member dari petunjuk dan kumpulkan poin.',
                              style: textTheme.bodyMedium?.copyWith(color: AppTheme.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Tetap terhubung', style: textTheme.titleLarge),
          ),
          const SizedBox(height: 6),
          _FeatureLink(
            icon: Icons.event_available_outlined,
            title: 'Event & agenda',
            subtitle: 'Lihat aktivitas dan event komunitas terbaru',
            onTap: () => _open(context, Routes.events),
          ),
          _FeatureLink(
            icon: Icons.shopping_bag_outlined,
            title: 'Marketplace',
            subtitle: 'Jelajahi koleksi dan merchandise',
            onTap: () => _open(context, Routes.catalog),
          ),
          _FeatureLink(
            icon: Icons.receipt_long_outlined,
            title: 'Pesanan saya',
            subtitle: 'Cek status dan riwayat checkout',
            onTap: () => _open(context, Routes.orders),
          ),
          _FeatureLink(
            icon: Icons.location_on_outlined,
            title: 'Temukan di sekitar',
            subtitle: 'Jelajahi lokasi yang relevan di sekitarmu',
            onTap: () => _open(context, Routes.nearby),
          ),
          _FeatureLink(
            icon: Icons.card_giftcard,
            title: 'Redeem Card',
            subtitle: 'Tukar poin dengan kartu eksklusif member',
            onTap: () => _open(context, Routes.redeem),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 68,
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Icon(icon, color: AppTheme.primaryDark, size: 26),
              ),
              const SizedBox(height: 8),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: AppTheme.primaryDark),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
