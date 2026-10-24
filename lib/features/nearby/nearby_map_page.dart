import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../event/event_model.dart';

class NearbyMapPage extends StatefulWidget {
  final List<Event> events;
  final double userLat;
  final double userLon;
  const NearbyMapPage({super.key, required this.events, required this.userLat, required this.userLon});
  @override
  State<NearbyMapPage> createState() => _NearbyMapPageState();
}

class _NearbyMapPageState extends State<NearbyMapPage> {
  StreamSubscription<MagnetometerEvent>? _magnetometer;
  double? _headingDegrees;
  Event? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _selectedEvent = widget.events.isEmpty ? null : widget.events.first;
    _magnetometer = magnetometerEventStream().listen((event) {
      final heading = (math.atan2(event.x, event.y) * 180 / math.pi + 360) % 360;
      if (mounted) setState(() => _headingDegrees = heading);
    }, onError: (_) {
      if (mounted) setState(() => _headingDegrees = null);
    });
  }

  @override
  void dispose() {
    _magnetometer?.cancel();
    super.dispose();
  }

  double _bearingTo(Event event) {
    final lat1 = widget.userLat * math.pi / 180;
    final lat2 = event.latitude * math.pi / 180;
    final deltaLon = (event.longitude - widget.userLon) * math.pi / 180;
    final y = math.sin(deltaLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    final target = _selectedEvent;
    final bearing = target == null ? null : _bearingTo(target);
    final relative = bearing == null || _headingDegrees == null
        ? null : (bearing - _headingDegrees! + 360) % 360;
    return Scaffold(
      appBar: AppBar(title: const Text('Peta & Kompas Event')),
      body: Stack(children: [
        FlutterMap(
          options: MapOptions(initialCenter: LatLng(widget.userLat, widget.userLon), initialZoom: 5),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.eclipseverse.app'),
            MarkerLayer(markers: [
              Marker(point: LatLng(widget.userLat, widget.userLon), width: 40, height: 40,
                child: const Icon(Icons.my_location, color: Colors.blue, size: 30)),
              ...widget.events.map((event) => Marker(
                point: LatLng(event.latitude, event.longitude), width: 48, height: 48,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedEvent = event),
                  child: Icon(Icons.location_on, color: target?.id == event.id ? Colors.amber : Colors.red, size: 40),
                ),
              )),
            ]),
          ],
        ),
        Positioned(left: 12, right: 12, top: 12, child: Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(width: 58, height: 58,
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(16)),
              child: relative == null ? const Icon(Icons.explore, size: 38)
                : Transform.rotate(angle: relative * math.pi / 180,
                    child: const Icon(Icons.navigation, size: 38, color: Colors.deepPurple))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(target?.title ?? 'Pilih event', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(_headingDegrees == null ? 'Kompas belum tersedia atau belum mendapatkan data sensor.'
                : 'Arah HP ${_headingDegrees!.round()}° · tujuan ${bearing!.round()}°'),
              if (target != null) Text('${target.venue}, ${target.city}', maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ))),
        Positioned(left: 12, right: 12, bottom: 12, child: Card(child: SizedBox(height: 62, child: ListView(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          children: widget.events.map((event) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(event.title, overflow: TextOverflow.ellipsis),
              selected: target?.id == event.id, onSelected: (_) => setState(() => _selectedEvent = event)),
          )).toList(),
        )))),
      ]),
    );
  }
}
