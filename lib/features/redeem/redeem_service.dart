import 'package:crypto/crypto.dart';
import 'dart:convert';
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
    final rows = await _client.from('blockchain_ledger')
        .select('id,transaction_data,previous_hash,current_hash,created_at')
        .order('id');
    var previous = 'GENESIS';
    var valid = true;
    int? invalidId;
    for (final item in rows) {
      final row = Map<String, dynamic>.from(item);
      final prev = row['previous_hash']?.toString() ?? '';
      final current = row['current_hash']?.toString() ?? '';
      final payload = jsonEncode(row['transaction_data']);
      final expected = sha256.convert(utf8.encode('$prev|$payload')).toString();
      if (prev != previous || current != expected) {
        valid = false;
        invalidId = (row['id'] as num?)?.toInt();
        break;
      }
      previous = current;
    }
    return {'valid': valid, 'block_count': rows.length, 'invalid_block_id': invalidId};
  }
}
