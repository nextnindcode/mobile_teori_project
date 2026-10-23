import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CurrencyRates {
  final String base;
  final Map<String, double> rates;
  final DateTime updatedAt;
  final String source;

  const CurrencyRates({required this.base, required this.rates, required this.updatedAt, required this.source});

  double convert(double amount, String from, String to) => amount / rates[from]! * rates[to]!;

  factory CurrencyRates.fromJson(Map<String, dynamic> j) {
    return CurrencyRates(
      base: '${j['base_code'] ?? 'USD'}',
      rates: { '${j['target_code']}': (j['rate'] as num).toDouble() },
      updatedAt: DateTime.tryParse('${j['fetched_at']}')?.toUtc() ?? DateTime.now().toUtc(),
      source: '${j['source'] ?? 'demo'}',
    );
  }
}

class CurrencyService {
  static const codes = ['IDR', 'USD', 'KRW', 'JPY'];
  static final _client = Supabase.instance.client;

  static Future<CurrencyRates> fetchRates() async {
    final rows = await _client.from('currency_rates')
        .select('base_code,target_code,rate,source,fetched_at')
        .eq('base_code', 'USD')
        .timeout(const Duration(seconds: 8));
    final rates = <String, double>{};
    DateTime updated = DateTime.now().toUtc();
    var source = 'demo';
    for (final row in rows) {
      rates['${row['target_code']}'] = (row['rate'] as num).toDouble();
      updated = DateTime.tryParse('${row['fetched_at']}')?.toUtc() ?? updated;
      source = '${row['source'] ?? 'demo'}';
    }
    rates['USD'] = 1;
    for (final code in codes) {
      if (!rates.containsKey(code) || rates[code] == 0) {
        throw Exception('Kurs $code belum tersedia di Supabase.');
      }
    }
    return CurrencyRates(base: 'USD', rates: rates, updatedAt: updated, source: source);
  }

  static String format(String code, double v) => NumberFormat.decimalPatternDigits(
    locale: 'id_ID', decimalDigits: code == 'USD' ? 2 : 0,
  ).format(v);
}
