import 'package:supabase_flutter/supabase_flutter.dart';
import 'eclipse_card_model.dart';

class RedeemService {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>> getUserStats() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Silakan login terlebih dahulu.');

    final results = await Future.wait<dynamic>([
      _client
          .from('user_points')
          .select('total_points')
          .eq('user_id', user.id)
          .maybeSingle(),
      _client.from('user_cards').select('card_id').eq('user_id', user.id),
    ]);

    final pointsRow = results[0] as Map<String, dynamic>?;
    final ownedRows = results[1] as List;

    return {
      'points': (pointsRow?['total_points'] as num?)?.toInt() ?? 0,
      'owned_cards': ownedRows.map((row) => row['card_id']).toList(),
    };
  }

  static Future<List<EclipseCard>> getCards() async {
    // 1. Ambil data kartu dari tabel 'cards'
    final cardRows = await _client
        .from('cards')
        .select('id, card_name, points_cost, is_available, image_path')
        .eq('is_available', true)
        .order('points_cost')
        .timeout(const Duration(seconds: 10));

    // 2. Proses data
    return cardRows.map((item) {
      final row = Map<String, dynamic>.from(item);
      
      // Ambil path langsung dari database (contoh isinya: "members/SCOUPS.jpg")
      final cardImagePath = row['image_path']?.toString() ?? '';
      
      String imageUrl = '';
      String imageAssetPath = 'assets/members/SOLEN.jpg'; // Default fallback jika kosong

      if (cardImagePath.isNotEmpty) {
        // A. URL untuk internet (Supabase Storage)
        imageUrl = _client.storage.from('eclipseverse-media').getPublicUrl(cardImagePath);
        
        // B. Path untuk gambar lokal (offline) -> "assets/members/SCOUPS.jpg"
        imageAssetPath = 'assets/$cardImagePath'; 
      }

      return EclipseCard(
        id: (row['id'] as num).toInt(),
        name: '${row['card_name'] ?? 'Photocard'}',
        cost: (row['points_cost'] as num).toInt(),
        imageUrl: imageUrl,
        imageAssetPath: imageAssetPath,
      );
    }).toList();
  }

  static Future<bool> redeemCard(int cardId) async {
    final response = await _client
        .rpc('redeem_photocard', params: {'p_card_id': cardId})
        .timeout(const Duration(seconds: 12));

    if (response is Map) {
      final success = response['success'] == true;
      if (!success) {
        throw Exception(response['message']?.toString() ?? 'Gagal menukar photocard.');
      }
      return true;
    }
    throw Exception('Respons database tidak valid.');
  }

  static Future<Map<String, dynamic>> verifyBlockchain() async {
    final result = await _client
        .rpc('verify_blockchain_ledger')
        .timeout(const Duration(seconds: 10));
    return Map<String, dynamic>.from(result as Map);
  }
}