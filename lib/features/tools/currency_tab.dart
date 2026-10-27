import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eclipseverse/theme/app_theme.dart';

import '../fandom/shared/state_views.dart';
import 'currency_service.dart';

class CurrencyTab extends StatefulWidget {
  const CurrencyTab({super.key});
  @override
  State<CurrencyTab> createState() => _CurrencyTabState();
}

class _CurrencyTabState extends State<CurrencyTab> {
  final _amount = TextEditingController(text: '100');
  String _from = 'IDR';
  CurrencyRates? _rates;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await CurrencyService.fetchRates();
      if (!mounted) return;
      setState(() => _rates = r);
    } catch (e) {
      if (!mounted) return;
      final msg = friendlyError(e);
      setState(
        () => _error = msg == 'Tidak ada koneksi' ? msg : 'Kurs belum tersedia',
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  double? get _value {
    final v = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    return (v != null && v > 0) ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    final rates = _rates!;
    final v = _value;
    final codes = CurrencyService.codesFor(rates);
    if (!codes.contains(_from)) _from = codes.contains('IDR') ? 'IDR' : rates.base;
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      children: [
        Card(
          color: AppTheme.surfaceElevated,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Jumlah',
            errorText: v == null ? 'Masukkan angka lebih dari 0' : null,
          ),
        ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        DropdownField<String>(
          label: 'Dari mata uang',
          value: _from,
          items: codes
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (c) => setState(() => _from = c ?? _from),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        if (v != null)
          for (var i = 0; i < codes.where((c) => c != _from).length; i += 2)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: codes.where((c) => c != _from).skip(i).take(2).map((c) => Expanded(
                child: Card(
                  color: AppTheme.surfaceElevated,
                  margin: const EdgeInsets.all(5),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(CurrencyService.format(c, rates.convert(v, _from, c)),
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          'Diperbarui: ${DateFormat('d MMM yyyy HH:mm').format(rates.updatedAt.toLocal())} • Sumber: ${rates.source}',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
