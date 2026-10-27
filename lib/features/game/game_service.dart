import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/local_db.dart';

class GameService {
  static final _client = Supabase.instance.client;

  static Future<int> getBestScore() async {
    final local =
        int.tryParse(await LocalDb.getPreference('best_score') ?? '0') ?? 0;
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

  static Future<List<Map<String, dynamic>>> fetchQuestions() async {
    List<Map<String, dynamic>> rows;

    try {
      rows = await _client
          .from('quiz_questions_public')
          .select('id,question_text,options,difficulty,points,correct_option')
          .limit(50)
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      rows = await _client
          .from('quiz_questions_public')
          .select('id,question_text,options,difficulty,points')
          .limit(50)
          .timeout(const Duration(seconds: 8));
    }

    if (rows.length < 20) {
      throw Exception('Data soal Supabase belum cukup. Jalankan migrasi kuis terbaru.');
    }

    final list = rows.map((row) => Map<String, dynamic>.from(row)).toList()
      ..shuffle();
    return list.take(20).toList();
  }

  static Future<Map<String, dynamic>> submitAnswers(
    List<Map<String, dynamic>> answers, {
    bool memberChallenge = false,
  }) async {
    final result = await _client
        .rpc(
          memberChallenge
              ? 'submit_member_quiz_attempt'
              : 'submit_quiz_attempt',
          params: {'p_answers': answers},
        )
        .timeout(const Duration(seconds: 10));
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<void> saveUnverifiedScoreLocally(int score) async {
    await LocalDb.setPreference('best_score', score.toString());
  }

  static void logFailure(Object error) =>
      debugPrint('Game/Supabase: $error');
}