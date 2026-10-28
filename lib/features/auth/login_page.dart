import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/offline_auth_service.dart';

import '../../core/auth_service.dart';
import '../../core/local_db.dart';
import '../../core/routes.dart';
import '../../core/session_timeout_service.dart';
import '../../core/secure_store.dart';
import '../../theme/app_theme.dart';
import '../profile/biometric_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await AuthService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final user = response.user;
      if (user == null) throw Exception('Login gagal.');

      await AuthService.cacheUserLocally(user);
      final cachedProfile = await LocalDb.getProfile(user.id);
      if (cachedProfile != null) {
        await OfflineAuthService.saveCredentials(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          userId: user.id,
          name: cachedProfile['name']?.toString() ?? 'Pengguna',
          profileEmail: cachedProfile['email']?.toString() ?? _emailController.text.trim(),
        );
      }
      await LocalDb.setPref('offline_mode', '0');
      await SessionTimeoutService.clearBackgroundTime();
      if (!mounted) return;

      // Simpan kredensial biometrik setelah login berhasil.
      final isSupported = await BiometricService.isSupported();
      if (isSupported) {
        await SecureStore.saveCredentials(
          _emailController.text.trim(),
          _passwordController.text,
        );
        await LocalDb.setPref('biometric_enabled', '1');
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.shell, (_) => false);
    } on AuthException catch (e) {
      if (e.statusCode == null) {
        final signedInOffline = await _tryOfflineLogin();
        if (signedInOffline) return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      final signedInOffline = await _tryOfflineLogin();
      if (signedInOffline) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _tryOfflineLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return false;

    final profile = await OfflineAuthService.verify(
      email: email,
      password: password,
    );
    if (profile == null) return false;
    await _openOfflineProfile(profile);
    return true;
  }

  Future<void> _openOfflineProfile(OfflineProfile profile) async {
    await LocalDb.saveProfile(
      userId: profile.userId,
      name: profile.name,
      email: profile.email,
    );
    await LocalDb.setPref('active_user_id', profile.userId);
    await LocalDb.setPref('user_role', 'user');
    await LocalDb.setPref('offline_mode', '1');
    await SessionTimeoutService.clearBackgroundTime();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Login offline berhasil. Fitur yang membutuhkan internet mungkin belum tersedia.',
        ),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, Routes.shell, (_) => false);
  }

  Future<void> _loginBiometric() async {
    final authSuccess = await BiometricService.authenticate();
    if (!mounted) return;

    if (!authSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifikasi biometrik gagal atau dibatalkan.'),
        ),
      );
      return;
    }

    // Ambil kredensial yang tersimpan dengan aman.
    final creds = await SecureStore.getCredentials();
    if (!mounted) return;

    if (creds == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada data sidik jari. Silakan isi email & password dulu.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Coba autentikasi ulang melalui Supabase.
      final response = await AuthService.login(
        email: creds['email']!,
        password: creds['password']!,
      );

      await AuthService.cacheUserLocally(response.user!);
      await SessionTimeoutService.clearBackgroundTime();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.shell, (_) => false);
    } on AuthException catch (e) {
      if (e.statusCode == null) {
        final offlineProfile = await OfflineAuthService.verify(
          email: creds['email']!,
          password: creds['password']!,
        );
        if (offlineProfile != null) {
          await _openOfflineProfile(offlineProfile);
          return;
        }
      } else {
        await SecureStore.deleteCredentials();
        await LocalDb.setPref('biometric_enabled', '0');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.statusCode == null
                  ? 'Login biometrik tidak dapat terhubung. Periksa koneksi atau gunakan login offline.'
                  : 'Kredensial biometrik sudah tidak valid. Silakan login dengan email dan kata sandi terbaru.',
            ),
          ),
        );
      }
    } catch (e) {
      final offlineProfile = await OfflineAuthService.verify(
        email: creds['email']!,
        password: creds['password']!,
      );
      if (offlineProfile != null) {
        await _openOfflineProfile(offlineProfile);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal login: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ===== 1. ILUSTRASI GERHANA =====
                  Stack(
                    alignment: Alignment.center,
                    children: [
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
                      Transform.translate(
                        offset: const Offset(-30, 0),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: AppTheme.background,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ===== 2. JUDUL HALAMAN =====
                  Text(
                    'EclipseVerse',
                    style: AppTheme.textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masuk untuk melanjutkan',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  // ===== 3. FORMULIR EMAIL =====
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Email wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // ===== 4. FORMULIR KATA SANDI =====
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Password wajib diisi' : null,
                  ),
                  const SizedBox(height: 24),

                  // ===== 5. TOMBOL MASUK =====
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login', style: TextStyle(fontSize: 16)),
                    ),
                  ),

                  // ===== 6. PEMBATAS METODE MASUK =====
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'atau',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ===== 7. TOMBOL MASUK BIOMETRIK =====
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginBiometric,
                      icon: const Icon(Icons.fingerprint, size: 28),
                      label: const Text(
                        'Login dengan sidik jari',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryDark,
                        side: const BorderSide(
                          color: AppTheme.primaryDark,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ===== 8. TAUTAN PENDAFTARAN =====
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, Routes.register),
                    child: const Text('Belum punya akun? Daftar di sini'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
