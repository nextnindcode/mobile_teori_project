import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../theme/app_theme.dart';

class CompassWidget extends StatefulWidget {
  const CompassWidget({super.key});

  @override
  State<CompassWidget> createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<CompassWidget> {
  double? _heading;
  StreamSubscription<CompassEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() {
          _heading = event.heading;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan jika sensor kompas tidak ada di HP
    if (_heading == null) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceElevated,
          border: Border.all(color: Colors.grey, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.explore_off, size: 30, color: Colors.grey),
        ),
      );
    }

    // Tampilan Kompas Visual Saja
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surfaceElevated,
        border: Border.all(color: AppTheme.coolCyan, width: 2),
      ),
      child: Transform.rotate(
        // Jarum berputar berlawanan arah dengan HP
        angle: -(_heading! * (pi / 180)), 
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Jarum Merah (Utara)
            Positioned(
              top: 4,
              child: Icon(Icons.navigation, size: 22, color: Colors.red.shade700),
            ),
            // Huruf Mata Angin (N, E, S, W)
            Positioned(top: 1, child: Text('N', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.red.shade700))),
            Positioned(bottom: 1, child: Text('S', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))),
            Positioned(left: 2, child: Text('W', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))),
            Positioned(right: 2, child: Text('E', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))),
          ],
        ),
      ),
    );
  }
}