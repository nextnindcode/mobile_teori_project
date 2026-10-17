class Constants {
  /// URL backend. Ganti TANPA edit kode lewat --dart-define:
  ///   flutter run -t lib/main_full.dart --dart-define=API_BASE=https://xxxx.trycloudflare.com/eclipseverse/api
  ///   flutter build apk --dart-define=API_BASE=https://xxxx.trycloudflare.com/eclipseverse/api
  /// Bila tidak diberi, dipakai nilai default di bawah (emulator + XAMPP).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2/eclipseverse/api',
  );

  static const String appName = 'EclipseVerse';
}
