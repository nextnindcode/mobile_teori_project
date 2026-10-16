import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ZoneOption {
  final String label;
  final String tzName;
  const ZoneOption(this.label, this.tzName);
}

/// Semua tanggal di database adalah UTC.
class TimeService {
  static const wib = ZoneOption('WIB', 'Asia/Jakarta');
  static const wita = ZoneOption('WITA', 'Asia/Makassar');
  static const wit = ZoneOption('WIT', 'Asia/Jayapura');
  static const london = ZoneOption('London', 'Europe/London');
  static const kst = ZoneOption('KST', 'Asia/Seoul');

  /// Zona tujuan yang selalu ditampilkan.
  static const zones = [wib, wita, wit, london];

  /// Zona asal untuk mode manual.
  static const originZones = [wib, wita, wit, london, kst];

  static bool _ready = false;
  static void _ensure() {
    if (_ready) return;
    tzdata.initializeTimeZones(); // diinisialisasi lazy, sekali saja
    _ready = true;
  }

  static tz.TZDateTime at(DateTime utc, String zone) {
    _ensure();
    return tz.TZDateTime.from(utc, tz.getLocation(zone));
  }

  /// Waktu dinding [y-m-d h:mi] di zona asal -> UTC.
  static DateTime toUtc(
      int y, int m, int d, int h, int mi, String originZone) {
    _ensure();
    return tz.TZDateTime(tz.getLocation(originZone), y, m, d, h, mi).toUtc();
  }

  /// label zona -> waktu di zona itu (urut WIB, WITA, WIT, London).
  static Map<String, tz.TZDateTime> convertAll(DateTime utc) => {
        for (final z in zones) z.label: at(utc, z.tzName),
      };
}
