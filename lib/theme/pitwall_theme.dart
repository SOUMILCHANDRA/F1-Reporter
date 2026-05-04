import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PitwallTheme {
  static const Color background = Color(0xFF0A0A0A);
  static const Color cardBackground = Color(0xFF1C1C1C);
  static const Color cardBorder = Color(0xFF2A2A2A);
  static const Color primaryAccent = Color(0xFFE8002D);
  static const Color secondaryAccent = Color(0xFFFFD700);
  
  static const Color teamRedBull = Color(0xFF3671C6);
  static const Color teamFerrari = Color(0xFFE80020);
  static const Color teamMercedes = Color(0xFF27F4D2);
  static const Color teamMcLaren = Color(0xFFFF8000);
  static const Color teamAstonMartin = Color(0xFF229971);
  static const Color teamAlpine = Color(0xFF0093CC);
  static const Color teamWilliams = Color(0xFF64C4FF);
  static const Color teamRB = Color(0xFF6692FF);
  static const Color teamSauber = Color(0xFF52E252);
  static const Color teamHaas = Color(0xFFB6BABD);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: cardBackground,
        primary: primaryAccent,
        secondary: secondaryAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.orbitron(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.rajdhani(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.rajdhani(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.white70,
        ),
        labelLarge: GoogleFonts.rajdhani(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: primaryAccent,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static TextStyle get monoStyle => GoogleFonts.jetBrainsMono(
        fontWeight: FontWeight.w500,
      );
}
