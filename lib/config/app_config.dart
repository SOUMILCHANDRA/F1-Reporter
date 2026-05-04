import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConfig {
  static const String defaultBaseUrl = 'https://f1-reporter.onrender.com';
  
  // Colors
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color card = Color(0xFF1C1C1C);
  static const Color accentRed = Color(0xFFE8002D);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);
  static const Color border = Color(0xFF2A2A2A);

  // Themes
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: accentRed,
    cardTheme: const CardTheme(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.orbitron(color: textPrimary, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.orbitron(color: textPrimary, fontWeight: FontWeight.bold),
      bodyLarge: GoogleFonts.rajdhani(color: textPrimary),
      bodyMedium: GoogleFonts.rajdhani(color: textPrimary),
      labelSmall: GoogleFonts.jetbrainsMono(color: textSecondary),
    ),
  );

  static TextStyle get monoStyle => GoogleFonts.jetbrainsMono();
  static TextStyle get displayStyle => GoogleFonts.orbitron();
  static TextStyle get bodyStyle => GoogleFonts.rajdhani();
}
