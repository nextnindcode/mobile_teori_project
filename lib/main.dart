import 'package:flutter/material.dart';

import './theme/app_theme.dart';
import './screens/login.dart';

import 'features/shell/main_shell.dart';
import 'features/ai/ai_page.dart'; 
import 'features/game/game_page.dart'; 
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
      home: const LoginPage(),

      routes: {
        // Route untuk Main Shell (Home)
        '/shell': (context) => const MainShell(),
        
        // Route untuk Eclipse AI 
        '/ai': (context) => const AiPage(),

        // Route untuk Mini Game 
        '/game': (context) => const GamePage(),

        // Route untuk Nearby Lokasi 
        '/nearby': (context) => const NearbyPage(),

        // Route untuk Redeem Kartu 
        '/redeem': (context) => const RedeemPage(), 
        
        // Route untuk Notifikasi 
        '/notifications': (context) => const NotificationPage(),
      },
    );
  }
}