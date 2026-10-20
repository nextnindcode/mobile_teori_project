import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  Timer? _moveCooldown;
  Timer? _confirmCooldown;
  bool _moveLocked = false;
  bool _confirmLocked = false;

  void listenSensors({
    required Function(int direction) onMove,
    required Function() onConfirm,
  }) {
    stopSensors();
    _moveLocked = false;
    _confirmLocked = false;

    // Accelerometer mengukur kemiringan HP. Ambang 2.5 m/s² lebih realistis
    // untuk gerakan tangan biasa dibanding ambang yang terlalu tinggi.
    _accelSubscription = accelerometerEventStream().listen(
      (event) {
        if (_moveLocked) return;

        if (event.x > 2.5) {
          _moveLocked = true;
          onMove(1);
          _moveCooldown?.cancel();
          _moveCooldown = Timer(const Duration(milliseconds: 650), () {
            _moveLocked = false;
          });
        } else if (event.x < -2.5) {
          _moveLocked = true;
          onMove(-1);
          _moveCooldown?.cancel();
          _moveCooldown = Timer(const Duration(milliseconds: 650), () {
            _moveLocked = false;
          });
        }
      },
      onError: (Object error) {
        debugPrint('Accelerometer tidak tersedia: $error');
      },
    );

    // Gyroscope menghasilkan kecepatan rotasi dalam rad/s; 4.0 terlalu tinggi
    // untuk anggukan normal. Ambang 1.0 lebih mudah terdeteksi.
    _gyroSubscription = gyroscopeEventStream().listen(
      (event) {
        if (_confirmLocked || event.x.abs() < 1.0) return;

        _confirmLocked = true;
        onConfirm();
        _confirmCooldown?.cancel();
        _confirmCooldown = Timer(const Duration(milliseconds: 900), () {
          _confirmLocked = false;
        });
      },
      onError: (Object error) {
        debugPrint('Gyroscope tidak tersedia: $error');
      },
    );
  }

  void stopSensors() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _moveCooldown?.cancel();
    _confirmCooldown?.cancel();
    _accelSubscription = null;
    _gyroSubscription = null;
    _moveCooldown = null;
    _confirmCooldown = null;
  }
}
