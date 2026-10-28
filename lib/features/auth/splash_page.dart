import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_service.dart';
import '../../core/routes.dart';
import '../../core/session_timeout_service.dart';
import '../../theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // Variabel untuk mengontrol posisi animasi
  double _moonPosition = -120.0;

  @override
  void initState() {
    super.initState();

    // 1. Jalankan animasi setelah layar dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _moonPosition = 0.0; // Bulan bergerak ke tengah
      });
    });

    // 2. Cek session dengan delay yang cukup
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final expired = await SessionTimeoutService.hasExpired();
    await SessionTimeoutService.clearBackgroundTime();

    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;

    if (session == null || user == null || expired) {
      if (expired && session != null) {
        try {
          await AuthService.logout();
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.login);
      return;
    }

    try {
      await AuthService.cacheUserLocally(user);
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.shell);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ===== AREA ANIMASI GERHANA =====
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Lingkaran Matahari (Kuning, diam di tengah)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentYellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orangeAccent,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  // 2. Lingkaran Bulan (Gelap, bergerak dari kiri menutupi matahari)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeInOutCubic, // Gerakan yang mulus
                    left: _moonPosition,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryDark, // Sama dengan background
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'EclipseVerse',
              style: AppTheme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
