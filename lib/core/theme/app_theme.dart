import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================================
// SGEO — Premium Tactical Dark Design System
// ============================================================================
// Paleta: Fondo #0A0E12, superficies #161B22, acento #1A73E8, alerta rojo
// Estilo: Glassmorphism opaco + bordes tácticos (0.5px, blanco al 10%)
// Geometría: Cards 20.0, Botones 12.0
// ============================================================================

class AppTheme {
  // ── Notifier global para cambio de tema reactivo ──
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.dark);

  // ══════════════════════════════════════════════════════════════════════════
  //  PALETA DE COLORES TÁCTICOS (Constantes reutilizables)
  // ══════════════════════════════════════════════════════════════════════════
  
  // ── Fondos ──
  static const Color bgDeep       = Color(0xFF0A0E12);   // Fondo principal profundo
  static const Color bgSurface    = Color(0xFF161B22);   // Superficies / tarjetas
  static const Color bgElevated   = Color(0xFF1C2128);   // Superficies elevadas (dialogs, sheets)

  // ── Acentos ──
  static const Color accentBlue   = Color(0xFF1A73E8);   // Azul eléctrico principal
  static const Color accentBlueLight = Color(0xFF4DA3FF); // Azul para textos sobre oscuro
  static const Color accentBlueMuted = Color(0xFF1A73E8); // Azul para iconos/detalles

  // ── Alertas ──
  static const Color alertRed     = Color(0xFFE53935);   // Rojo de alerta (sólido)
  static const Color alertRedBg   = Color(0x33E53935);   // Rojo semitransparente (fondos de badges/alertas)
  static const Color alertAmber   = Color(0xFFFFB300);   // Ámbar para advertencias
  static const Color successGreen = Color(0xFF43A047);   // Verde confirmación

  // ── Bordes tácticos ──
  static const Color borderTactical   = Color(0x1AFFFFFF); // Blanco al 10%
  static const Color borderSubtle     = Color(0x0DFFFFFF); // Blanco al 5%

  // ── Textos ──
  static const Color textPrimary   = Color(0xFFF0F6FC);  // Texto principal (alto contraste)
  static const Color textSecondary = Color(0xFF8B949E);   // Texto secundario / subtítulos
  static const Color textMuted     = Color(0xFF484F58);   // Texto deshabilitado / hints

  // ── Gradiente radial del fondo (para SafetyLayout) ──
  static const Color bgGlowCenter = Color(0xFF0D1B2A);   // Centro del glow sutil
  static const Color bgGlowEdge   = Color(0xFF0A0E12);   // Borde que se desvanece al bgDeep

  // ══════════════════════════════════════════════════════════════════════════
  //  TEMA CLARO (Light Mode)
  // ══════════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
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
        systemOverlayStyle: SystemUiOverlayStyle.dark,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F4FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0061A4), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF535F70)),
        prefixIconColor: const Color(0xFF535F70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0061A4),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TEMA OSCURO — PREMIUM TACTICAL DARK
  // ══════════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),

      // ── Color Scheme ──
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF0D47A1),
        onPrimaryContainer: accentBlueLight,
        secondary: accentBlueLight,
        onSecondary: Color(0xFF0A0E12),
        surface: bgSurface,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        error: alertRed,
        onError: Colors.white,
        outline: borderTactical,
        outlineVariant: borderSubtle,
      ),

      // ── Scaffold ──
      scaffoldBackgroundColor: bgDeep,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: bgDeep,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.3,
        ),
      ),

      // ── Bottom Navigation ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgSurface,
        selectedItemColor: accentBlue,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      // ── Card (Glassmorphism táctico) ──
      cardTheme: CardThemeData(
        color: bgSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderTactical, width: 0.5),
        ),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: bgElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderTactical, width: 0.5),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),

      // ── InputDecoration (formularios modernos) ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1117),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderTactical, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderTactical, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: alertRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: alertRed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        floatingLabelStyle: const TextStyle(color: accentBlueLight),
      ),

      // ── ElevatedButton (con gradiente táctico implícito) ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── OutlinedButton ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentBlueLight,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: borderTactical, width: 0.5),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── TextButton ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentBlueLight,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── FloatingActionButton ──
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 0.5,
        space: 1,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgElevated,
        contentTextStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderTactical, width: 0.5),
        ),
      ),

      // ── BottomSheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: borderTactical, width: 0.5),
        ),
      ),

      // ── ListTile ──
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: textSecondary,
        textColor: textPrimary,
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: bgSurface,
        selectedColor: accentBlue.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: textPrimary),
        side: const BorderSide(color: borderTactical, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentBlue;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentBlue.withValues(alpha: 0.3);
          }
          return bgSurface;
        }),
      ),

      // ── ProgressIndicator ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentBlue,
        linearTrackColor: bgSurface,
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderTactical, width: 0.5),
        ),
        textStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 12),
      ),
    );
  }
}
