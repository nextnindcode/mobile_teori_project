import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ZoneOption {
  final String label;
  final String tzName;
  final String flag;
  const ZoneOption(this.label, this.tzName, this.flag);
}

/// Semua tanggal di database disimpan sebagai UTC.
class TimeService {
  static const wib = ZoneOption('WIB', 'Asia/Jakarta', '🇮🇩');
  static const wita = ZoneOption('WITA', 'Asia/Makassar', '🇮🇩');
  static const wit = ZoneOption('WIT', 'Asia/Jayapura', '🇮🇩');
  static const london = ZoneOption('London', 'Europe/London', '🇬🇧');
  static const kst = ZoneOption('KST', 'Asia/Seoul', '🇰🇷');
  static const kualaLumpur = ZoneOption('Kuala Lumpur', 'Asia/Kuala_Lumpur', '🇲🇾');
  static const singapore = ZoneOption('Singapore', 'Asia/Singapore', '🇸🇬');
  static const bangkok = ZoneOption('Bangkok', 'Asia/Bangkok', '🇹🇭');
  static const tokyo = ZoneOption('Tokyo', 'Asia/Tokyo', '🇯🇵');

  static const zones = [wib, wita, wit, london, kualaLumpur, singapore, bangkok, tokyo];
  static const originZones = [wib, wita, wit, london, kst, kualaLumpur, singapore, bangkok, tokyo];

  static bool _ready = false;
  static void _ensure() {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready = true;
  }

  static tz.TZDateTime at(DateTime utc, String zone) {
    _ensure();
    return tz.TZDateTime.from(utc.toUtc(), tz.getLocation(zone));
  }

  /// Waktu dinding pada zona asal -> UTC.
  static DateTime toUtc(int y, int m, int d, int h, int mi, String originZone) {
    _ensure();
    return tz.TZDateTime(tz.getLocation(originZone), y, m, d, h, mi).toUtc();
  }

  static Map<String, tz.TZDateTime> convertAll(DateTime utc) => {
        for (final z in zones) z.label: at(utc, z.tzName),
      };
}
