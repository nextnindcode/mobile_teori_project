import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/local_db.dart';
import 'member_model.dart';

class MemberService {
  static final _client = Supabase.instance.client;

  static Future<List<Member>> fetchMembers() async {
    try {
      final rows = await _client
          .from('members')
          .select(
            '*',
          )
          .order('sort_order')
          .timeout(const Duration(seconds: 12));

      final data = rows.map((item) {
        final row = Map<String, dynamic>.from(item);
        final path = row['profile_image_path']?.toString() ?? '';
        row['image_url'] = path.isEmpty
            ? null
            : _client.storage.from('eclipseverse-media').getPublicUrl(path);
        return row;
      }).toList();

      await LocalDb.saveMembers(data);
      return data.map(Member.fromJson).toList();
    } catch (_) {
      final cached = await LocalDb.getMembers();
      if (cached.isEmpty) rethrow;
      return cached.map(Member.fromJson).toList();
    }
  }

  static Future<Member> fetchDetail(int id) async {
    try {
      final row = await _client
          .from('members')
          .select(
            'id,stage_name,position,team,description,fun_fact,profile_image_path',
          )
          .eq('id', id)
          .single()
          .timeout(const Duration(seconds: 12));
      final data = Map<String, dynamic>.from(row);
      final path = data['profile_image_path']?.toString() ?? '';
      data['image_url'] = path.isEmpty
          ? null
          : _client.storage.from('eclipseverse-media').getPublicUrl(path);
      return Member.fromJson(data);
    } catch (_) {
      final cached = await LocalDb.getMembers();
      final hit = cached.where((item) => int.tryParse('${item['id']}') == id);
      if (hit.isEmpty) rethrow;
      return Member.fromJson(hit.first);
    }
  }
}
