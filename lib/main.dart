import 'package:flutter/material.dart';

import './theme/app_theme.dart';
import './features/auth/login_page.dart';
import './features/auth/register_page.dart';
import './features/auth/splash_page.dart';
import './core/routes.dart';

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
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (context) => const SplashPage(),
        Routes.login: (context) => const LoginPage(),
        Routes.register: (context) => const RegisterPage(),

        Routes.shell: (context) => Scaffold(
          appBar: AppBar(title: const Text('Home Sementara')),
          body: const Center(child: Text('Login Berhasil!')),
        ),
      },
    );
  }
}
