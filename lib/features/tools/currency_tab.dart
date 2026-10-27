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
      final rates = await CurrencyService.fetchRates();

      if (!mounted) return;

      setState(() {
        _rates = rates;
      });
    } catch (e) {
      if (!mounted) return;

      final message = friendlyError(e);

      setState(() {
        _error = message == 'Tidak ada koneksi'
            ? message
            : 'Kurs belum tersedia';
      });
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  double? get _value {
    final value = double.tryParse(_amount.text.trim().replaceAll(',', '.'));

    return value != null && value > 0 ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingView();
    }

    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    final rates = _rates!;
    final value = _value;
    final codes = CurrencyService.codesFor(rates);

    if (!codes.contains(_from)) {
      _from = codes.contains('IDR') ? 'IDR' : rates.base;
    }

    final targetCodes = codes.where((code) => code != _from).toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      children: [
        Card(
          color: AppTheme.surfaceElevated,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Jumlah',
                errorText: value == null ? 'Masukkan angka lebih dari 0' : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),

        DropdownField<String>(
          label: 'Dari mata uang',
          value: _from,
          items: codes
              .map((code) => DropdownMenuItem(value: code, child: Text(code)))
              .toList(),
          onChanged: (code) {
            if (code == null) return;

            setState(() {
              _from = code;
            });
          },
        ),
        const SizedBox(height: AppTheme.spacingMedium),

        if (value != null)
          ...List.generate((targetCodes.length + 1) ~/ 2, (rowIndex) {
            final rowCodes = targetCodes.skip(rowIndex * 2).take(2).toList();

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final code in rowCodes)
                  Expanded(
                    child: Card(
                      color: AppTheme.surfaceElevated,
                      margin: const EdgeInsets.all(5),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              code,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyService.format(
                                code,
                                rates.convert(value, _from, code),
                              ),
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (rowCodes.length == 1) const Expanded(child: SizedBox()),
              ],
            );
          }),

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
