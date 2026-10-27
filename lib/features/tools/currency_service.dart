import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../core/local_db.dart';

class CurrencyRates {
  final String base;
  final Map<String, double> rates;
  final DateTime updatedAt;
  final String source;

  const CurrencyRates({required this.base, required this.rates, required this.updatedAt, required this.source});

  double convert(double amount, String from, String to) {
    final fromRate = rates[from];
    final toRate = rates[to];
    if (fromRate == null || toRate == null || fromRate == 0) throw ArgumentError('Kurs $from atau $to belum tersedia.');
    return amount / fromRate * toRate;
  }

  factory CurrencyRates.fromJson(Map<String, dynamic> json) {
    final rawRates = Map<String, dynamic>.from(json['rates'] as Map);
    return CurrencyRates(
      base: '${json['base'] ?? 'USD'}',
      rates: rawRates.map((key, value) => MapEntry(key, (value as num).toDouble())),
      updatedAt: DateTime.parse('${json['updated_at']}').toUtc(),
      source: '${json['source'] ?? 'ExchangeRate-API'}',
    );
  }

  Map<String, dynamic> toJson() => {'base': base, 'rates': rates, 'updated_at': updatedAt.toIso8601String(), 'source': source};
}

class CurrencyService {
  // Daftar utama diperluas agar merchandise dapat dibandingkan lintas negara.
  static const codes = ['IDR', 'USD', 'KRW', 'JPY', 'MYR', 'SGD', 'THB', 'GBP', 'EUR', 'CNY', 'AUD'];
  static const _cacheKey = 'currency_rates_cache';
  static const _apiUrl = 'https://open.er-api.com/v6/latest/USD';

  static Future<CurrencyRates> fetchRates() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) throw Exception('API kurs tidak merespons.');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['result'] != 'success' || body['rates'] is! Map) throw Exception('Format data kurs dari API tidak valid.');
      final apiRates = Map<String, dynamic>.from(body['rates'] as Map);
      final rates = <String, double>{'USD': 1};
      for (final code in codes) {
        final value = apiRates[code];
        if (value is! num || value <= 0) throw Exception('Kurs $code tidak tersedia dari API.');
        rates[code] = value.toDouble();
      }
      final unix = body['time_last_update_unix'];
      final updatedAt = unix is num ? DateTime.fromMillisecondsSinceEpoch(unix.toInt() * 1000, isUtc: true) : DateTime.now().toUtc();
      final result = CurrencyRates(base: 'USD', rates: rates, updatedAt: updatedAt, source: 'ExchangeRate-API');
      await LocalDb.setPref(_cacheKey, jsonEncode(result.toJson()));
      return result;
    } catch (error) {
      final cached = await LocalDb.getPref(_cacheKey);
      if (cached != null) {
        try {
          final result = CurrencyRates.fromJson(Map<String, dynamic>.from(jsonDecode(cached) as Map));
          return CurrencyRates(base: result.base, rates: result.rates, updatedAt: result.updatedAt, source: '${result.source} (cache terakhir)');
        } catch (_) {}
      }
      rethrow;
    }
  }

  static String format(String code, double value) => NumberFormat.decimalPatternDigits(locale: 'id_ID', decimalDigits: code == 'USD' || code == 'GBP' || code == 'EUR' ? 2 : 0).format(value);
}
