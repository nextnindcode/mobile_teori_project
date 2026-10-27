import 'package:supabase_flutter/supabase_flutter.dart';
import 'event_model.dart';

class EventService {
  static final _client = Supabase.instance.client;

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
      final path = data['poster_path']?.toString() ?? '';
      if (path.isNotEmpty && !path.startsWith('http')) {
        data['poster_path'] = _client.storage.from('eclipseverse-media').getPublicUrl(path);
      }
      return Event.fromJson(data);
    }).toList();
  }

  static Future<Event> fetchEventDetail(int id) async {
    final row = await _client
        .from('events')
        .select('id,title,description,event_date,venue,city,latitude,longitude,status')
        .eq('id', id)
        .single()
        .timeout(const Duration(seconds: 12));
    final data = Map<String, dynamic>.from(row);
    final path = data['poster_path']?.toString() ?? '';
    if (path.isNotEmpty && !path.startsWith('http')) {
      data['poster_path'] = _client.storage.from('eclipseverse-media').getPublicUrl(path);
    }
    return Event.fromJson(data);
  }
}
