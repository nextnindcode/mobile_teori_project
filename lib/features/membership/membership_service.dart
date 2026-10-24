import 'package:supabase_flutter/supabase_flutter.dart';

class MembershipService {
  static final _client = Supabase.instance.client;

  static Future<bool> isActive() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final row = await _client.rpc(
      'has_active_membership',
      params: {'p_user_id': user.id},
    );
    return row == true;
  }

  static Future<Map<String, dynamic>?> currentMembership() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final rows = await _client
        .from('user_memberships')
        .select(
          'id, status, starts_at, expires_at, redeem_quota, membership_plans(name, benefits)',
        )
        .eq('user_id', user.id)
        .eq('status', 'active')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('expires_at', ascending: false)
        .limit(1);

    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
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
