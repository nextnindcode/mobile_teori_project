import '../../core/api_service.dart';
import '../../core/local_db.dart';
import 'member_model.dart';
import 'shared/json_utils.dart';

class MemberService {
  /// Ambil 13 member dari server dan isi cache `members_cache`.
  /// Jika server gagal, pakai cache (Fandom tetap tampil saat offline).
  static Future<List<Member>> fetchMembers() async {
    try {
      final data = await ApiService.get('/members');
      final list = asList(data);
      await LocalDb.saveMembers(list);
      return list.map(Member.fromJson).toList();
    } catch (_) {
      final cached = await LocalDb.getMembers();
      if (cached.isEmpty) rethrow;
      return cached.map(Member.fromJson).toList();
    }
  }

  static Future<Member> fetchDetail(int id) async {
    try {
      final data = await ApiService.get(
        '/members/detail',
        query: {'id': '$id'},
      );
      return Member.fromJson(asObject(data));
    } catch (_) {
      final cached = await LocalDb.getMembers();
      final hit = cached.where((m) => toInt(m['id']) == id);
      if (hit.isEmpty) rethrow;
      return Member.fromJson(hit.first);
    }
  }
}
