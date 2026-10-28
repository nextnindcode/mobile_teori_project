import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import 'theme/app_theme.dart';
import 'core/routes.dart';
import 'core/auth_service.dart';
import 'core/supabase_config.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/auth/splash_page.dart';
import 'features/event/event_page.dart';
import 'features/event/event_detail_page.dart';
import 'features/fandom/member_detail_page.dart';
import 'features/tools/tools_page.dart';
import 'features/tools/observatory_page.dart';
import 'features/shell/main_shell.dart';
import 'features/ai/ai_page.dart';
import 'features/game/game_page.dart';
import 'features/marketplace/catalog_page.dart';
import 'features/marketplace/cart_page.dart';
import 'features/marketplace/orders_page.dart';
import 'features/membership/membership_page.dart';
import 'features/nearby/nearby_page.dart';
import 'features/redeem/redeem_page.dart';
import 'features/notification/notification_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // inisialisasi zona waktu buat konversi
  tz.initializeTimeZones();

  // Semua anggota menggunakan satu proyek Supabase yang sama.
  // Aplikasi tidak lagi bergantung pada XAMPP, localhost, atau alamat IP laptop.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EclipseVerse',
      theme: AppTheme.cosmicTheme(),
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
      routes: {
        Routes.login: (_) => const LoginPage(),
        Routes.register: (_) => const RegisterPage(),
        Routes.splash: (_) => const SplashPage(),
        Routes.shell: (context) => MainShell(
          onLogout: () async {
            try {
              await AuthService.logout();
            } catch (e) {
              debugPrint('Logout error: $e');
            }

            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.login,
                (_) => false,
              );
            }
          },
        ),
        Routes.events: (_) => const EventListPage(),
        Routes.eventDetail: (_) => const EventDetailPage(),
        Routes.memberDetail: (_) => const MemberDetailPage(),
        Routes.tools: (_) => const ToolsPage(),
        Routes.observatory: (_) => const ObservatoryPage(),
        Routes.catalog: (_) => const CatalogPage(),
        Routes.cart: (_) => const CartPage(),
        Routes.orders: (_) => const OrdersPage(),
        Routes.membership: (_) => const MembershipPage(),
        Routes.ai: (_) => const AiPage(),
        Routes.game: (_) => const GamePage(),
        Routes.nearby: (_) => const NearbyPage(),
        Routes.redeem: (_) => const RedeemPage(),
        Routes.notifications: (_) => const NotificationPage(),
      },
    );
  }
}
