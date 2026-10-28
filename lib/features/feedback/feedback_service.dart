import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> fetchReviews() async {
    final rows = await _client
        .from('feedback')
        .select('id,rating,impression,suggestion,created_at')
        .order('created_at', ascending: false)
        .limit(50)
        .timeout(const Duration(seconds: 12));
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
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
