import 'package:flutter/material.dart';

import './theme/app_theme.dart';
import './features/auth/login_page.dart';
import './features/auth/register_page.dart';
import './features/auth/splash_page.dart';
import './core/routes.dart';

import 'features/shell/main_shell.dart';
import 'features/ai/ai_page.dart';
import 'features/game/game_page.dart';
import 'features/marketplace/catalog_page.dart'; // 👈 TAMBAHIN INI

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
      home: const MainShell(),

      routes: {
        // Route untuk Main Shell (Home)
        '/shell': (context) => const MainShell(),

        // Route untuk Eclipse AI
        '/ai': (context) => const AiPage(),

        // Route untuk Mini Game
        '/game': (context) => const GamePage(),

        // Route untuk Marketplace Catalog
        '/catalog': (context) => const CatalogPage(),
      },
      home: const LoginPage(),
    );
  }
}
