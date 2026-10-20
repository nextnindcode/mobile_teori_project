import 'package:flutter/material.dart';

import 'core/routes.dart';
import 'theme/app_theme.dart';
import 'features/shell/main_shell.dart';
import 'features/marketplace/catalog_page.dart';
import 'features/marketplace/cart_page.dart';
import 'features/marketplace/orders_page.dart';
import 'features/event/event_page.dart';
import 'features/tools/tools_page.dart';
import 'features/game/game_page.dart';
import 'features/ai/ai_page.dart';
import 'features/nearby/nearby_page.dart';
import 'features/redeem/redeem_page.dart';
import 'features/notification/notification_page.dart';

// Entry point khusus untuk melihat UI tanpa login/backend.
// Gunakan: flutter run -t lib/main_preview.dart
void main() {
  runApp(const EclipseVersePreviewApp());
}

class EclipseVersePreviewApp extends StatelessWidget {
  const EclipseVersePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EclipseVerse UI Preview',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
      routes: {
        Routes.shell: (_) => const MainShell(),
        Routes.catalog: (_) => const CatalogPage(previewMode: true),
        Routes.cart: (_) => const CartPage(previewMode: true),
        Routes.orders: (_) => const OrdersPage(previewMode: true),
        Routes.events: (_) => const EventListPage(),
        Routes.tools: (_) => const ToolsPage(),
        Routes.game: (_) => const GamePage(),
        Routes.ai: (_) => const AiPage(),
        Routes.nearby: (_) => const NearbyPage(),
        Routes.redeem: (_) => const RedeemPage(),
        Routes.notifications: (_) => const NotificationPage(),
      },
    );
  }
}
