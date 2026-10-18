import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import 'location_service.dart';
import 'nearby_map_page.dart'; 
import '../event/event_model.dart';       
import '../event/event_service.dart';     

class NearbyPage extends StatefulWidget {
  const NearbyPage({super.key});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _eventsWithDistance = [];
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _fetchNearbyEvents();
  }

  Future<void> _fetchNearbyEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Ambil lokasi user
      Position? pos = await LocationService.getCurrentLocation();
      
      if (pos != null) {
        _userPosition = pos;

        // 2. Ambil data event
        List<Event> events = await EventService.fetchEvents(); 

        // 3. Hitung jarak
        List<Map<String, dynamic>> calculatedEvents = [];
        for (var event in events) {
          double distance = LocationService.distanceKm(
            pos.latitude, pos.longitude, 
            event.latitude, event.longitude
          );
          
          calculatedEvents.add({
            'event': event,
            'distance': distance,
          });
        }

        // 4. Urutkan dari jarak terdekat
        calculatedEvents.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

        setState(() {
          _eventsWithDistance = calculatedEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Eclipse Nearby'),
      ),
      
      body: _buildBody(),
      floatingActionButton: (_eventsWithDistance.isNotEmpty && _userPosition != null)
          ? FloatingActionButton.extended(
              onPressed: () {
                final List<Event> eventList = _eventsWithDistance
                    .map((e) => e['event'] as Event)
                    .toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NearbyMapPage(
                      events: eventList,
                      userLat: _userPosition!.latitude,
                      userLon: _userPosition!.longitude,
                    ),
                  ),
                );
              },
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Lihat Peta', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null, 
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryDark));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTheme.textTheme.titleMedium?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: AppTheme.primaryButtonStyle,
                onPressed: () => _fetchNearbyEvents(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eventsWithDistance.length,
      itemBuilder: (context, index) {
        final data = _eventsWithDistance[index];
        final Event event = data['event'];
        final double distance = data['distance'];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on, color: AppTheme.primaryDark),
            ),
            title: Text(
              event.title,
              style: AppTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(event.city, style: AppTheme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  '${distance.toStringAsFixed(1)} km dari lokasimu',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}