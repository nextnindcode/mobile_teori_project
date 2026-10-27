import 'package:eclipseverse/core/api_service.dart';
import 'package:intl/intl.dart';
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
      source: '${payload['source'] ?? 'live'}',
    );
  }
}

class CurrencyService {
  // Mata uang utama + beberapa negara yang relevan untuk fandom/travel.
  static const preferredCodes = [
    'IDR', 'USD', 'MYR', 'SGD', 'THB', 'KRW', 'JPY', 'CNY', 'GBP', 'EUR', 'AUD',
  ];

  static List<String> codesFor(CurrencyRates rates) => preferredCodes
      .where((code) => rates.rates.containsKey(code) && rates.rates[code] != 0)
      .toList();

  static Future<CurrencyRates> fetchRates() async {
    final data = await ApiService.get('/currency/rates', query: {'base': 'USD'});
    final rates = CurrencyRates.fromJson(Map<String, dynamic>.from(data as Map));
    if (codesFor(rates).length < 3) {
      throw Exception('Kurs belum tersedia lengkap.');
    }
    return rates;
  }

  static String format(String code, double value) {
    final decimals = code == 'USD' || code == 'GBP' || code == 'EUR' ? 2 : 0;
    return NumberFormat.decimalPatternDigits(
      locale: 'id_ID',
      decimalDigits: decimals,
    ).format(value);
  }

  static String flag(String code) {
    const flags = {
      'IDR': '🇮🇩',
      'USD': '🇺🇸',
      'MYR': '🇲🇾',
      'SGD': '🇸🇬',
      'THB': '🇹🇭',
      'KRW': '🇰🇷',
      'JPY': '🇯🇵',
      'CNY': '🇨🇳',
      'GBP': '🇬🇧',
      'EUR': '🇪🇺',
      'AUD': '🇦🇺',
    };
    return flags[code] ?? '🌐';
  }
}
