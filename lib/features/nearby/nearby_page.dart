import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart';
import '../event/event_model.dart';
import '../event/event_service.dart';
import 'compass_widget.dart';
import 'location_service.dart';

class NearbyPage extends StatefulWidget {
  final int? initialEventId;
  const NearbyPage({super.key, this.initialEventId});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  final MapController _mapController = MapController();
  StreamSubscription<CompassEvent>? _compassSubscription;

  bool _loading = true;
  String? _error;
  Position? _userPosition;
  List<Event> _activeEvents = [];
  Event? _selectedEvent;

  double? _headingDegrees;
  List<LatLng> _routePoints = [];
  bool _loadingRoute = false;
  String? _routeError;

  // Default fallback center: Jakarta Monas
  static const double _defaultLat = -6.175392;
  static const double _defaultLon = 106.827153;

  @override
  void initState() {
    super.initState();
    _initCompass();
    _loadNearbyData();
  }

  void _initCompass() {
    _compassSubscription = FlutterCompass.events?.listen(
      (event) {
        if (mounted) {
          setState(() {
            _headingDegrees = event.heading;
          });
        }
      },
      onError: (_) {
        if (mounted) setState(() => _headingDegrees = null);
      },
    );
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Fetch user location (graceful fallback)
      try {
        _userPosition = await LocationService.getCurrentLocation();
      } catch (locErr) {
        debugPrint('Location service note: $locErr');
      }

      // 2. Fetch events and filter upcoming/ongoing only
      final allEvents = await EventService.fetchEvents();
      final now = DateTime.now().toUtc();

      // Only show upcoming / ongoing events (not past)
      final filtered = allEvents.where((e) {
        final notPast = e.eventDate.isAfter(
          now.subtract(const Duration(hours: 12)),
        );
        final validCoords = _validCoordinate(e.latitude, e.longitude);
        return notPast && validCoords;
      }).toList();

      final routeArg = ModalRoute.of(context)?.settings.arguments;
      final requestedId = widget.initialEventId ?? (routeArg is int ? routeArg : null);
      // Saat dipanggil dari detail, pertahankan event yang diminta meski bukan event mendatang.
      if (requestedId != null && !filtered.any((event) => event.id == requestedId)) {
        try {
          final requestedEvent = await EventService.fetchEventDetail(requestedId);
          if (_validCoordinate(requestedEvent.latitude, requestedEvent.longitude)) {
            filtered.insert(0, requestedEvent);
          }
        } catch (_) {
          // Jangan mengganti event yang gagal dimuat dengan event acak.
        }
      }

      // Sort by distance if user position is available
      if (_userPosition != null) {
        filtered.sort((a, b) {
          final distA = LocationService.distanceKm(
            _userPosition!.latitude,
            _userPosition!.longitude,
            a.latitude,
            a.longitude,
          );
          final distB = LocationService.distanceKm(
            _userPosition!.latitude,
            _userPosition!.longitude,
            b.latitude,
            b.longitude,
          );
          return distA.compareTo(distB);
        });
      }

      if (!mounted) return;
      setState(() {
        _activeEvents = filtered;
        _loading = false;
        if (filtered.isNotEmpty) {
          _selectedEvent = requestedId == null
              ? filtered.first
              : filtered.where((event) => event.id == requestedId).firstOrNull;
        }
      });

      if (_selectedEvent != null && _userPosition != null) {
        _loadRoute(_selectedEvent!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  bool _validCoordinate(double lat, double lon) =>
      lat >= -90 &&
      lat <= 90 &&
      lon >= -180 &&
      lon <= 180 &&
      !(lat == 0 && lon == 0);

  Future<void> _selectEvent(Event event) async {
    setState(() {
      _selectedEvent = event;
      _routePoints = [];
      _routeError = null;
    });

    _showEventBottomSheet(event);

    if (_userPosition != null) {
      await _loadRoute(event);
    }
  }

  Future<void> _loadRoute(Event event) async {
    final pos = _userPosition;
    if (pos == null) return;

    setState(() {
      _loadingRoute = true;
      _routeError = null;
    });

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${pos.longitude},${pos.latitude};'
        '${event.longitude},${event.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 12));
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
        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.fromLTRB(48, 140, 48, 140),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRoute = false;
        _routeError = 'Rute belum tersedia saat ini.';
      });
    }
  }

