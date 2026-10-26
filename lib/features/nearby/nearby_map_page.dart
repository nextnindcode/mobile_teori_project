import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart'; 

import '../event/event_model.dart';
import 'compass_widget.dart'; 
import '../../theme/app_theme.dart';

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
  StreamSubscription<CompassEvent>? _compassSubscription; 
  double? _headingDegrees;
  Event? _selectedEvent;
  List<LatLng> _routePoints = [];
  double? _routeDistanceKm;
  int? _routeDurationMinutes;
  bool _loadingRoute = false;
  String? _routeError;

  @override
  void initState() {
    super.initState();
    _selectedEvent = widget.events.isEmpty ? null : widget.events.first;
    
    // 1. Inisialisasi Sensor Kompas menggunakan FlutterCompass
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() {
          _headingDegrees = event.heading; // Ambil nilai heading yang sudah terkalibrasi
        });
      }
    }, onError: (_) {
      if (mounted) setState(() => _headingDegrees = null);
    });

    // 2. Load rute pertama kali
    if (_selectedEvent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRoute(_selectedEvent!);
      });
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _selectEvent(Event event) async {
    setState(() {
      _selectedEvent = event;
      _routePoints = [];
      _routeDistanceKm = null;
      _routeDurationMinutes = null;
      _routeError = null;
    });
    await _loadRoute(event);
  }

  // 3. Mengambil Rute via OSRM API
  Future<void> _loadRoute(Event event) async {
    if (!_validCoordinate(event.latitude, event.longitude)) {
      if (mounted) setState(() => _routeError = 'Koordinat lokasi event tidak valid.');
      return;
    }

    setState(() {
      _loadingRoute = true;
      _routeDistanceKm = null;
      _routeDurationMinutes = null;
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
      if (response.statusCode != 200) throw Exception('Layanan rute tidak merespons.');

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List? ?? [];
      if (routes.isEmpty) throw Exception('Rute berkendara tidak ditemukan.');

      final route = Map<String, dynamic>.from(routes.first as Map);
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List;
      final distanceKm = ((route['distance'] as num?)?.toDouble() ?? 0) / 1000;
      final durationMinutes = (((route['duration'] as num?)?.toDouble() ?? 0) / 60).ceil();
      final points = coordinates.map((pair) {
        final values = pair as List;
        return LatLng((values[1] as num).toDouble(), (values[0] as num).toDouble());
      }).toList();

      if (!mounted) return;
      setState(() {
        _routePoints = points;
        _routeDistanceKm = distanceKm;
        _routeDurationMinutes = durationMinutes;
        _loadingRoute = false;
      });

      // 4. Zoom kamera peta agar muat seluruh garis rute
      if (points.length > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapController.fitCamera(
            CameraFit.coordinates(
              coordinates: points,
              padding: const EdgeInsets.fromLTRB(48, 140, 48, 48), 
            ),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRoute = false;
        _routeDistanceKm = null;
        _routeDurationMinutes = null;
        _routeError = 'Rute belum tersedia. Periksa koneksi internet lalu pilih event lagi.';
      });
    }
  }

  bool _validCoordinate(double lat, double lon) =>
      lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180 && !(lat == 0 && lon == 0);

  double _bearingTo(Event event) {
    final lat1 = widget.userLat * math.pi / 180;
    final lat2 = event.latitude * math.pi / 180;
    final deltaLon = (event.longitude - widget.userLon) * math.pi / 180;
    final y = math.sin(deltaLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);
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
      appBar: AppBar(
        title: const Text('Peta & Rute Event'),
        backgroundColor: AppTheme.deepSpace,
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            // --- 1. PETA UTAMA ---
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(widget.userLat, widget.userLon),
                initialZoom: 13,
                minZoom: 3,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.eclipseverse.app',
                ),
                
                // Garis Rute (Polyline)
                if (_routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5,
                        color: AppTheme.eclipseViolet,
                      ),
                    ],
                  ),
                  
                // Marker
                MarkerLayer(
                  markers: [
                    // Titik User
                    Marker(
                      point: LatLng(widget.userLat, widget.userLon),
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                    // Titik Event
                    ...widget.events.where((e) => _validCoordinate(e.latitude, e.longitude)).map(
                      (event) => Marker(
                        point: LatLng(event.latitude, event.longitude),
                        width: 48,
                        height: 48,
                        child: GestureDetector(
                          onTap: () => _selectEvent(event),
                          child: Icon(
                            Icons.location_on,
                            color: target?.id == event.id ? AppTheme.coronaGold : Colors.red,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [TextSourceAttribution('OpenStreetMap contributors')],
                ),
              ],
            ),

            // 2. Kartu Info Rute 
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Card(
                color: AppTheme.surfaceElevated,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppTheme.deepSpace,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: relative == null
                            ? const Icon(Icons.explore, size: 38, color: Colors.white)
                            : Transform.rotate(
                                angle: relative * math.pi / 180,
                                child: const Icon(Icons.navigation, size: 38, color: AppTheme.coolCyan),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              target?.title ?? 'Pilih event',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _headingDegrees == null
                                  ? 'Kompas menunggu data sensor.'
                                  : 'Arah HP ${_headingDegrees!.round()}° · Tujuan ${bearing!.round()}°',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            if (target != null)
                              Text(
                                '${target.venue}, ${target.city}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            if (_loadingRoute)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: LinearProgressIndicator(color: AppTheme.coolCyan),
                              )
                            else if (_routeError != null)
                              Text(_routeError!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.error, fontSize: 11))
                            else if (_routePoints.isNotEmpty)
                              Text(
                                'Rute ${_routeDistanceKm?.toStringAsFixed(1) ?? '-'} km • sekitar ${_routeDurationMinutes ?? '-'} menit',
                                style: const TextStyle(color: AppTheme.success, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Kompas Melayang 
            Positioned(
              top: 120,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(50), 
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: const CompassWidget(), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}