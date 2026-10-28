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
        .select('id, card_name, points_cost, is_available, image_path, members(stage_name, profile_image_path)')
        .eq('is_available', true)
        .order('points_cost')
        .timeout(const Duration(seconds: 10));

    String publicImageUrl(dynamic storagePath) {
      final path = storagePath?.toString().trim() ?? '';
      if (path.isEmpty) return '';
      if (path.startsWith('https://') || path.startsWith('http://')) return path;
      return _client.storage.from('eclipseverse-media').getPublicUrl(path);
    }

    return cardRows.map((item) {
      final row = Map<String, dynamic>.from(item);
      final member = row['members'] is Map
          ? Map<String, dynamic>.from(row['members'] as Map)
          : <String, dynamic>{};
      final cardImage = publicImageUrl(row['image_path']);
      final memberImage = publicImageUrl(member['profile_image_path']);

      return EclipseCard(
        id: (row['id'] as num).toInt(),
        name: '${row['card_name'] ?? 'Photocard'}',
        cost: (row['points_cost'] as num).toInt(),
        imageUrl: cardImage.isNotEmpty ? cardImage : memberImage,
      );
    }).toList();
  }

  // 3. Proses tukar kartu melalui Supabase RPC
  static Future<bool> redeemCard(int cardId) async {
    final response = await _client
        .rpc('redeem_photocard', params: {'p_card_id': cardId})
        .timeout(const Duration(seconds: 12));

    debugPrint('Respon Database: $response');

    if (response is Map) {
      final success = response['success'] == true;

      if (!success) {
        throw Exception(
          response['message']?.toString() ?? 'Gagal menukar photocard.',
        );
      }

      return true;
    }

    throw Exception('Respons database tidak valid.');
  }

  // 4. Verifikasi blockchain ledger
  static Future<Map<String, dynamic>> verifyBlockchain() async {
    final result = await _client
        .rpc('verify_blockchain_ledger')
        .timeout(const Duration(seconds: 10));
    return Map<String, dynamic>.from(result as Map);
  }
}
