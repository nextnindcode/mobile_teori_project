import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../theme/app_theme.dart';
import '../marketplace/catalog_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTheme.textTheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('EclipseVerse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, Routes.notifications);
            },
          ),
        ],
      ),
      // Menggunakan ListView agar tidak pernah terjadi overflow layar
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        children: [
          Text(
            'Halo, Eclipse Lovers!',
            style: textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mau eksplor apa hari ini?',
            style: textTheme.bodyLarge?.copyWith(
              color: AppTheme.grey,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          
          // Grid Menu
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.25, 
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMenuCard(context, 'Marketplace', Icons.shopping_bag, Routes.catalog),
              _buildMenuCard(context, 'Event', Icons.event, Routes.events),
              _buildMenuCard(context, 'Nearby', Icons.location_on, Routes.nearby),
              _buildMenuCard(context, 'Eclipse AI', Icons.smart_toy, Routes.ai),
              _buildMenuCard(context, 'Eclipse Tools', Icons.handyman, Routes.tools),
              _buildMenuCard(context, 'Redeem Card', Icons.card_giftcard, Routes.redeem),
            ],
          ),
          
          // Jarak aman di bawah agar tidak tertutup tombol Mini Game
          const SizedBox(height: 80), 
        ],
      ),
      
      // Tombol Melayang untuk Mini Game
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, Routes.game);
        },
        backgroundColor: AppTheme.primaryDark, 
        foregroundColor: Colors.white,
        icon: const Icon(Icons.sports_esports),
        label: const Text(
          'Main Game!', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32, 
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 8), 
                Text(
                  title,
                  style: AppTheme.textTheme.titleSmall?.copyWith( 
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}