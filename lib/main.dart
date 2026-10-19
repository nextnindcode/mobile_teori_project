import 'package:flutter/material.dart';

import './theme/app_theme.dart';
import './core/routes.dart';
import './features/auth/login_page.dart';
import './features/auth/register_page.dart';
import './features/auth/splash_page.dart';
import './core/local_db.dart';
import './core/secure_store.dart';
import './features/event/event_page.dart';
import './features/tools/tools_page.dart';

import 'features/shell/main_shell.dart';
import 'features/ai/ai_page.dart';
import 'features/game/game_page.dart';
import 'features/marketplace/catalog_page.dart'; 
import 'features/nearby/nearby_page.dart';
import 'features/redeem/redeem_page.dart';
import 'features/notification/notification_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EclipseVerse',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      
      // Aplikasi dimulai dari Login 
      home: const LoginPage(),

      routes: {
        Routes.login: (_) => const LoginPage(),
        Routes.register: (_) => const RegisterPage(),
        Routes.splash: (_) => const SplashPage(),
        Routes.shell: (context) => MainShell(
          onLogout: () async {
            await SecureStore.deleteToken();
            await LocalDb.clearAll();
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
        Routes.tools: (_) => const ToolsPage(),
        '/catalog': (context) => const CatalogPage(),
        '/ai': (context) => const AiPage(),
        '/game': (context) => const GamePage(),
        '/nearby': (context) => const NearbyPage(),
        '/redeem': (context) => const RedeemPage(),
        '/notifications': (context) => const NotificationPage(),
      },
    );
  }
}