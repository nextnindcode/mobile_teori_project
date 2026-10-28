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
  String _from = 'USD';
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
      setState(() => _rates = rates);
    } catch (error) {
      if (!mounted) return;
      final message = friendlyError(error);
      setState(() {
        _error = message == 'Tidak ada koneksi'
            ? message
            : 'Kurs belum tersedia. Coba muat ulang.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? get _value {
    final value = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null || _rates == null) {
      return ErrorView(
        message: _error ?? 'Kurs belum tersedia.',
        onRetry: _load,
      );
    }

    final rates = _rates!;
    final amount = _value;
    final availableCodes = CurrencyService.codesFor(rates);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMedium,
        AppTheme.spacingMedium,
        AppTheme.spacingMedium,
        AppTheme.spacingXLarge,
      ),
      children: [
        _buildHero(),
        const SizedBox(height: AppTheme.spacingLarge),
        _sectionHeading(
          icon: Icons.edit_outlined,
          title: 'Jumlah yang ingin dikonversi',
          subtitle: 'Masukkan nominal, lalu pilih mata uang asal.',
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: InputDecoration(
              labelText: 'Nominal',
              hintText: 'Contoh: 100',
              prefixIcon: const Icon(
                Icons.payments_outlined,
                color: AppTheme.coronaGold,
              ),
              suffixText: _from,
              errorText: amount == null ? 'Masukkan angka lebih dari 0' : null,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingLarge),
        _sectionHeading(
          icon: Icons.public,
          title: 'Mata uang asal',
          subtitle: 'Geser untuk memilih mata uang.',
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: availableCodes.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppTheme.spacingSmall),
            itemBuilder: (context, index) {
              final code = availableCodes[index];
              final selected = code == _from;
              return ChoiceChip(
                selected: selected,
                onSelected: (_) => setState(() => _from = code),
                avatar: Text(CurrencyService.flag(code)),
                label: Text(code),
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: selected ? AppTheme.deepSpace : AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: AppTheme.eclipseViolet,
                backgroundColor: AppTheme.surfaceSecondary,
                side: BorderSide(
                  color: selected
                      ? AppTheme.eclipseViolet
                      : AppTheme.borderSubtle,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingLarge),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _sectionHeading(
                icon: Icons.currency_exchange,
                title: 'Hasil konversi',
                subtitle: amount == null
                    ? 'Isi nominal untuk melihat hasil.'
                    : '${CurrencyService.format(_from, amount)} $_from setara dengan',
              ),
            ),
            IconButton(
              tooltip: 'Muat ulang kurs',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        if (amount != null)
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppTheme.spacingSmall,
            mainAxisSpacing: AppTheme.spacingSmall,
            childAspectRatio: 0.98,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final code in availableCodes.where((code) => code != _from))
                _buildResultCard(
                  code: code,
                  amount: rates.convert(amount, _from, code),
                  sourceCode: _from,
                  sourceAmount: amount,
                ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: const Text(
              'Nominal harus lebih besar dari 0 agar hasil konversi bisa dihitung.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        const SizedBox(height: AppTheme.spacingMedium),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceGlass,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: AppTheme.coolCyan,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Diperbarui: ${DateFormat('d MMM yyyy, HH:mm').format(rates.updatedAt.toLocal())}\nSumber: ${rates.source}. Nilai kurs dapat berubah.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        height: 1.6,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.cosmicHeroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 0,
            top: 0,
            child: Icon(
              Icons.auto_awesome,
              size: 62,
              color: Color(0x55FFFCFF),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.textPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Text(
                  'COSMIC CURRENCY',
                  style: TextStyle(
                    color: AppTheme.coolCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Jelajahi nilai\nantar mata uang',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      height: 1.15,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Konversi IDR, USD, KRW, dan JPY dalam satu tempat.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.eclipseViolet.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.eclipseViolet, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard({
    required String code,
    required double amount,
    required String sourceCode,
    required double sourceAmount,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                CurrencyService.flag(code),
                style: const TextStyle(fontSize: 23),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  code,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(
                Icons.north_east_rounded,
                size: 16,
                color: AppTheme.coolCyan,
              ),
            ],
          ),
          const Spacer(),
          Text(
            CurrencyService.format(code, amount),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.coronaGold,
                  fontSize: 19,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            '$sourceCode → $code',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            width: 34,
            decoration: BoxDecoration(
              color: AppTheme.eclipseViolet,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
