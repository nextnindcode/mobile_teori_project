import 'package:flutter_test/flutter_test.dart';
import 'package:eclipseverse/features/tools/currency_service.dart';
import 'package:eclipseverse/features/tools/time_service.dart';

void main() {
  group('Unit Test Konversi Kurs (Anggota B)', () {
    final rates = CurrencyRates(
      base: 'USD',
      rates: const {
        'USD': 1.0,
        'IDR': 16000.0,
        'KRW': 1300.0,
        'JPY': 150.0,
      },
      updatedAt: DateTime.utc(2026, 10, 17, 12, 0),
      source: 'live',
    );

    test('Konversi USD ke IDR', () {
      final res = rates.convert(100, 'USD', 'IDR');
      expect(res, 1600000.0);
    });

    test('Konversi USD ke KRW dan JPY', () {
      expect(rates.convert(10, 'USD', 'KRW'), 13000.0);
      expect(rates.convert(10, 'USD', 'JPY'), 1500.0);
    });

    test('Konversi silang non-USD (IDR ke JPY)', () {
      // 16000 IDR = 1 USD = 150 JPY
      final res = rates.convert(16000, 'IDR', 'JPY');
      expect(res, 150.0);
    });

    test('Formatting angka kurs sesuai aturan', () {
      // USD 2 desimal, lainnya 0 desimal
      expect(CurrencyService.format('USD', 123.456), '123,46');
      expect(CurrencyService.format('IDR', 123456.78), '123.457');
    });
  });

  group('Unit Test Konversi Waktu (Anggota B)', () {
    test('Konversi 20:00 KST = 18:00 WIB = 19:00 WITA = 20:00 WIT', () {
      // 20:00 KST (Asia/Seoul) pada hari tertentu
      // KST adalah UTC+9. 20:00 KST = 11:00 UTC.
      final utcTime = TimeService.toUtc(2026, 10, 20, 20, 0, 'Asia/Seoul');
      expect(utcTime.hour, 11);

      final wib = TimeService.at(utcTime, TimeService.wib.tzName);
      final wita = TimeService.at(utcTime, TimeService.wita.tzName);
      final wit = TimeService.at(utcTime, TimeService.wit.tzName);

      expect(wib.hour, 18);
      expect(wita.hour, 19);
      expect(wit.hour, 20);
    });

    test('convertAll mengembalikan 4 zona: WIB, WITA, WIT, London', () {
      final utc = DateTime.utc(2026, 10, 20, 12, 0);
      final result = TimeService.convertAll(utc);

      expect(result.containsKey('WIB'), isTrue);
      expect(result.containsKey('WITA'), isTrue);
      expect(result.containsKey('WIT'), isTrue);
      expect(result.containsKey('London'), isTrue);
    });
  });
}

