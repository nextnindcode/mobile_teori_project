import 'package:flutter/material.dart';

import './theme/app_theme.dart';
import './screens/login.dart';

import 'features/shell/main_shell.dart';
import 'features/ai/ai_page.dart'; 

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
      },
    );
  }
}