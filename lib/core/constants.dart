class Constants {
  /// Override with --dart-define=API_BASE_URL=...
  /// Default: Android Emulator + XAMPP (backend at htdocs/eclipseverse/api).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2/eclipseverse/api',
  );

  static const String appName = 'EclipseVerse';
}
