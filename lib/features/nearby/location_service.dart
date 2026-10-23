import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // 1. Fungsi Haversine (menghitung jarak antara 2 koordinat dalam km)
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Radius bumi dalam km
    double rad(double d) => d * pi / 180;

    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(rad(lat1)) * cos(rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    
    return 2 * r * asin(sqrt(a));
  }

  // 2. Fungsi untuk menghitung arah mata angin 
  static String getDirection(double lat1, double lon1, double lat2, double lon2) {
    double dLon = (lon2 - lon1) * (pi / 180);
    double lat1Rad = lat1 * (pi / 180);
    double lat2Rad = lat2 * (pi / 180);
    
    double y = sin(dLon) * cos(lat2Rad);
    double x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
    
    double bearing = atan2(y, x) * (180 / pi);
    bearing = (bearing + 360) % 360; // Normalisasi 0-360
    
    if (bearing >= 337.5 || bearing < 22.5) return 'Utara';
    if (bearing >= 22.5 && bearing < 67.5) return 'Timur Laut';
    if (bearing >= 67.5 && bearing < 112.5) return 'Timur';
    if (bearing >= 112.5 && bearing < 157.5) return 'Tenggara';
    if (bearing >= 157.5 && bearing < 202.5) return 'Selatan';
    if (bearing >= 202.5 && bearing < 247.5) return 'Barat Daya';
    if (bearing >= 247.5 && bearing < 292.5) return 'Barat';
    if (bearing >= 292.5 && bearing < 337.5) return 'Barat Laut';
    return 'Tidak diketahui';
  }

  // 3. Fungsi untuk meminta izin dan mengambil lokasi user saat ini
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah GPS (layanan lokasi) menyala/aktif 
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi (GPS) tidak aktif.');
    }

    // Cek izin lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Buka pengaturan.');
    }

    // Ambil lokasi
    return await Geolocator.getCurrentPosition();
  }
}