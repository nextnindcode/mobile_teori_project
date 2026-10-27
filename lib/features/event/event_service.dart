import 'package:supabase_flutter/supabase_flutter.dart';
import 'event_model.dart';

class EventService {
  static final _client = Supabase.instance.client;

  static const Map<int, String> _fallbackPosters = {
    18: 'events/fan-meeting-yogyakarta.jpg',
    19: 'events/acoustic-night-semarang.jpg',
    20: 'events/starlight-campus-tour.jpg',
    21: 'events/anniversary-gala.jpg',
    22: 'events/midnight-comeback-live.jpg',
    23: 'events/acoustic-night-semarang.jpg',
    24: 'events/fan-meeting-jakarta.jpg',
    25: 'events/penumbra-showcase-bandung.jpg',
    26: 'events/cosmic-pop-up-malang.jpg',
    27: 'events/totality-live-surabaya.jpg',
    28: 'events/summer-fest-denpasar.jpg',
    29: 'events/fan-meeting-yogyakarta.jpg',
    30: 'events/midnight-comeback-live.jpg',
    31: 'events/penumbra-showcase-bandung.jpg',
    32: 'events/fan-meeting-jakarta.jpg',
    33: 'events/world-tour-seoul.jpg',
    34: 'events/anniversary-gala.jpg',
    35: 'events/totality-live-surabaya.jpg',
  };

  static String? _posterUrl(dynamic rawPath, {int? eventId}) {
    var path = rawPath?.toString().trim() ?? '';
    if (path.isEmpty) path = _fallbackPosters[eventId] ?? '';
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    path = path.replaceFirst(RegExp(r'^/+'), '');
    if (path.startsWith('eclipseverse-media/')) {
      path = path.substring('eclipseverse-media/'.length);
    }
    // Semua poster event pada bucket disimpan di folder events/.
    if (!path.startsWith('events/')) path = 'events/' + path.split('/').last;
    return _client.storage.from('eclipseverse-media').getPublicUrl(path);
  }

  static Future<List<Event>> fetchEvents() async {
    final rows = await _client
        .from('events')
        .select('id,title,description,event_date,venue,city,latitude,longitude,status,poster_path')
        .neq('status', 'draft')
        .order('event_date')
        .limit(100)
        .timeout(const Duration(seconds: 12));
    return rows.map((row) {
      final data = Map<String, dynamic>.from(row);
      data['poster_path'] = _posterUrl(data['poster_path'], eventId: (data['id'] as num?)?.toInt());
      return Event.fromJson(data);
    }).toList();
  }

  static Future<Event> fetchEventDetail(int id) async {
    final row = await _client
        .from('events')
        .select('id,title,description,event_date,venue,city,latitude,longitude,status,poster_path')
        .eq('id', id)
        .single()
        .timeout(const Duration(seconds: 12));
    final data = Map<String, dynamic>.from(row);
    data['poster_path'] = _posterUrl(data['poster_path']);
    return Event.fromJson(data);
  }
}