  double _bearingTo(Event event) {
    final lat = _userPosition?.latitude ?? _defaultLat;
    final lon = _userPosition?.longitude ?? _defaultLon;
    final lat1 = lat * math.pi / 180;
    final lat2 = event.latitude * math.pi / 180;
    final deltaLon = (event.longitude - lon) * math.pi / 180;
    final y = math.sin(deltaLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  void _showEventBottomSheet(Event event) {
    final double? distance = _userPosition != null
        ? LocationService.distanceKm(
            _userPosition!.latitude,
            _userPosition!.longitude,
            event.latitude,
            event.longitude,
          )
        : null;

    final String? direction = _userPosition != null
        ? LocationService.getDirection(
            _userPosition!.latitude,
            _userPosition!.longitude,
            event.latitude,
            event.longitude,
          )
        : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppTheme.eclipseViolet, width: 2),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.coronaGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.coronaGold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'EVENT AKTIF',
                      style: TextStyle(
                        color: AppTheme.coronaGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (distance != null)
                    Text(
                      '${distance.toStringAsFixed(1)} km ($direction)',
                      style: const TextStyle(
                        color: AppTheme.coolCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${event.venue}, ${event.city}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _mapController.move(
                          LatLng(event.latitude, event.longitude),
                          14,
                        );
                      },
                      icon: const Icon(Icons.center_focus_strong, size: 18),
                      label: const Text('Fokus Peta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.coolCyan,
                        side: const BorderSide(color: AppTheme.coolCyan),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(
                          context,
                          Routes.eventDetail,
                          arguments: event.id,
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Detail Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.eclipseViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final curLat = _userPosition?.latitude ?? _defaultLat;
    final curLon = _userPosition?.longitude ?? _defaultLon;
    final target = _selectedEvent;
    final bearing = target == null ? null : _bearingTo(target);
    final relative = bearing == null || _headingDegrees == null
        ? null
        : (bearing - _headingDegrees! + 360) % 360;

    return Scaffold(
      backgroundColor: AppTheme.deepSpace,
      appBar: AppBar(
        title: const Text('Eclipse Nearby (Peta Interaktif)'),
        backgroundColor: AppTheme.deepSpace,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Lokasi Saya',
            onPressed: () {
              if (_userPosition != null) {
                _mapController.move(
                  LatLng(_userPosition!.latitude, _userPosition!.longitude),
                  14,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lokasi GPS belum tersedia.')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _loadNearbyData,
          ),
        ],
      ),
      body: _loading
          ? const CosmicLoading(message: 'Memuat peta & lokasi event aktif...')
          : _error != null
          ? CosmicErrorView(message: _error!, onRetry: _loadNearbyData)
          : Stack(
              children: [
                // 1. Interactive Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(curLat, curLon),
                    initialZoom: 12,
                    minZoom: 3,
                    maxZoom: 18,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.eclipseverse.app',
                    ),
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
                    MarkerLayer(
                      markers: [
                        // User position marker
                        if (_userPosition != null)
                          Marker(
                            point: LatLng(
                              _userPosition!.latitude,
                              _userPosition!.longitude,
                            ),
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blueAccent,
                              size: 32,
                            ),
                          ),
                        // Active event markers
                        ..._activeEvents.map(
                          (event) => Marker(
                            point: LatLng(event.latitude, event.longitude),
                            width: 48,
                            height: 48,
                            child: GestureDetector(
                              onTap: () => _selectEvent(event),
                              child: Icon(
                                Icons.location_on,
                                color: target?.id == event.id
                                    ? AppTheme.coronaGold
                                    : Colors.redAccent,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),

                // 2. Info Card on Top
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Card(
                    color: AppTheme.surfaceElevated.withValues(alpha: 0.95),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.deepSpace,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: relative == null
                                ? const Icon(
                                    Icons.explore,
                                    size: 30,
                                    color: Colors.white,
                                  )
                                : Transform.rotate(
                                    angle: relative * math.pi / 180,
                                    child: const Icon(
                                      Icons.navigation,
                                      size: 30,
                                      color: AppTheme.coolCyan,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  target?.title ?? 'Pilih Event Aktif di Peta',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _headingDegrees == null
                                      ? (_userPosition == null
                                            ? 'GPS nonaktif · Menampilkan peta umum'
                                            : 'Kompas siap · Sentuh pin event')
                                      : 'Kompas ${_headingDegrees!.round()}° · Tujuan ${bearing?.round() ?? 0}°',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                if (_loadingRoute)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: LinearProgressIndicator(
                                      color: AppTheme.coolCyan,
                                    ),
                                  )
                                else if (_routeError != null)
                                  Text(
                                    _routeError!,
                                    style: const TextStyle(
                                      color: AppTheme.error,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Swipeable event cards, ordered by distance when GPS is available.
                if (_activeEvents.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 18,
                    child: SizedBox(
                      height: 142,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        itemCount: _activeEvents.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final event = _activeEvents[index];
                          final distance = _userPosition == null
                              ? null
                              : LocationService.distanceKm(
                                  _userPosition!.latitude,
                                  _userPosition!.longitude,
                                  event.latitude,
                                  event.longitude,
                                );
                          return SizedBox(
                            width: 270,
                            child: Card(
                              color: AppTheme.surfaceElevated.withValues(
                                alpha: 0.97,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: target?.id == event.id
                                      ? AppTheme.coronaGold
                                      : AppTheme.borderSubtle,
                                  width: target?.id == event.id ? 2 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _selectEvent(event),
                                child: Row(
                                  children: [
                                    if (event.imageUrl != null &&
                                        event.imageUrl!.isNotEmpty)
                                      Image.network(
                                        event.imageUrl!,
                                        width: 86,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          width: 86,
                                          color: AppTheme.deepSpace,
                                          child: const Icon(
                                            Icons.event,
                                            color: AppTheme.coolCyan,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 86,
                                        color: AppTheme.deepSpace,
                                        child: const Icon(
                                          Icons.event,
                                          color: AppTheme.coolCyan,
                                        ),
                                      ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              event.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              event.city,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (distance != null)
                                              Text(
                                                '${distance.toStringAsFixed(1)} km dari kamu',
                                                style: const TextStyle(
                                                  color: AppTheme.coronaGold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            const Spacer(),
                                            const Text(
                                              'Pilih & lihat rute →',
                                              style: TextStyle(
                                                color: AppTheme.coolCyan,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // 4. Floating Compass
                Positioned(
                  top: 96,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const CompassWidget(),
                  ),
                ),
              ],
            ),
    );
  }
}
