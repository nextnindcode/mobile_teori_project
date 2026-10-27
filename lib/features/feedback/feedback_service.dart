import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> fetchReviews() async {
    final rows = await _client
        .from('feedback')
        .select('id,user_id,rating,impression,suggestion,created_at')
        .order('created_at', ascending: false)
        .limit(50)
        .timeout(const Duration(seconds: 12));

    final reviews = rows.map((row) => Map<String, dynamic>.from(row)).toList();
    final userIds = reviews
        .map((row) => row['user_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (userIds.isNotEmpty) {
      try {
        final profiles = await _client
            .from('profiles')
            .select('id,display_name')
            .inFilter('id', userIds)
            .timeout(const Duration(seconds: 8));
        final names = <String, String>{
          for (final row in profiles)
            '${row['id']}': (row['display_name']?.toString().trim().isNotEmpty ?? false)
                ? row['display_name'].toString().trim()
                : 'Pengguna',
        };
        for (final review in reviews) {
          review['user_name'] = names[review['user_id']?.toString()] ?? 'Pengguna';
        }
      } catch (_) {
        for (final review in reviews) {
          review['user_name'] = 'Pengguna';
        }
      }
    }
    return reviews;
  }

  static Future<void> submit({
    required int rating,
    required String impression,
    required String suggestion,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Silakan login terlebih dahulu.');
    await _client.from('feedback').insert({
      'user_id': user.id,
      'rating': rating,
      'impression': impression.trim(),
      'suggestion': suggestion.trim(),
    }).timeout(const Duration(seconds: 12));
  }
}
