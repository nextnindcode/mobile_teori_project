import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/local_db.dart';
import 'member_model.dart';

class MemberService {
  static final _client = Supabase.instance.client;

  static Future<List<Member>> fetchMembers() async {
    try {
      final rows = await _client
          .from('members')
          .select('id,stage_name,position,description,fun_fact')
          .order('sort_order')
          .timeout(const Duration(seconds: 12));
      final data = rows.map((row) => Map<String, dynamic>.from(row)).toList();
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
          .select('id,stage_name,position,description,fun_fact')
          .eq('id', id)
          .single()
          .timeout(const Duration(seconds: 12));
      return Member.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      final cached = await LocalDb.getMembers();
      final hit = cached.where((m) => int.tryParse('${m['id']}') == id);
      if (hit.isEmpty) rethrow;
      return Member.fromJson(hit.first);
    }
  }
}
