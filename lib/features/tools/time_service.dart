// import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/data/latest_all.dart' as tzdata;
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
  static const thailand = ZoneOption('Thailand (Bangkok)', 'Asia/Bangkok');
  static const kst = ZoneOption('KST (Seoul)', 'Asia/Seoul');

  /// Zona yang digunakan untuk hasil konversi (Malaysia sementara dihapus).
  static const requiredZones = [
    wib,
    wita,
    wit,
    london,
    japan,
    singapore,
    thailand,
  ];

  /// Zona tujuan yang selalu ditampilkan.
  static const zones = requiredZones;

  /// Zona asal untuk mode manual.
  static const originZones = [
    wib,
    wita,
    wit,
    london,
    japan,
    singapore,
    thailand,
    kst,
  ];

  static bool _ready = false;
  static void _ensure() {
    if (_ready) return;
    tzdata.initializeTimeZones(); // diinisialisasi lazy, sekali saja
    _ready = true;
  }

  static tz.TZDateTime at(DateTime utc, String zone) {
    _ensure();
    try {
      // Coba cari zona waktunya
      return tz.TZDateTime.from(utc, tz.getLocation(zone));
    } catch (e) {
      // Kalo error balikin ke WIB
      return tz.TZDateTime.from(utc, tz.getLocation('Asia/Jakarta'));
    }
  }

  /// Waktu dinding [y-m-d h:mi] di zona asal -> UTC.
  static DateTime toUtc(int y, int m, int d, int h, int mi, String originZone) {
    _ensure();
    return tz.TZDateTime(tz.getLocation(originZone), y, m, d, h, mi).toUtc();
  }

  /// Label zona -> waktu di zona itu
  static Map<String, tz.TZDateTime> convertAll(DateTime utc) => {
    for (final z in requiredZones) z.label: at(utc, z.tzName),
  };
}
