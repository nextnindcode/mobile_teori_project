// FILE UJI LOKAL (seluruh aplikasi). Jangan ganti main.dart (milik A).
// Jalankan:
// flutter run -t lib/main_full.dart --dart-define=API_BASE=https://xxxx.trycloudflare.com/eclipseverse/api
import 'package:flutter/material.dart';

import 'package:eclipseverse/core/local_db.dart';
import 'package:eclipseverse/core/routes.dart';
import 'package:eclipseverse/core/secure_store.dart';
import 'package:eclipseverse/theme/app_theme.dart';

import 'package:eclipseverse/features/ai/ai_page.dart';
import 'package:eclipseverse/features/event/event_detail_page.dart';
import 'package:eclipseverse/features/event/event_page.dart';
import 'package:eclipseverse/features/fandom/member_detail_page.dart';
import 'package:eclipseverse/features/game/game_page.dart';
import 'package:eclipseverse/features/shell/main_shell.dart';
import 'package:eclipseverse/features/tools/tools_page.dart';
import 'package:eclipseverse/features/nearby/nearby_page.dart';
import 'package:eclipseverse/features/notification/notification_page.dart';
import 'package:eclipseverse/features/redeem/redeem_page.dart';
import 'package:eclipseverse/features/auth/login_page.dart';
import 'package:eclipseverse/features/auth/register_page.dart';
import 'package:eclipseverse/features/auth/splash_page.dart';
import 'package:eclipseverse/features/marketplace/catalog_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sesi uji (sampai Login milik A jadi). Hapus bila Login sudah dipasang.
  await SecureStore.saveToken('DEV-TOKEN-ECLIPSE');
  await LocalDb.saveProfile(
    userId: 1,
    name: 'User Uji',
    email: 'uji@eclipseverse.test',
  );
  runApp(const FullApp());
}

class FullApp extends StatelessWidget {
  const FullApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EclipseVerse',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.shell,
      routes: {
        Routes.login: (_) => const LoginPage(),
        Routes.shell: (context) => MainShell(
          onLogout: () async {
            final nav = Navigator.of(context);
            await SecureStore.deleteToken();
            await LocalDb.clearAll();
            nav.pushNamedAndRemoveUntil(Routes.login, (_) => false);
          },
        ),
        Routes.splash: (_) => const SplashPage(),
        Routes.login: (_) => const LoginPage(),
        Routes.register: (_) => const RegisterPage(),
        Routes.catalog: (_) => const CatalogPage(),
        Routes.events: (_) => const EventListPage(),
        '/event-detail': (_) => const EventDetailPage(),
        '/member-detail': (_) => const MemberDetailPage(),
        Routes.tools: (_) => const ToolsPage(),
        Routes.ai: (_) => const AiPage(),
        Routes.game: (_) => const GamePage(),
        Routes.nearby: (_) => const NearbyPage(),
        Routes.notifications: (_) => const NotificationPage(),
        Routes.redeem: (_) => const RedeemPage(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => _ComingSoonPage(route: settings.name ?? '-'),
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  final String route;
  const _ComingSoonPage({required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Belum tersedia')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 56, color: AppTheme.grey),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                'Halaman $route belum dibuat\n(modul A / C)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}