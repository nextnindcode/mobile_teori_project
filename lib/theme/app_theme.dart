import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =========================================================
// AppTheme — EclipseOps
// Palet warna:
//   - #FFFBF5 (krem terang)  → background utama
//   - #F7EFE5 (krem)         → card, input, surface
//   - #C3ACD0 (lavender)     → aksen sekunder
//   - #674188 (ungu tua)     → warna utama (primary)
//   - Hitam / Abu-abu        → teks
// =========================================================

class AppTheme {
  // ===== Warna Utama (Primary) =====
  static const Color primaryDark = Color(0xFF674188); // Ungu tua
  static const Color primaryLight = Color(0xFFC3ACD0); // Lavender

  // ===== Warna Background & Surface =====
  static const Color background = Color(0xFFFFFBF5); // Krem terang
  static const Color surface = Color(0xFFF7EFE5); // Krem

  // ===== Warna Teks =====
  static const Color black = Color(0xFF212121); // Hitam
  static const Color blackSoft = Colors.black87;
  static const Color grey = Color(0xFF9E9E9E); // Abu-abu
  static const Color greyLight = Color(0xFFE0E0E0); // Abu-abu terang
  static const Color white = Colors.white;

  // ===== Warna Status =====
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);

  // ===== Aksen Tombol =====
  static const Color accentYellow = Color(0xFFFFC107); // Aksi utama (opsional)
  static const Color accentGrey = Color(0xFF9E9E9E); // Aksi sekunder

  // ===== Gradient (opsional) =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== Spacing =====
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // ===== Radius =====
  static const double radiusSmall = 8.0;
  static const double radius = 12.0;
  static const double radiusLarge = 16.0;

  // ===== Ukuran Font =====
  static const double fontSizeDisplay = 32.0;
  static const double fontSizeHeadline = 24.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeSubtitle = 18.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeBodySmall = 14.0;
  static const double fontSizeCaption = 12.0;

  // ===== Text Theme =====
  static TextTheme get textTheme => TextTheme(
    // Display — untuk judul besar
    displayLarge: GoogleFonts.poppins(
      fontSize: fontSizeDisplay,
      fontWeight: FontWeight.bold,
      color: black,
    ),
    // Headline — untuk judul halaman
    headlineMedium: GoogleFonts.poppins(
      fontSize: fontSizeHeadline,
      fontWeight: FontWeight.bold,
      color: black,
    ),
    // Title — untuk judul card/section
    titleLarge: GoogleFonts.poppins(
      fontSize: fontSizeTitle,
      fontWeight: FontWeight.w600,
      color: black,
    ),
    // Subtitle — untuk sub-judul
    titleMedium: GoogleFonts.poppins(
      fontSize: fontSizeSubtitle,
      fontWeight: FontWeight.w500,
      color: black,
    ),
    // Body — untuk teks isi
    bodyLarge: GoogleFonts.inter(fontSize: fontSizeBody, color: black),
    bodyMedium: GoogleFonts.inter(fontSize: fontSizeBodySmall, color: black),
    // Caption — untuk teks kecil
    bodySmall: GoogleFonts.inter(
      fontSize: fontSizeCaption,
      color: black.withValues(alpha: 0.6),
    ),
  );

  // ===== Style Tombol Primer (Ungu Tua) =====
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryDark,
    foregroundColor: white,
    textStyle: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: fontSizeBody,
    ),
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    elevation: 0,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingMedium,
      vertical: spacingSmall,
    ),
  );

  // ===== Style Tombol Sekunder (Lavender) =====
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryLight,
    foregroundColor: white,
    textStyle: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: fontSizeBody,
    ),
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    elevation: 0,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingMedium,
      vertical: spacingSmall,
    ),
  );

  // ===== Theme Data =====
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primaryDark,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryDark,
        onPrimary: white,
        secondary: primaryLight,
        onSecondary: black,
        surface: surface,
        onSurface: black,
        error: error,
        onError: white,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: fontSizeTitle,
          fontWeight: FontWeight.bold,
          color: white,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.inter(fontSize: fontSizeBody, color: grey),
        labelStyle: GoogleFonts.inter(fontSize: fontSizeBody, color: black),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 2,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),

      // Text
      textTheme: textTheme,

      // Divider
      dividerTheme: const DividerThemeData(color: greyLight, thickness: 1),

      // Icon
      iconTheme: const IconThemeData(color: black, size: 24),
    );
  }
}
