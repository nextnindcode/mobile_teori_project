import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/local_db.dart';

class GameService {
  static final _client = Supabase.instance.client;

  static Future<int> getBestScore() async {
    final local = int.tryParse(await LocalDb.getPreference('best_score') ?? '0') ?? 0;
    final user = _client.auth.currentUser;
    if (user == null) return local;
    try {
      final row = await _client
          .from('game_scores')
          .select('score')
          .eq('user_id', user.id)
          .order('score', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));
      final remote = (row?['score'] as num?)?.toInt() ?? 0;
      return remote > local ? remote : local;
    } catch (_) {
      return local;
    }
  }

  static Future<void> saveBestScore(int score) async {
    await LocalDb.setPreference('best_score', score.toString());
  }

  static Future<void> kirimSkorKeServer(int score, int correctCount) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      // Store the result for history/leaderboard. Points are awarded only by trusted RPCs.
      await _client.from('game_scores').insert({
        'user_id': user.id,
        'score': score,
        'correct_count': correctCount.clamp(0, 10),
        'question_count': 10,
      }).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Gagal menyimpan skor ke Supabase: $e');
    }
  }
}
