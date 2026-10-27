import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/local_db.dart';

class GameService {
  static final _client = Supabase.instance.client;

  static const int questionsPerSession = 10;
  static const int questionBankSize = 20;

  static Future<int> getBestScore() async {
    final user = _client.auth.currentUser;
    final scoreKey = user == null ? 'best_score_guest' : 'best_score_${user.id}';
    final local = int.tryParse(await LocalDb.getPreference(scoreKey) ?? '0') ?? 0;
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
    final user = _client.auth.currentUser;
    final scoreKey = user == null ? 'best_score_guest' : 'best_score_${user.id}';
    await LocalDb.setPreference(scoreKey, score.toString());
  }

  /// Ambil maksimal 20 soal aktif dari bank, lalu acak dan gunakan 10 soal.
  static Future<List<Map<String, dynamic>>> fetchQuestions() async {
    final rows = await _client
        .from('quiz_questions_public')
        .select('id,question_text,options,difficulty,points,explanation')
        .limit(questionBankSize)
        .timeout(const Duration(seconds: 8));

    if (rows.length < questionsPerSession) {
      throw Exception('Bank soal belum cukup. Minimal $questionsPerSession soal aktif diperlukan.');
    }

    final questions = rows.map((row) => Map<String, dynamic>.from(row)).toList()..shuffle();
    return questions.take(questionsPerSession).toList();
  }

  static Future<Map<String, dynamic>> submitAnswers(
    List<Map<String, dynamic>> answers, {
    bool memberChallenge = false,
  }) async {
    if (answers.length != questionsPerSession) {
      throw Exception('Satu sesi harus berisi tepat $questionsPerSession jawaban.');
    }

    final result = await _client.rpc(
      memberChallenge ? 'submit_member_quiz_attempt' : 'submit_quiz_attempt',
      params: {'p_answers': answers},
    ).timeout(const Duration(seconds: 10));

    return Map<String, dynamic>.from(result as Map);
  }

  static Future<void> saveUnverifiedScoreLocally(int score) async {
    final user = _client.auth.currentUser;
    final scoreKey = user == null ? 'best_score_guest' : 'best_score_${user.id}';
    await LocalDb.setPreference(scoreKey, score.toString());
  }

  static void logFailure(Object error) => debugPrint('Game/Supabase: $error');
}
