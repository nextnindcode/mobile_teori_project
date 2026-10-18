import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../event/event_model.dart';

class NearbyMapPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peta Event Terdekat')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(userLat, userLon), // Pusatkan ke lokasi user
          initialZoom: 5.0, // Skala zoom (5 = sedang, bisa dilihat se-Indonesia)
        ),
        children: [
          // 1. Gambar Peta OpenStreetMap
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.final_project_bgt_nih',
          ),
          
          // 2. Titik-Titik Lokasi (Marker)
          MarkerLayer(
            markers: [
              // Titik Lokasi User (Biru) 
              Marker(
                point: LatLng(userLat, userLon),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.my_location, 
                  color: Colors.blue, 
                  size: 30,
                ),
              ),
              
              // Titik Lokasi Event (Merah) 
              ...events.map((event) {
                return Marker(
                  point: LatLng(event.latitude, event.longitude),
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () {
                      // Munculkan pop-up info event saat pin merah diklik
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('Kota: ${event.city}'),
                              const SizedBox(height: 4),
                              Text('Lokasi: ${event.venue}', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.location_on, 
                      color: Colors.red, 
                      size: 40,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}