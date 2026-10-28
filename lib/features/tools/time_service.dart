import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ZoneOption {
  final String label;
  final String tzName;
  const ZoneOption(this.label, this.tzName);
}

/// Waktu input ditafsirkan sesuai zona asal, lalu dinormalisasi ke UTC.
class TimeService {
  static const wib = ZoneOption('WIB (Jakarta)', 'Asia/Jakarta');
  static const wita = ZoneOption('WITA (Makassar)', 'Asia/Makassar');
  static const wit = ZoneOption('WIT (Jayapura)', 'Asia/Jayapura');
  static const london = ZoneOption('London (UK)', 'Europe/London');

  /// Zona hasil yang ditampilkan. Malaysia sementara tidak disertakan.
  static const requiredZones = [wib, wita, wit, london];
  static const zones = requiredZones;
  static const originZones = requiredZones;

  static bool _ready = false;

  static void _ensure() {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready = true;
  }

  /// Konversi satu waktu absolut ke zona tujuan.
  static tz.TZDateTime at(DateTime instant, String zone) {
    _ensure();
    return tz.TZDateTime.from(instant.toUtc(), tz.getLocation(zone));
  }

  /// Waktu lokal yang dipilih pengguna di zona asal -> UTC.
  static DateTime toUtc(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    String originZone,
  ) {
    _ensure();
    return tz.TZDateTime(
      tz.getLocation(originZone),
      year,
      month,
      day,
      hour,
      minute,
    ).toUtc();
  }

  static Map<String, tz.TZDateTime> convertAll(DateTime instant) {
    final utc = instant.toUtc();
    return {
      for (final zone in requiredZones) zone.label: at(utc, zone.tzName),
    };
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
