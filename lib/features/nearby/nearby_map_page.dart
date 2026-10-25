import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../event/event_model.dart';

class NearbyMapPage extends StatefulWidget {
  final List<Event> events;
  final double userLat;
  final double userLon;

  const NearbyMapPage({
    super.key,
    required this.events,
    required this.userLat,
    required this.userLon,
  });

  @override
  State<NearbyMapPage> createState() => _NearbyMapPageState();
}

class _NearbyMapPageState extends State<NearbyMapPage> {
  final MapController _mapController = MapController();
  StreamSubscription<MagnetometerEvent>? _magnetometer;
  double? _headingDegrees;
  Event? _selectedEvent;
  List<LatLng> _routePoints = [];
  bool _loadingRoute = false;
  String? _routeError;

  @override
  void initState() {
    super.initState();
    _selectedEvent = widget.events.isEmpty ? null : widget.events.first;
    _magnetometer = magnetometerEventStream().listen((event) {
      final heading =
          (math.atan2(event.x, event.y) * 180 / math.pi + 360) % 360;
      if (mounted) setState(() => _headingDegrees = heading);
    }, onError: (_) {
      if (mounted) setState(() => _headingDegrees = null);
    });
    if (_selectedEvent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRoute(_selectedEvent!);
      });
    }
  }

  @override
  void dispose() {
    _magnetometer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _selectEvent(Event event) async {
    setState(() {
      _selectedEvent = event;
      _routePoints = [];
      _routeError = null;
    });
    await _loadRoute(event);
  }

  Future<void> _loadRoute(Event event) async {
    if (!_validCoordinate(event.latitude, event.longitude)) {
      if (mounted) {
        setState(() => _routeError = 'Koordinat lokasi event tidak valid.');
      }
      return;
    }

    setState(() {
      _loadingRoute = true;
      _routeError = null;
    });

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${widget.userLon},${widget.userLat};'
        '${event.longitude},${event.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Layanan rute tidak merespons.');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List? ?? [];
      if (routes.isEmpty) throw Exception('Rute berkendara tidak ditemukan.');

      final geometry = routes.first['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List;
      final points = coordinates.map((pair) {
        final values = pair as List;
        return LatLng(
          (values[1] as num).toDouble(),
          (values[0] as num).toDouble(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _routePoints = points;
        _loadingRoute = false;
      });

      if (points.length > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapController.fitCamera(
            CameraFit.coordinates(
              coordinates: points,
              padding: const EdgeInsets.fromLTRB(48, 140, 48, 110),
            ),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRoute = false;
        _routeError = 'Rute belum tersedia. Periksa koneksi internet lalu pilih event lagi.';
      });
    }
  }

  bool _validCoordinate(double lat, double lon) =>
      lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180 &&
      !(lat == 0 && lon == 0);

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
        ? null
        : (bearing - _headingDegrees! + 360) % 360;

    return Scaffold(
      appBar: AppBar(title: const Text('Peta & Kompas Event')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.userLat, widget.userLon),
              initialZoom: 13,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.eclipseverse.app',
              ),
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: Colors.deepPurple,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(widget.userLat, widget.userLon),
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                  ...widget.events.where((e) => _validCoordinate(e.latitude, e.longitude)).map(
                    (event) => Marker(
                      point: LatLng(event.latitude, event.longitude),
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () => _selectEvent(event),
                        child: Icon(
                          Icons.location_on,
                          color: target?.id == event.id ? Colors.amber : Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: relative == null
                          ? const Icon(Icons.explore, size: 38)
                          : Transform.rotate(
                              angle: relative * math.pi / 180,
                              child: const Icon(
                                Icons.navigation,
                                size: 38,
                                color: Colors.deepPurple,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            target?.title ?? 'Pilih event',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _headingDegrees == null
                                ? 'Kompas menunggu data sensor.'
                                : 'Arah HP ${_headingDegrees!.round()}° · tujuan ${bearing!.round()}°',
                          ),
                          if (target != null)
                            Text(
                              '${target.venue}, ${target.city}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (_loadingRoute)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: LinearProgressIndicator(),
                            )
                          else if (_routeError != null)
                            Text(
                              _routeError!,
                              style: const TextStyle(color: Colors.red, fontSize: 11),
                            )
                          else if (_routePoints.isNotEmpty)
                            const Text(
                              'Rute berkendara ditampilkan',
                              style: TextStyle(color: Colors.green, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              child: SizedBox(
                height: 62,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  children: widget.events.map((event) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          event.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: target?.id == event.id,
                        onSelected: (_) => _selectEvent(event),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
