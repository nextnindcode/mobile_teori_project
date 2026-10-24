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
      setState(() {
        _heading = event.heading;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String _getDirectionText(double? heading) {
    if (heading == null) return 'Memuat...';
    if (heading >= 337.5 || heading < 22.5) return 'Utara (N)';
    if (heading >= 22.5 && heading < 67.5) return 'Timur Laut (NE)';
    if (heading >= 67.5 && heading < 112.5) return 'Timur (E)';
    if (heading >= 112.5 && heading < 157.5) return 'Tenggara (SE)';
    if (heading >= 157.5 && heading < 202.5) return 'Selatan (S)';
    if (heading >= 202.5 && heading < 247.5) return 'Barat Daya (SW)';
    if (heading >= 247.5 && heading < 292.5) return 'Barat (W)';
    if (heading >= 292.5 && heading < 337.5) return 'Barat Laut (NW)';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_heading == null) {
      return const Center(
        child: Text(
          'Sensor kompas tidak tersedia', 
          style: TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getDirectionText(_heading),
          style: AppTheme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryDark, width: 3),
            color: AppTheme.white,
          ),
          child: Transform.rotate(
            angle: -(_heading! * (pi / 180)), 
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 8,
                  child: Icon(Icons.navigation, size: 30, color: Colors.red.shade700),
                ),
                Positioned(top: 2, child: Text('N', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700))),
                Positioned(bottom: 2, child: Text('S', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark))),
                Positioned(left: 4, child: Text('W', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark))),
                Positioned(right: 4, child: Text('E', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}