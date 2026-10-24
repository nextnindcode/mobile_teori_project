import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_service.dart';
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
    // Supabase.initialize() sudah memulihkan session tersimpan.
    // Splash hanya memberi waktu singkat untuk transisi UI, bukan menunggu 3 detik.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;

    if (session == null || user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.login);
      return;
    }

    // Supabase Auth adalah sumber kebenaran session. Cache lokal hanya untuk UI.
    try {
      await AuthService.cacheUserLocally(user);
    } catch (_) {
      // Session tetap valid meskipun cache profile gagal diperbarui.
    }
    if (!mounted) return;

    final biometricEnabled = await LocalDb.getPref('biometric_enabled');
    if (!mounted) return;

    if (biometricEnabled == '1' || biometricEnabled == 'true') {
      final isSupported = await BiometricService.isSupported();
      if (!mounted) return;

      if (isSupported) {
        final authSuccess = await BiometricService.authenticate();
        if (!mounted) return;

        if (authSuccess) {
          Navigator.pushReplacementNamed(context, Routes.shell);
        } else {
          // Gagal/cancel biometric tidak menghapus session Supabase.
          Navigator.pushReplacementNamed(context, Routes.login);
        }
        return;
      }
    }

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
            TweenAnimationBuilder<double>(
              tween: Tween(begin: -100.0, end: 0.0),
              duration: const Duration(milliseconds: 700),
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
