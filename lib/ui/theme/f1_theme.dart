import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class F1Theme {
  // Official F1 Brand Palette
  static const Color f1Red = Color(0xFFE10600);
  static const Color f1DarkRed = Color(0xFF990000);
  static const Color carbonBlack = Color(0xFF0C0D12);
  static const Color surfaceDark = Color(0xFF141721);
  static const Color surfaceBorder = Color(0xFF242A38);
  static const Color cardBg = Color(0xFF1A1E2B);
  static const Color cardHighlight = Color(0xFF202636);

  // Timing & Telemetry Colors (Official Broadcast Style)
  static const Color purpleSector = Color(0xFFB800FF); // Overall fastest lap
  static const Color greenSector = Color(0xFF00D2BE);  // Personal best
  static const Color yellowSector = Color(0xFFFFD700); // Normal / slower
  static const Color drsGreen = Color(0xFF00FF7F);     // DRS enabled
  static const Color safetyCarAmber = Color(0xFFFF9E00);

  // Typography - Official F1 Aesthetic
  static TextStyle f1Display({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w900,
    Color color = Colors.white,
    double letterSpacing = 0.5,
    bool italic = true,
  }) {
    return GoogleFonts.titilliumWeb(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle f1Body({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
    double letterSpacing = 0.0,
  }) {
    return GoogleFonts.titilliumWeb(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle f1Mono({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.bold,
    Color color = Colors.white,
  }) {
    return GoogleFonts.robotoMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.titilliumWebTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: carbonBlack,
      primaryColor: f1Red,
      colorScheme: const ColorScheme.dark(
        primary: f1Red,
        secondary: Color(0xFF00D2BE),
        surface: surfaceDark,
      ),
      textTheme: baseTextTheme,
      cardTheme: const CardThemeData(
        color: cardBg,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: surfaceBorder, width: 1.2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: carbonBlack,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  // Elevated Glassmorphism & Carbon Styling
  static BoxDecoration glassCardDecoration({
    Color? borderColor,
    double borderWidth = 1.0,
    double borderRadius = 8.0,
    Color? glowColor,
  }) {
    return BoxDecoration(
      color: surfaceDark.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? surfaceBorder, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: (glowColor ?? Colors.black).withValues(alpha: 0.25),
          blurRadius: 10,
          spreadRadius: 1,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static BoxDecoration carbonCardDecoration({
    Color? accentColor,
    double borderRadius = 8.0,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF191D28), Color(0xFF10121A)],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: accentColor ?? surfaceBorder, width: accentColor != null ? 1.5 : 1.0),
      boxShadow: accentColor != null
          ? [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ]
          : null,
    );
  }
}
