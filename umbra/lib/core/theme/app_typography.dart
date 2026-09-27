import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Prototipteki iki yazı ailesi:
///  - `Newsreader` → serif, başlıklar ve hafıza ifadeleri
///  - `Public Sans` → arayüz metinleri
abstract final class AppTypography {
  static const String serif = 'Newsreader';
  static const String sans = 'Public Sans';

  static TextStyle serifStyle({
    double size = 18,
    FontWeight weight = FontWeight.w400,
    bool italic = false,
    double height = 1.2,
    Color color = const Color(0xFF2B2620),
    double? letterSpacing,
  }) {
    return GoogleFonts.newsreader(
      fontSize: size,
      fontWeight: weight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle sansStyle({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    double height = 1.35,
    Color color = const Color(0xFF2B2620),
    double? letterSpacing,
  }) {
    return GoogleFonts.publicSans(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Tüm uygulama için gövde varsayılanı.
  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2B2620),
        surface: const Color(0xFFF6F1E7),
      ),
      scaffoldBackgroundColor: const Color(0xFFF6F1E7),
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: GoogleFonts.publicSansTextTheme(base.textTheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2B2620),
          foregroundColor: const Color(0xFFF6F1E7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFFFFDF8),
        border: InputBorder.none,
        isDense: true,
      ),
      dividerColor: const Color(0xFFEEE7D9),
    );
  }
}
