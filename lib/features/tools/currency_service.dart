import 'package:eclipseverse/core/api_service.dart';

import 'package:intl/intl.dart';

import '../fandom/shared/json_utils.dart';

class CurrencyRates {
  final String base;
  final Map<String, double> rates;
  final DateTime updatedAt; // UTC
  final String source; // "live" | "cache"

  const CurrencyRates({
    required this.base,
    required this.rates,
    required this.updatedAt,
    required this.source,
  });

  /// hasil = jumlah / rate[asal] * rate[tujuan]
  double convert(double amount, String from, String to) =>
      amount / rates[from]! * rates[to]!;

  factory CurrencyRates.fromJson(Map<String, dynamic> j) {
    final payload =
        (j['data'] is Map) ? Map<String, dynamic>.from(j['data'] as Map) : j;
    final r = Map<String, dynamic>.from((payload['rates'] ?? {}) as Map);
    return CurrencyRates(
      base: '${payload['base'] ?? 'USD'}',
      rates: r.map((k, v) => MapEntry(k, toDouble(v))),
      updatedAt: parseUtc(payload['updated_at']),
      source: '${payload['source'] ?? 'live'}',
    );
  }
}

class CurrencyService {
  static const codes = ['IDR', 'USD', 'KRW', 'JPY'];

  static Future<CurrencyRates> fetchRates() async {
    final data = await ApiService.get(
      '/currency/rates',
      query: {'base': 'USD'},
    );
    final rates = CurrencyRates.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
    for (final c in codes) {
      if (!rates.rates.containsKey(c) || rates.rates[c] == 0) {
        throw Exception('Kurs belum tersedia');
      }
    }
    return rates;
  }

  /// IDR, KRW, JPY tanpa desimal; USD 2 desimal.
  static String format(String code, double v) =>
      NumberFormat.decimalPatternDigits(
        locale: 'id_ID',
        decimalDigits: code == 'USD' ? 2 : 0,
      ).format(v);
}
