import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_db.dart';
import 'offline_auth_service.dart';
import 'secure_store.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim()},
    );
  }

  /// Simpan data tampilan secara lokal; Supabase tetap menjadi sumber data utama.
  static Future<void> cacheUserLocally(User user) async {
    final previousUserId = await LocalDb.getPref('active_user_id');
    if (previousUserId != null && previousUserId.isNotEmpty && previousUserId != user.id) {
      await LocalDb.clearAccountData();
    }

    Map<String, dynamic> profile = <String, dynamic>{};

    try {
      final result = await _client
          .from('profiles')
          .select('display_name, email, role')
          .eq('id', user.id)
          .maybeSingle();
      if (result != null) {
        profile = Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // Login tetap dilanjutkan jika cache profil gagal diperbarui.
    }

    final metadata = user.userMetadata ?? <String, dynamic>{};
    final profileName = profile['display_name']?.toString().trim() ?? '';
    final metadataName = metadata['name']?.toString().trim() ?? '';
    final email = profile['email']?.toString().trim().isNotEmpty == true
        ? profile['email'].toString().trim()
        : (user.email ?? '').trim();
    final name = profileName.isNotEmpty
        ? profileName
        : (metadataName.isNotEmpty
            ? metadataName
            : (email.contains('@') ? email.split('@').first : 'Pengguna'));

    await LocalDb.saveProfile(
      // Gunakan UUID Supabase agar profil setiap akun tetap terpisah.
      userId: user.id,
      name: name,
      email: email,
    );

    // Ambil peran dari data profil yang dilindungi, bukan metadata pengguna.
    await LocalDb.setPref(
      'user_role',
      profile['role'] == 'admin' ? 'admin' : 'user',
    );
    await LocalDb.setPref('active_user_id', user.id);
  }

  static Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } finally {
      // Hapus data akun sebelumnya agar tidak tertinggal pada perangkat bersama.
      await LocalDb.clearAccountData();
      await LocalDb.setPref('active_user_id', '');
      await LocalDb.setPref('biometric_enabled', '0');
      await SecureStore.deleteCredentials();
      await SecureStore.deleteToken();
      await OfflineAuthService.clear();
      await LocalDb.setPref('offline_mode', '0');
    }
  }

  static User? get currentUser => _client.auth.currentUser;

  static Session? get currentSession => _client.auth.currentSession;
}
