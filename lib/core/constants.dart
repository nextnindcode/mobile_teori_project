class Constants {
  /// Override with --dart-define=API_BASE_URL=...
  /// Default: Android Emulator + XAMPP (backend at htdocs/eclipseverse/api).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2/eclipseverse/api',
  );

  static const String appName = 'EclipseVerse';

  /// Resolves image URLs distinguishing API base URL from backend host root.
  /// If the URL is relative (e.g. "/uploads/products/1.jpg"), it resolves against
  /// the server root (stripping `/api` suffix) rather than appending to `/api`.
  static String? resolveImageUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Strip trailing slash from baseUrl
    String cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    // Remove /api suffix to get the web root for static images
    if (cleanBase.endsWith('/api')) {
      cleanBase = cleanBase.substring(0, cleanBase.length - 4);
    }

    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$cleanBase$path';
  }
}
