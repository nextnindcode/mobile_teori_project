import 'package:eclipseverse/core/api_service.dart';

import '../fandom/shared/json_utils.dart';
import 'event_model.dart';

/// Kontrak serah-terima H8: EventService.fetchEvents() dipakai C (Nearby).
class EventService {
  /// 6 event, urut tanggal naik.
  static Future<List<Event>> fetchEvents() async {
    final data = await ApiService.get('/events');
    final list = asList(data).map(Event.fromJson).toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
    return list;
  }

  static Future<Event> fetchEventDetail(int id) async {
    final data = await ApiService.get('/events/detail', query: {'id': '$id'});
    return Event.fromJson(asObject(data));
  }
}
