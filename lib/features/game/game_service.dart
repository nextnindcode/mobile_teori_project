import '../../core/api_service.dart';
import '../../core/local_db.dart';
import 'package:flutter/foundation.dart';

class GameService {
  // 1. Ambil skor terbaik dari SQLite lokal
  static Future<int> getBestScore() async {
    final bestScoreStr = await LocalDb.getPreference('best_score');
    return int.tryParse(bestScoreStr ?? '0') ?? 0;
  }

  // 2. Simpan skor terbaik baru ke SQLite
  static Future<void> saveBestScore(int score) async {
    await LocalDb.setPreference('best_score', score.toString());
  }

  // 3. Kirim skor ke server backend (PHP)
  static Future<void> kirimSkorKeServer(int score, int correctCount) async {
    try {
      await ApiService.post('/game/score', {
        'score': score,
        'correct_count': correctCount,
      });
    } catch (e) {
      // Skor tetap tersimpan di SQLite lokal.
      debugPrint('Gagal mengirim skor ke server: $e');
    }
  }

  // 4. Kirim poin ke database (untuk redeem kartu)
  static Future<void> kirimPoin(int poin) async {
    try {
      await ApiService.post('/game/redeem.php', {
        'action': 'add_points',
        'points': poin,
      });
    } catch (e) {
      // Abaikan jika gagal, karena mungkin sedang offline
    }
  }
}