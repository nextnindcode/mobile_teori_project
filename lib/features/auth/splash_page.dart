import 'package:flutter/material.dart';

import '../../core/secure_store.dart';
import '../../core/routes.dart';
import '../../theme/app_theme.dart';
import '../../core/local_db.dart';
import '../profile/biometric_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Delay 3 detik biar animasi gerhana selesai
    await Future.delayed(const Duration(seconds: 3));

    final token = await SecureStore.getToken();

    if (!mounted) return;

    if (token != null) {
      final biometricEnabled = await LocalDb.getPref('biometric_enabled');

      if (biometricEnabled == '1' || biometricEnabled == 'true') {
        final isSupported = await BiometricService.isSupported();

        if (isSupported) {
          final authSuccess = await BiometricService.authenticate();

          if (!mounted) return;

          if (authSuccess) {
            Navigator.pushReplacementNamed(context, Routes.shell);
          } else {
            Navigator.pushReplacementNamed(context, Routes.login);
          }
          return;
        }
      }

      // Kalau biometrik mati / ga support, tapi token ada -> Langsung ke Home!
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, Routes.shell);
    } else {
      // Kalau token ga ada -> ke Login
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: -100.0, end: 0.0),
              duration: const Duration(seconds: 3),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppTheme.background,
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
                    // Bulan geser nutupin matahari
                    Transform.translate(
                      offset: Offset(value, 0),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'EclipseVerse',
              style: AppTheme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
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
