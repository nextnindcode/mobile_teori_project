import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ZoneOption {
  final String label;
  final String tzName;
  const ZoneOption(this.label, this.tzName);
}

/// Implementasi awal konversi waktu dengan zona WIB, WITA, WIT, dan London.
class TimeService {
  static const wib = ZoneOption('WIB (Jakarta)', 'Asia/Jakarta');
  static const wita = ZoneOption('WITA (Makassar)', 'Asia/Makassar');
  static const wit = ZoneOption('WIT (Jayapura)', 'Asia/Jayapura');
  static const london = ZoneOption('London (UK)', 'Europe/London');

  static const requiredZones = [wib, wita, wit, london];
  static const zones = requiredZones;
  static const originZones = requiredZones;

  static bool _ready = false;

  static void _ensure() {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready = true;
  }

  static tz.TZDateTime at(DateTime instant, String zone) {
    _ensure();
    return tz.TZDateTime.from(instant.toUtc(), tz.getLocation(zone));
  }

  /// Waktu lokal yang dipilih pada zona asal dikonversi menjadi UTC.
  static DateTime toUtc(int y, int m, int d, int h, int mi, String originZone) {
    _ensure();
    return tz.TZDateTime(tz.getLocation(originZone), y, m, d, h, mi).toUtc();
  }

  static Map<String, tz.TZDateTime> convertAll(DateTime instant) {
    final utc = instant.toUtc();
    return {for (final zone in requiredZones) zone.label: at(utc, zone.tzName)};
  }

  static String flag(String zone) {
    const flags = {
      'Asia/Jakarta': '🇮🇩',
      'Asia/Makassar': '🇮🇩',
      'Asia/Jayapura': '🇮🇩',
      'Europe/London': '🇬🇧',
    };
    return flags[zone] ?? '🌐';
  }

  static String zoneCode(String label) {
    for (final zone in requiredZones) {
      if (zone.label == label) return zone.tzName;
    }
    return '';
  }
}
