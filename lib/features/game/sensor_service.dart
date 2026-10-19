import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription? _accelSubscription;
  StreamSubscription? _gyroSubscription;

  void listenSensors({
    required Function(int direction) onMove,
    required Function() onConfirm,
  }) {
    bool isLocked = false;
    bool isConfirmLocked = false;

    // 1. Accelerometer (Miring ke kiri/kanan untuk geser)
    _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (isLocked) return;

      // Jika HP dimiringkan ke kanan (x > 4)
      if (event.x > 4.0) {
        onMove(1); // Geser ke kanan
        _lockTemporarily(() => isLocked = false);
        isLocked = true;
      }
      // Jika HP dimiringkan ke kiri (x < -4)
      else if (event.x < -4.0) {
        onMove(-1); // Geser ke kiri
        _lockTemporarily(() => isLocked = false);
        isLocked = true;
      }
    });

    // 2. Gyroscope (Anggukkan hp ke depan untuk konfirmasi jawaban)
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      // event.x mendeteksi putaran depan/belakang (seperti mengangguk).
      // Debounce mencegah satu gerakan memicu jawaban berkali-kali.
      if (event.x.abs() > 4.0 && !isConfirmLocked) {
        isConfirmLocked = true;
        onConfirm();
        Future.delayed(const Duration(milliseconds: 800), () {
          isConfirmLocked = false;
        });
      }
    });
  }

  void _lockTemporarily(VoidCallback unlock) {
    Future.delayed(const Duration(milliseconds: 800), unlock);
  }

  void stopSensors() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
  }
}