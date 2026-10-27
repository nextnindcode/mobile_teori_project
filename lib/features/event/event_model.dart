import '../fandom/shared/json_utils.dart';

class Event {
  final int id;
  final String title;
  final String description;
  final DateTime eventDate; // UTC
  final String venue;
  final String city;
  final double latitude;
  final double longitude;
  final String? imageUrl;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.venue,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
  });

  bool get isPast => eventDate.isBefore(DateTime.now().toUtc());

  factory Event.fromJson(Map<String, dynamic> j) => Event(
        id: toInt(j['id']),
        title: '${j['title'] ?? ''}',
        description: '${j['description'] ?? ''}',
        eventDate: parseUtc(j['event_date']),
        venue: '${j['venue'] ?? ''}',
        city: '${j['city'] ?? ''}',
        latitude: toDouble(j['latitude']),
        longitude: toDouble(j['longitude']),
        imageUrl: (j['poster_path'] ?? j['image_url'])?.toString(),
      );
}
