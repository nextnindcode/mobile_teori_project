import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';

class SensorService {
  StreamSubscription? _accelSubscription;
  StreamSubscription? _gyroSubscription;

  // Fungsi untuk mendengarkan gerakan HP
  void listenSensors({
    required Function(int direction) onMove,
    required Function() onConfirm,
  }) {
    bool isLocked = false; // Mencegah gerakan terlalu sensitif

    // 1. Accelerometer (Miring kiri/kanan)
    _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (isLocked) return;

      // Jika HP dimiringkan ke kanan (x > 3) -> Pindah ke kanan (+1)
      if (event.x > 3.0) {
        onMove(1);
        _lockTemporarily(() => isLocked = false);
        isLocked = true;
      }
      // Jika HP dimiringkan ke kiri (x < -3) -> Pindah ke kiri (-1)
      else if (event.x < -3.0) {
        onMove(-1);
        _lockTemporarily(() => isLocked = false);
        isLocked = true;
      }
    });

    // 2. Gyroscope (Putar HP untuk konfirmasi)
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      // Jika HP diputar cepat (z > 3.5 rad/s)
      if (event.z.abs() > 3.5) {
        onConfirm();
      }
    });
  }

  // Jeda 600ms sebelum bisa miring lagi
  void _lockTemporarily(VoidCallback unlock) {
    Future.delayed(const Duration(milliseconds: 600), unlock);
  }

  // Selalu matikan sensor saat keluar halaman
  void stopSensors() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
  }
}