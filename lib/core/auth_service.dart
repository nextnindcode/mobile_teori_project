import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_db.dart';
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

  /// Cache only presentation data locally. Supabase remains the source of truth.
  static Future<void> cacheUserLocally(User user) async {
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
      // Login should not fail just because the profile cache cannot be refreshed.
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
      // The legacy local cache uses an integer key; the real UUID stays in Supabase.
      userId: user.id.hashCode & 0x7fffffff,
      name: name,
      email: email,
    );

    // Never trust role from user metadata; use the protected profile row only.
    await LocalDb.setPref(
      'user_role',
      profile['role'] == 'admin' ? 'admin' : 'user',
    );
  }

  static Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } finally {
      // Remove any legacy API token left by an earlier app version.
      await SecureStore.deleteToken();
    }
  }

  static User? get currentUser => _client.auth.currentUser;

  static Session? get currentSession => _client.auth.currentSession;
}
