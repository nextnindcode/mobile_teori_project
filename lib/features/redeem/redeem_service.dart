import 'package:supabase_flutter/supabase_flutter.dart';

import 'eclipse_card_model.dart';

class RedeemService {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>> getUserStats() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Silakan login terlebih dahulu.');

    final results = await Future.wait<dynamic>([
      (() async => await _client
          .from('user_points')
          .select('total_points')
          .eq('user_id', user.id)
          .maybeSingle())(),
      (() async => await _client
          .from('user_cards')
          .select('card_id')
          .eq('user_id', user.id))(),
    ]);

    final pointsRow = results[0] as Map<String, dynamic>?;
    final ownedRows = results[1] as List;
    return {
      'points': (pointsRow?['total_points'] as num?)?.toInt() ?? 0,
      'owned_cards': ownedRows.map((row) => row['card_id']).toList(),
    };
  }

  static Future<List<EclipseCard>> getCards() async {
    final rows = await _client
        .from('cards')
        .select('id,card_name,points_cost,image_path,is_available')
        .eq('is_available', true)
        .order('points_cost')
        .timeout(const Duration(seconds: 10));

    return rows.map((item) {
      final row = Map<String, dynamic>.from(item);
      final imagePath = row['image_path']?.toString() ?? '';
      final imageUrl = imagePath.isEmpty
          ? ''
          : _client.storage.from('eclipseverse-media').getPublicUrl(imagePath);
      return EclipseCard(
        id: (row['id'] as num).toInt(),
        name: '${row['card_name'] ?? 'Photocard'}',
        cost: (row['points_cost'] as num).toInt(),
        imageUrl: imageUrl,
      );
    }).toList();
  }

  static Future<void> redeemCard(int cardId, int cost) async {
    // Biaya dan kuota divalidasi di database. Parameter cost hanya untuk
    // menjaga kompatibilitas pemanggil lama dan tidak dipercaya oleh server.
    await _client
        .rpc('redeem_photocard', params: {'p_card_id': cardId})
        .timeout(const Duration(seconds: 12));
  }

  static Future<Map<String, dynamic>> verifyBlockchain() async {
    final result = await _client
        .rpc('verify_blockchain_ledger')
        .timeout(const Duration(seconds: 10));
    return Map<String, dynamic>.from(result as Map);
  }
}
