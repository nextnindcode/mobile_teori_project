import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'eclipse_card_model.dart';

class RedeemService {
  static final _client = Supabase.instance.client;

  // 1. Ambil total poin dan daftar kartu milik user
  static Future<Map<String, dynamic>> getUserStats() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Silakan login terlebih dahulu.');

    // Gunakan <dynamic> agar Future.wait tidak error saat menggabungkan Map dan List
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

  // 2. Ambil katalog kartu (Menggabungkan data dari tabel cards dan members)
  static Future<List<EclipseCard>> getCards() async {
    final cardRows = await _client
        .from('cards')
        .select('id, card_name, points_cost, is_available')
        .eq('is_available', true)
        .order('points_cost')
        .timeout(const Duration(seconds: 10));

    final memberRows = await _client
        .from('members')
        .select('stage_name, profile_image_path');

    final Map<String, String> memberImages = {};
    final Map<String, String> memberAssets = {};
    for (var m in memberRows) {
      final name = m['stage_name'].toString().toLowerCase();
      memberAssets[name] = 'assets/members/${m['stage_name'].toString().toUpperCase()}.jpg';
      final path = m['profile_image_path']?.toString() ?? '';
      if (path.isNotEmpty) {
        memberImages[name] = _client.storage
            .from('eclipseverse-media')
            .getPublicUrl(path);
      }
    }

    return cardRows.map((item) {
      final row = Map<String, dynamic>.from(item);
      final cardName = row['card_name'].toString().toLowerCase();

      String imageUrl = '';
      String imageAssetPath = 'assets/members/SOLEN.jpg';
      for (String memberName in memberImages.keys) {
        if (cardName.contains(memberName)) {
          imageUrl = memberImages[memberName]!;
          imageAssetPath = memberAssets[memberName]!;
          break;
        }
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

  // 3. Proses Tukar Kartu (Via Supabase RPC)
  static Future<void> redeemCard(int cardId, int cost) async {
    // Tangkap balasan dari database (bisa success: true atau false)
    final response = await _client
        .rpc('redeem_photocard', params: {'p_card_id': cardId})
        .timeout(const Duration(seconds: 12));

    debugPrint('Respon Database: $response');

    // Jika database bilang "success: false" (poin kurang/kuota habis), lempar error ke UI
    if (response is Map && response['success'] == false) {
      throw Exception(response['message']);
    }
  }

  // 4. Verifikasi blockchain ledger 
  static Future<Map<String, dynamic>> verifyBlockchain() async {
    final result = await _client
        .rpc('verify_blockchain_ledger')
        .timeout(const Duration(seconds: 10));
    return Map<String, dynamic>.from(result as Map);
  }
}