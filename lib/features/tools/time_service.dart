import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ZoneOption {
  final String label;
  final String tzName;
  const ZoneOption(this.label, this.tzName);
}

/// Semua tanggal di database adalah UTC.
class TimeService {
  static const wib = ZoneOption('WIB (Jakarta)', 'Asia/Jakarta');
  static const wita = ZoneOption('WITA (Makassar)', 'Asia/Makassar');
  static const wit = ZoneOption('WIT (Jayapura)', 'Asia/Jayapura');
  static const london = ZoneOption('London (UK)', 'Europe/London');
  static const japan = ZoneOption('Jepang (Tokyo)', 'Asia/Tokyo');
  static const singapore = ZoneOption('Singapura', 'Asia/Singapore');
  static const malaysia = ZoneOption('Malaysia (Kuala Lumpur)', 'Asia/Kuala_Lumpur');
  static const thailand = ZoneOption('Thailand (Bangkok)', 'Asia/Bangkok');
  static const kst = ZoneOption('Korea Selatan (Seoul)', 'Asia/Seoul');
  static const china = ZoneOption('China (Shanghai)', 'Asia/Shanghai');

  /// Eight target countries, with Indonesia represented by WIB, WITA, and WIT.
  static const requiredZones = [
    wib,
    wita,
    wit,
    malaysia,
    singapore,
    thailand,
    japan,
    kst,
    china,
    london,
  ];

  /// Zona tujuan yang selalu ditampilkan.
  static const zones = requiredZones;

  /// Zona asal untuk mode manual.
  static const originZones = [wib, wita, wit, malaysia, singapore, thailand, japan, kst, china, london];

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

  /// Label zona -> waktu di zona itu
  static Map<String, tz.TZDateTime> convertAll(DateTime utc) => {
        for (final z in requiredZones) z.label: at(utc, z.tzName),
      };
}
