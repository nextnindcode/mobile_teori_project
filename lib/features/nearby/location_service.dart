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

  // 2. Fungsi untuk meminta izin dan mengambil lokasi user saat ini
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
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );
  }
}