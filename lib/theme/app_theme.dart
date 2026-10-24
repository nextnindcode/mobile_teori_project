import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme — Premium Cosmic EclipseVerse Design System
/// Inspired by deep space, celestial eclipses, and connected fandom universes.
class AppTheme {
  // ===== Core Cosmic Palette =====
  static const Color deepSpace = Color(0xFF17152B); // Twilight space: atmospheric, not pitch black
  static const Color surfaceElevated = Color(0xFF24213F); // Nebula surface
  static const Color surfaceSecondary = Color(0xFF302D50); // Elevated lavender-indigo surface
  static const Color surfaceGlass = Color(0x55302D50); // Soft glassmorphic surface

  // ===== Semantic Accents =====
  static const Color eclipseViolet = Color(0xFFB39AFB); // Luminous eclipse lavender
  static const Color nebulaIndigo = Color(0xFF858FF8); // Nebula periwinkle
  static const Color coronaGold = Color(0xFFFFD98A); // Warm corona gold
  static const Color coolCyan = Color(0xFF8DE8F2); // Starlight cyan

  // ===== Text & Neutral Colors =====
  static const Color textPrimary = Color(0xFFFFFCFF); // Starlight white
  static const Color textSecondary = Color(0xFFD0CDE5); // Soft moonlight text
  static const Color textMuted = Color(0xFFA6A1C1); // Muted nebula text
  static const Color borderSubtle = Color(0x558DE8F2); // Visible but gentle starlight border
  static const Color borderLight = Color(0x1FFFFFFF); // Subtle white divider

  // ===== Backward Compatibility Aliases =====
  static const Color primaryDark = eclipseViolet;
  static const Color primaryLight = nebulaIndigo;
  static const Color background = deepSpace;
  static const Color surface = surfaceElevated;
  static const Color white = textPrimary;
  static const Color black = deepSpace;
  static const Color blackSoft = surfaceElevated;
  static const Color grey = textSecondary;
  static const Color greyLight = borderSubtle;

  // ===== Status Colors =====
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color accentYellow = coronaGold;
  static const Color accentGrey = textMuted;

  // ===== Cosmic Gradients =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [eclipseViolet, nebulaIndigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cosmicHeroGradient = LinearGradient(
    colors: [Color(0xFF58428B), Color(0xFF393C72), Color(0xFF252744)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [surfaceSecondary, surfaceElevated],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coronaGradient = LinearGradient(
    colors: [coronaGold, Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [coolCyan, nebulaIndigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== Spacing Constants =====
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // ===== Corner Radii =====
  static const double radiusSmall = 8.0;
  static const double radius = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusFull = 999.0;

  // ===== Font Sizes =====
  static const double fontSizeDisplay = 32.0;
  static const double fontSizeHeadline = 24.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeSubtitle = 16.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeBodySmall = 12.0;
  static const double fontSizeCaption = 10.0;

  // ===== Text Theme =====
  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: fontSizeDisplay,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: fontSizeHeadline,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: fontSizeTitle,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: fontSizeSubtitle,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: fontSizeBody,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: fontSizeBodySmall,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: fontSizeCaption,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
      );

  // ===== Button Styles =====
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: eclipseViolet,
        foregroundColor: textPrimary,
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: fontSizeBody,
          letterSpacing: 0.5,
        ),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        elevation: 4,
        shadowColor: eclipseViolet.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: 14,
        ),
      );

  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: coolCyan,
        side: const BorderSide(color: coolCyan, width: 1.2),
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: fontSizeBody,
        ),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: 14,
        ),
      );

  // ===== Main Cosmic Theme =====
  static ThemeData cosmicTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepSpace,
      primaryColor: eclipseViolet,

      colorScheme: const ColorScheme.dark(
        primary: eclipseViolet,
        onPrimary: textPrimary,
        secondary: nebulaIndigo,
        onSecondary: textPrimary,
        tertiary: coolCyan,
        surface: surfaceElevated,
        onSurface: textPrimary,
        error: error,
        onError: textPrimary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: deepSpace,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: fontSizeTitle,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceElevated,
        selectedItemColor: eclipseViolet,
        unselectedItemColor: textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: coolCyan, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: fontSizeBody,
          color: textMuted,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: fontSizeBody,
          color: textSecondary,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),

      textTheme: textTheme,
      dividerTheme: const DividerThemeData(color: borderLight, thickness: 1),
      iconTheme: const IconThemeData(color: textPrimary, size: 22),
    );
  }

  // Alias for backward compatibility
  static ThemeData light() => cosmicTheme();
  static ThemeData dark() => cosmicTheme();
}
