import 'package:supabase_flutter/supabase_flutter.dart';
import 'event_model.dart';

class EventService {
  static final _client = Supabase.instance.client;

  static String? _posterUrl(dynamic rawPath) {
    var path = rawPath?.toString().trim() ?? '';
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    path = path.replaceFirst(RegExp(r'^/+'), '');
    if (path.startsWith('eclipseverse-media/')) {
      path = path.substring('eclipseverse-media/'.length);
    }
    // Semua poster event pada bucket disimpan di folder events/.
    if (!path.startsWith('events/')) path = 'events/\${path.split('/').last}';
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
      data['poster_path'] = _posterUrl(data['poster_path']);
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
    final path = data['poster_path']?.toString() ?? '';
    if (path.isNotEmpty && !path.startsWith('http')) {
      data['poster_path'] = _client.storage.from('eclipseverse-media').getPublicUrl(path);
    }
    return Event.fromJson(data);
  }
}
