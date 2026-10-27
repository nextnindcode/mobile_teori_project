import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_service.dart';
import '../../core/local_db.dart';
import '../../core/secure_store.dart';
import '../../theme/app_theme.dart';
import '../../core/routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await AuthService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      final user = response.user;
      if (user == null) {
        throw Exception('Registrasi gagal. Silakan coba lagi.');
      }

      // A newly created account must not inherit leftover local state from a prior account.
      await LocalDb.clearAccountData();
      await LocalDb.setPref('active_user_id', '');
      await LocalDb.setPref('biometric_enabled', '0');
      await SecureStore.deleteCredentials();

      // =========================================================
      // TAMBAHAN BAGIAN C: SIMPAN NOTIFIKASI WELCOME KE INBOX
      // =========================================================
      try {
        await Supabase.instance.client.from('notifications').insert({
          'user_id': user.id,
          'title': 'Selamat Datang di EclipseVerse! 🌟',
          'message': 'Halo ${_nameController.text}, selamat bergabung di semesta Eclipse. Jangan lupa lengkapi profilmu dan mainkan Mini Game untuk mendapatkan Photocard!',
          'type': 'system',
        });
      } catch (e) {
        // Jika gagal simpan notif, registrasi tetap lanjut
        debugPrint('Gagal menyimpan notifikasi welcome: $e');
      }
      // =========================================================

      if (response.session != null) {
        await AuthService.cacheUserLocally(user);
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, Routes.shell, (_) => false);
      } else {
        // Supabase email confirmation is enabled: user must confirm before login.
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Registrasi berhasil. Periksa email untuk konfirmasi, lalu login.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registrasi gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryDark,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ===== 1. GAMBAR ATAS (ANIMASI GERHANA) =====
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
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
                        offset: const Offset(-25, 0), // Bulan geser nutupin
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppTheme.background,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ===== 2. JUDUL =====
                  Text(
                    'Buat Akun',
                    style: AppTheme.textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bergabunglah dengan EclipseVerse',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  // ===== 3. FORM NAMA =====
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // ===== 4. FORM EMAIL =====
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) =>
                        val!.isEmpty ? 'Email wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // ===== 5. FORM PASSWORD =====
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
                        val!.length < 8 ? 'Password minimal 8 karakter' : null,
                  ),
                  const SizedBox(height: 32),

                  // ===== 6. TOMBOL DAFTAR =====
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Daftar',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== 7. LINK KEMBALI KE LOGIN =====
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Balik ke halaman Login
                    },
                    child: const Text('Sudah punya akun? Login di sini'),
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