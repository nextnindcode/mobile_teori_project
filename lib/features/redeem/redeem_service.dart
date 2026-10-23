import 'package:supabase_flutter/supabase_flutter.dart';

class RedeemService {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>> getUserStats() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Silakan login terlebih dahulu.');
    final pointsRow = await _client.from('user_points')
        .select('total_points').eq('user_id', user.id).maybeSingle();
    final cards = await _client.from('user_cards')
        .select('card_id').eq('user_id', user.id);
    return {
      'points': (pointsRow?['total_points'] as num?)?.toInt() ?? 0,
      'owned_cards': cards.map((row) => row['card_id']).toList(),
    };
  }

  static Future<void> redeemCard(int cardId, int cost) async {
    await _client.rpc('redeem_photocard', params: {'p_card_id': cardId});
  }

  static Future<Map<String, dynamic>> verifyBlockchain() async {
    final result = await _client.rpc('verify_blockchain_ledger')
        .timeout(const Duration(seconds: 10));
    return Map<String, dynamic>.from(result as Map);
  }
}
