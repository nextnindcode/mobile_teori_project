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
  int? _processingPlanId;
  String? _error;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _active;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        MembershipService.plans(),
        MembershipService.currentMembership(),
      ]);
      if (!mounted) return;
      setState(() {
        _plans = results[0] as List<Map<String, dynamic>>;
        _plans.sort(
          (a, b) => (a['price_idr'] as num).compareTo(b['price_idr'] as num),
        );
        _active = results[1] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _buy(Map<String, dynamic> plan) async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _processingPlanId = (plan['id'] as num).toInt();
    });

    try {
      await MembershipService.purchase((plan['id'] as num).toInt());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil! Kuota redeem bertambah.'),
          backgroundColor: AppTheme.success,
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Pembelian gagal: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _processingPlanId = null;
        });
      }
    }
  }

  String _price(dynamic value) {
    final digits = (value as num).toInt().toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      out.write(digits[i]);
      if ((digits.length - i - 1) % 3 == 0 && i != digits.length - 1)
        out.write('.');
    }
    return 'Rp $out';
  }

  @override
  Widget build(BuildContext context) {
    final int sisaKuota = _active?['redeem_quota'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('EclipseVerse Membership')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        color: Colors.amber,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _active == null
                            ? 'Buka Akses Member'
                            : 'Status Member Aktif',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _active == null
                            ? 'Beli paket di bawah untuk mulai menukar kartu eksklusif.'
                            : 'Sisa Kuota Tukar Kartu Kamu: $sisaKuota',
                        style: TextStyle(
                          color: _active == null
                              ? AppTheme.textSecondary
                              : Colors.amber,
                          fontWeight: _active == null
                              ? FontWeight.normal
                              : FontWeight.bold,
                          fontSize: _active == null ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Pilih Paket Kuota',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),

                // Daftar Paket
                for (final plan in _plans)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${plan['name']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${plan['code']}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${plan['description'] ?? ''}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _price(plan['price_idr']),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.coronaGold,
                              fontSize: 22,
                            ),
                          ),

                          const SizedBox(height: 12),
                          // Benefit
                          if (plan['benefits'] is List)
                            ...(plan['benefits'] as List).map(
                              (benefit) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.success,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$benefit',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              // Cek apakah ID paket ini yang lagi diproses
                              onPressed:
                                  _busy &&
                                      _processingPlanId ==
                                          (plan['id'] as num).toInt()
                                  ? null
                                  : () => _buy(plan),
                              child: Text(
                                _busy &&
                                        _processingPlanId ==
                                            (plan['id'] as num).toInt()
                                    ? 'Memproses...'
                                    : 'Beli Paket Ini',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
