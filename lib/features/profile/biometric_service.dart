import 'package:local_auth/local_auth.dart';

/// Kontrak serah-terima H11 (ke A): isSupported() dan authenticate() -> bool.
/// Aplikasi tidak menyimpan data biometrik; OS hanya mengembalikan berhasil/gagal.
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
      // dibatalkan, gagal, atau tidak didukung -> false
      return false;
    }
  }
}
