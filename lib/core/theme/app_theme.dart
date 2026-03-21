import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  // Paleta clara
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0061A4),
        onPrimary: Colors.white,
        secondary: Color(0xFF535F70),
        onSecondary: Colors.white,
        surface: Color(0xFFFDFBFF),
        onSurface: Color(0xFF1A1C1E),
        error: Color(0xFFBA1A1A),
      ),
      scaffoldBackgroundColor: const Color(0xFFFDFBFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFDFBFF),
        foregroundColor: Color(0xFF1A1C1E),
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFF0F4FA),
        selectedItemColor: Color(0xFF0061A4),
        unselectedItemColor: Color(0xFF535F70),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFDFBFF),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Paleta oscura (inspirada en la imagen)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFA0C9FF), // Azul claro para resaltar en oscuro
        onPrimary: Color(0xFF003258),
        secondary: Color(0xFFBBC7DB),
        onSecondary: Color(0xFF253140),
        surface: Color(0xFF1A1F24), // Superficie como las tarjetas en la imagen
        onSurface: Color(0xFFE2E2E6),
      ),
      scaffoldBackgroundColor: const Color(0xFF111418),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111418),
        foregroundColor: Color(0xFFE2E2E6),
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1F24), // Tarjeta oscura inferior
        selectedItemColor: Color(0xFFA0C9FF),
        unselectedItemColor: Color(0xFF8E9099),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1F24), // Asegura un gris oscuro para tarjetas
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2A2F35), width: 1)),
      ),
    );
  }
}
