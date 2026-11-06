// import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'eclipse_card_model.dart';

class RedeemService {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>> getUserStats() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Silakan login terlebih dahulu.');

    final results = await Future.wait<dynamic>([
      _client.from('user_points').select('total_points').eq('user_id', user.id).maybeSingle(),
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

    // 2. Ambil data member dari tabel 'members' (sesuai screenshot kamu)
    final memberRows = await _client
        .from('members')
        .select('stage_name, profile_image_path');

    // 3. Buat "Kamus" untuk mencocokkan nama member dengan URL fotonya
    final Map<String, String> memberImages = {};
    for (var m in memberRows) {
      final name = m['stage_name'].toString().toLowerCase();
      final path = m['profile_image_path']?.toString() ?? '';
      if (path.isNotEmpty) {
        memberImages[name] = _client.storage
            .from('eclipseverse-media')
            .getPublicUrl(path);
      }
    }

    // 4. Gabungkan data
    return cardRows.map((item) {
      final row = Map<String, dynamic>.from(item);
      final cardName = row['card_name'].toString().toLowerCase();

      String imageUrl = '';
      String imageAssetPath = 'assets/members/SOLEN.jpg'; // Default fallback

      // Cocokkan nama kartu dengan nama member (misal: "SCOUPS Photocard" cocok dengan "SCOUPS")
      for (String memberName in memberImages.keys) {
        if (cardName.contains(memberName)) {
          imageUrl = memberImages[memberName]!;
          imageAssetPath = 'assets/members/${memberName.toUpperCase()}.jpg';
          print('KARTU: $cardName | URL: $imageUrl');
          break;
        }
      }

      // Jika kolom image_path di tabel cards ternyata ada isinya, prioritaskan itu
      final cardImagePath = row['image_path']?.toString() ?? '';
      if (cardImagePath.isNotEmpty) {
        imageUrl = _client.storage.from('eclipseverse-media').getPublicUrl(cardImagePath);
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