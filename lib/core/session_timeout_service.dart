import 'package:eclipseverse/core/local_db.dart';

/// Batas waktu aplikasi berada di background sebelum sesi perlu login ulang.
/// Diset 2 menit untuk memudahkan pengujian; ubah ke 30 menit setelah demo.
class SessionTimeoutService {
  static const Duration timeout = Duration(minutes: 2);
  static const String _backgroundKey = 'session_background_at';

  static Future<void> markBackgrounded() async {
    final existing = await LocalDb.getPref(_backgroundKey);
    if (existing != null && existing != '0') return;

    await LocalDb.setPref(
      _backgroundKey,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  static Future<bool> hasExpired() async {
    final value = await LocalDb.getPref(_backgroundKey);
    if (value == null || value == '0') return false;

    final timestamp = int.tryParse(value);
    if (timestamp == null) {
      await clearBackgroundTime();
      return false;
    }

    final elapsed = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
    return elapsed >= timeout;
  }

  static Future<void> clearBackgroundTime() async {
    await LocalDb.setPref(_backgroundKey, '0');
  }
}
