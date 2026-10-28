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
  final _amount = TextEditingController(text: '100000');
  String _from = 'IDR';
  CurrencyRates? _rates;
  bool _loading = true;
  bool _converted = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _amount.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rates = await CurrencyService.fetchRates();
      if (!mounted) return;
      setState(() {
        _rates = rates;
        _loading = false;
        if (!CurrencyService.codesFor(rates).contains(_from)) _from = 'IDR';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = friendlyError(e) == 'Tidak ada koneksi' ? 'Tidak ada koneksi' : 'Kurs belum tersedia'; });
    }
  }

  double? get _value {
    final value = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final rates = _rates!;
    final value = _value;
    final codes = CurrencyService.codesFor(rates);
    final targetCodes = codes.where((code) => code != _from).toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      children: [
        Text('Eclipse Currency', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Hitung harga merchandise dalam mata uang negara lain menggunakan kurs dari API aplikasi.', style: TextStyle(color: AppTheme.textSecondary, height: 1.45)),
        const SizedBox(height: 16),
        Card(
          color: AppTheme.surfaceElevated,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Nilai yang ingin dikonversi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() { _converted = false; }),
                decoration: const InputDecoration(labelText: 'Jumlah', prefixIcon: Icon(Icons.payments_outlined)),
              ),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Dari mata uang',
                value: codes.contains(_from) ? _from : codes.first,
                items: codes.map((code) => DropdownMenuItem(value: code, child: Text('${CurrencyService.flag(code)}  $code'))).toList(),
                onChanged: (code) { if (code != null) setState(() { _from = code; _converted = false; }); },
              ),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: value == null ? null : () => setState(() => _converted = true),
                icon: const Icon(Icons.currency_exchange_rounded),
                label: const Text('Konversi Harga'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.eclipseViolet, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              )),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Hasil konversi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(_converted ? 'Nilai setara dari $value $_from.' : 'Tekan Konversi Harga untuk melihat hasil.', style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        if (_converted && value != null)
          ...targetCodes.map((code) {
            final converted = rates.convert(value, _from, code);
            return Card(
              color: AppTheme.surfaceElevated,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(CurrencyService.flag(code), style: const TextStyle(fontSize: 25)),
                title: Text(code, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('1 $_from → ${CurrencyService.format(code, rates.convert(1, _from, code))} $code'),
                trailing: Text(CurrencyService.format(code, converted), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.coolCyan)),
              ),
            );
          }),
        if (!_converted)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: EmptyView(title: 'Belum ada hasil', subtitle: 'Masukkan nominal lalu tekan Konversi Harga.'),
          ),
        const SizedBox(height: 8),
        Text('Diperbarui: ${DateFormat('d MMM yyyy HH:mm').format(rates.updatedAt.toLocal())} • ${rates.source}', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}
