import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MembershipService {
  static final _client = Supabase.instance.client;

  static Future<bool> isActive() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      // 1. Cek apakah punya membership yang statusnya 'active' dan belum expired
      final rows = await _client
          .from('user_memberships')
          .select('redeem_quota')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .limit(1);

      if (rows.isEmpty) return false;

      // 2. Cek apakah kuotanya masih ada
      final quota = (rows.first['redeem_quota'] as num?)?.toInt() ?? 0;

      // Kalau kuota 0, anggap "tidak aktif" biar UI-nya berubah
      return quota > 0;
    } catch (e) {
      debugPrint('Error isActive: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> currentMembership() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Ambil data tanpa filter tanggal dulu
      final rows = await _client
          .from('user_memberships')
          .select(
            'id, status, starts_at, expires_at, redeem_quota, membership_plans(name, benefits)',
          )
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('expires_at', ascending: false)
          .limit(1);

      // Kalau datanya kosong, langsung return null
      if (rows.isEmpty) return null;

      // 2. Cek tanggal expired-nya pakai Dart (di sisi aplikasi)
      final data = Map<String, dynamic>.from(rows.first);
      final expiresAt = DateTime.tryParse(data['expires_at'].toString());

      // 3. Kalau udah expired (waktu sekarang lebih besar dari expires_at--berarti udah lalu), anggap gak aktif
      if (expiresAt != null && expiresAt.isBefore(DateTime.now().toUtc())) {
        return null;
      }

      return data;
    } catch (e) {
      debugPrint('Error currentMembership: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> plans() async {
    final rows = await _client
        .from('membership_plans')
        .select(
          'id, code, name, description, price_points, benefits, quota_amount',
        )
        .eq('is_active', true)
        .order('price_points');

    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<Map<String, dynamic>> purchase(int planId) async {
    final result = await _client.rpc(
      'purchase_membership_with_points',
      params: {'p_plan_id': planId},
    );
    return Map<String, dynamic>.from(result as Map);
  }
}
