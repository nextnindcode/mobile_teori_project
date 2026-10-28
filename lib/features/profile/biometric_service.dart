import 'package:local_auth/local_auth.dart';

/// Menyediakan pemeriksaan dukungan perangkat dan autentikasi biometrik.
/// Aplikasi tidak menyimpan data biometrik; sistem operasi hanya mengembalikan status berhasil atau gagal.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isSupported() async {
    try {
      final deviceOk = await _auth.isDeviceSupported();
      if (!deviceOk) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Verifikasi untuk membuka EclipseVerse',
      );
    } catch (_) {
      // Jika dibatalkan, gagal, atau tidak didukung, kembalikan false.
      return false;
    }
  }
}
