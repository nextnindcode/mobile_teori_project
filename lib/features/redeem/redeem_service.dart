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

  // 3. Tambah Poin 
  static Future<void> addPoints(int points) async {
    await ApiService.post('/game/redeem.php', {
      'action': 'add_points',
      'points': points,
    });
  }
}