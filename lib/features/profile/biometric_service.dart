import 'package:local_auth/local_auth.dart';

/// Aplikasi hanya meminta autentikasi sidik jari dari sistem operasi.
/// Data biometrik tidak pernah dibaca atau disimpan oleh EclipseVerse.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isSupported() async {
    try {
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.contains(BiometricType.fingerprint);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Verifikasi sidik jari untuk membuka EclipseVerse',
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}
