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

    // 1. Accelerometer dengan miringkan hp ke kiri/kanan untuk memilih jawaban 
    _accelSubscription = accelerometerEventStream().listen(
      (event) {
        if (_moveLocked) return;

        if (event.x > 5.0) {
          _moveLocked = true;
          onMove(1); // Geser Kanan
          _moveCooldown?.cancel();
          _moveCooldown = Timer(const Duration(milliseconds: 1000), () {
            _moveLocked = false;
          });
        } else if (event.x < -5.0) {
          _moveLocked = true;
          onMove(-1); // Geser Kiri
          _moveCooldown?.cancel();
          _moveCooldown = Timer(const Duration(milliseconds: 1000), () {
            _moveLocked = false;
          });
        }
      },
      onError: (Object error) {
        debugPrint('Accelerometer tidak tersedia: $error');
      },
    );

    // 2. Gyroscope dengan menganggukkan hp untuk mengonfirmasi jawaban 
    _gyroSubscription = gyroscopeEventStream().listen(
      (event) {
        if (_confirmLocked || event.x.abs() < 5.0) return;

        _confirmLocked = true;
        onConfirm();
        _confirmCooldown?.cancel();
        _confirmCooldown = Timer(const Duration(milliseconds: 1000), () {
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