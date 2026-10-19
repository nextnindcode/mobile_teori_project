import '../../core/api_service.dart';

class RedeemService {
  // 1. Ambil total poin user dan kartu yang sudah dimiliki
  static Future<Map<String, dynamic>> getUserStats() async {
    final response = await ApiService.post('/game/redeem.php', {
      'action': 'get_points',
    });
    return response['data'];
  }

  // 2. Tukar poin dengan kartu
  static Future<void> redeemCard(int cardId, int cost) async {
    await ApiService.post('/game/redeem.php', {
      'action': 'redeem',
      'card_id': cardId,
      'cost': cost,
    });
  }

  static Future<Map<String, dynamic>> verifyBlockchain() async {
    final response = await ApiService.get('/blockchain/verify');
    final data = response['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Respons verifikasi blockchain tidak valid');
  }

  static Future<void> addPoints(int points) async {
    await ApiService.post('/game/redeem.php', {
      'action': 'add_points',
      'points': points,
    });
  }
}