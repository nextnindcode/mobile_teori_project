import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'membership_service.dart';

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});
  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _active;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([MembershipService.plans(), MembershipService.currentMembership()]);
      if (!mounted) return;
      setState(() {
        _plans = results[0] as List<Map<String, dynamic>>;
        _active = results[1] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _buy(Map<String, dynamic> plan) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await MembershipService.purchase((plan['id'] as num).toInt());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Pembayaran simulasi berhasil. Membership aktif sampai ${result['expires_at']}.'),
        backgroundColor: AppTheme.success,
      ));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pembelian gagal: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _price(dynamic value) {
    final digits = (value as num).toInt().toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      out.write(digits[i]);
      if ((digits.length - i - 1) % 3 == 0 && i != digits.length - 1) out.write('.');
    }
    return 'Rp $out';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('EclipseVerse Membership')),
    body: _loading ? const Center(child: CircularProgressIndicator()) :
      _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Membership belum dapat dimuat. Pastikan migrasi Supabase sudah dijalankan.\n$_error', textAlign: TextAlign.center))) :
      ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.borderSubtle)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.workspace_premium, color: AppTheme.coronaGold, size: 36),
            const SizedBox(height: 8),
            Text(_active == null ? 'Buka akses member' : 'Membership aktif', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_active == null ? 'Akses mode mini-game khusus dan kategori Collectibles. Pembayaran ini simulasi untuk proyek.' : 'Berlaku sampai ${_active!['expires_at']}', style: const TextStyle(color: AppTheme.textSecondary)),
          ]),
        ),
        const SizedBox(height: 16),
        for (final plan in _plans) Card(
          child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${plan['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text('${plan['description'] ?? ''}'),
            const SizedBox(height: 8),
            Text(_price(plan['price_idr']), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.coronaGold, fontSize: 20)),
            Text('Masa aktif ${plan['duration_days']} hari'),
            const SizedBox(height: 8),
            if (plan['benefits'] is List) for (final benefit in plan['benefits'] as List) Text('• $benefit'),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _busy || _active != null ? null : () => _buy(plan),
              child: Text(_busy ? 'Memproses...' : _active != null ? 'Membership sudah aktif' : 'Bayar simulasi'),
            )),
          ])),
        ),
      ]),
  );
}
