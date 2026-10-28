import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/local_db.dart';
import '../fandom/shared/json_utils.dart';

class CurrencyRates {
  final String base;
  final Map<String, double> rates;
  final DateTime updatedAt;
  final String source;

  const CurrencyRates({
    required this.base,
    required this.rates,
    required this.updatedAt,
    required this.source,
  });

  double convert(double amount, String from, String to) {
    final fromRate = rates[from];
    final toRate = rates[to];
    if (fromRate == null || toRate == null || fromRate == 0) {
      throw Exception('Kurs $from/$to belum tersedia.');
    }
    return amount / fromRate * toRate;
  }

  factory CurrencyRates.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final rawRates = payload['rates'];
    final rates = rawRates is Map
        ? Map<String, dynamic>.from(rawRates)
        : <String, dynamic>{};

    return CurrencyRates(
      base: '${payload['base'] ?? 'USD'}'.toUpperCase(),
      rates: rates.map((key, value) => MapEntry(key.toUpperCase(), toDouble(value))),
      updatedAt: parseUtc(payload['updated_at']),
      source: '${payload['source'] ?? 'ExchangeRate-API'}',
    );
  }

  Map<String, dynamic> toJson() => {
        'base': base,
        'rates': rates,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'source': source,
      };
}

class CurrencyService {
  // Malaysia sementara dihapus sampai kurs MYR terverifikasi.
  static const preferredCodes = [
    'IDR', 'USD', 'SGD', 'THB', 'KRW', 'JPY', 'CNY', 'GBP', 'EUR', 'AUD',
  ];
  static const _cacheKey = 'currency_rates_cache';
  static const _apiUrl = 'https://open.er-api.com/v6/latest/USD';

  static List<String> codesFor(CurrencyRates rates) => preferredCodes
      .where((code) => rates.rates.containsKey(code) && rates.rates[code] != 0)
      .toList();

  static Future<CurrencyRates> fetchRates() async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception('API kurs tidak merespons (HTTP ${response.statusCode}).');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['result'] != 'success' || body['rates'] is! Map) {
        throw Exception('Format data kurs dari API tidak valid.');
      }

      final apiRates = Map<String, dynamic>.from(body['rates'] as Map);
      final rates = <String, double>{};
      for (final code in preferredCodes) {
        final value = apiRates[code];
        if (value is num && value > 0) rates[code] = value.toDouble();
      }
      rates['USD'] = 1;
      if (!rates.containsKey('IDR') || rates.length < 3) {
        throw Exception('Data kurs dari API belum lengkap.');
      }

      final unix = body['time_last_update_unix'];
      final updatedAt = unix is num
          ? DateTime.fromMillisecondsSinceEpoch(unix.toInt() * 1000, isUtc: true)
          : DateTime.now().toUtc();
      final result = CurrencyRates(
        base: 'USD',
        rates: rates,
        updatedAt: updatedAt,
        source: 'ExchangeRate-API',
      );
      await LocalDb.setPref(_cacheKey, jsonEncode(result.toJson()));
      return result;
    } catch (error) {
      final cached = await LocalDb.getPref(_cacheKey);
      if (cached != null) {
        try {
          final result = CurrencyRates.fromJson(
            Map<String, dynamic>.from(jsonDecode(cached) as Map),
          );
          return CurrencyRates(
            base: result.base,
            rates: result.rates,
            updatedAt: result.updatedAt,
            source: '${result.source} (cache terakhir)',
          );
        } catch (_) {
          // Abaikan cache yang tidak valid; tampilkan error API.
        }
      }
      rethrow;
    }
  }

  static String format(String code, double value) =>
      NumberFormat.decimalPatternDigits(
        locale: 'id_ID',
        decimalDigits: const ['USD', 'GBP', 'EUR', 'AUD'].contains(code) ? 2 : 0,
      ).format(value);

  static String flag(String code) {
    const flags = {
      'IDR': '🇮🇩', 'USD': '🇺🇸', 'SGD': '🇸🇬', 'THB': '🇹🇭',
      'KRW': '🇰🇷', 'JPY': '🇯🇵', 'CNY': '🇨🇳', 'GBP': '🇬🇧',
      'EUR': '🇪🇺', 'AUD': '🇦🇺',
    };
    return flags[code] ?? '🌐';
  }
}
