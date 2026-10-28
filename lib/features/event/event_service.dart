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

  /// Mengubah path poster menjadi URL publik Supabase Storage.
  /// Jika path kosong, gunakan poster cadangan berdasarkan ID event.
  static String? _posterUrl(dynamic rawPath, {int? eventId}) {
    var path = rawPath?.toString().trim() ?? '';

    if (path.isEmpty) {
      path = _fallbackPosters[eventId] ?? '';
    }

    if (path.isEmpty) {
      return null;
    }

    // Jika sudah berupa URL lengkap, gunakan URL tersebut.
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Menghapus garis miring di awal path.
    path = path.replaceFirst(RegExp(r'^/+'), '');

    // Menghapus nama bucket jika ikut tersimpan di dalam path.
    const bucketName = 'eclipseverse-media';

    if (path.startsWith('$bucketName/')) {
      path = path.substring(bucketName.length + 1);
    }

    // Semua poster event disimpan di folder events/.
    if (!path.startsWith('events/')) {
      path = 'events/${path.split('/').last}';
    }

    return _client.storage.from(bucketName).getPublicUrl(path);
  }

  /// Mengambil daftar event yang tidak berstatus draft.
  static Future<List<Event>> fetchEvents() async {
    final rows = await _client
        .from('events')
        .select(
          'id,'
          'title,'
          'description,'
          'event_date,'
          'venue,'
          'city,'
          'latitude,'
          'longitude,'
          'status,'
          'poster_path',
        )
        .neq('status', 'draft')
        .order('event_date')
        .limit(100)
        .timeout(const Duration(seconds: 12));

    return rows.map((row) {
      final data = Map<String, dynamic>.from(row);

      final eventId = (data['id'] as num?)?.toInt();

      data['poster_path'] = _posterUrl(data['poster_path'], eventId: eventId);

      return Event.fromJson(data);
    }).toList();
  }

  /// Mengambil detail satu event berdasarkan ID.
  static Future<Event> fetchEventDetail(int id) async {
    final row = await _client
        .from('events')
        .select(
          'id,'
          'title,'
          'description,'
          'event_date,'
          'venue,'
          'city,'
          'latitude,'
          'longitude,'
          'status,'
          'poster_path',
        )
        .eq('id', id)
        .single()
        .timeout(const Duration(seconds: 12));

    final data = Map<String, dynamic>.from(row);

    data['poster_path'] = _posterUrl(
      data['poster_path'],
      eventId: (data['id'] as num?)?.toInt(),
    );

    return Event.fromJson(data);
  }
}
