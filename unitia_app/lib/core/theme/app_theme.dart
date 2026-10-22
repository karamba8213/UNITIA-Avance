import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens — Unitia Marketplace
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  // Primary — Naranja vibrante (botones, estados activos, nav activo)
  static const primary    = Color(0xFFFF7A1A);
  static const primaryLight = Color(0xFFFF954D);   // gradiente
  static const primaryBg  = Color(0xFFFFF3EB);     // fondos tintados

  // Brand green — solo para identidad de marca (no UI)
  static const brand      = Color(0xFF2D6A4F);
  static const brandLight = Color(0xFFD1EBDF);

  // Surfaces
  static const background = Color(0xFFF5F5F5);
  static const surface    = Color(0xFFFFFFFF);

  // Text
  static const textPrimary   = Color(0xFF2D2D2D);
  static const textSecondary = Color(0xFF757575);
  static const textMuted     = Color(0xFFBDBDBD);

  // Semantic
  static const success = Color(0xFF4CAF50);
  static const error   = Color(0xFFE53935);
  static const warning = Color(0xFFFFA726);
  static const info    = Color(0xFF1E88E5);

  // Borders
  static const border      = Color(0xFFE0E0E0);
  static const inputBorder = Color(0xFFE0E0E0);

  // Legacy aliases (mantener compatibilidad con pantallas existentes)
  static const primary50  = primaryBg;
  static const primary100 = Color(0xFFFFDFC2);
  static const primary400 = primaryLight;
  static const primary600 = Color(0xFFE05E00);
  static const accent     = primary;
  static const accentBg   = primaryBg;
  static const secondary  = primaryLight;
  static const surfaceAlt = Color(0xFFF5F5F5);
}

// ─────────────────────────────────────────────────────────────────────────────
// Shadows
// ─────────────────────────────────────────────────────────────────────────────
List<BoxShadow> get cardShadow => [
  BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 10,
    spreadRadius: 0,
    offset: const Offset(0, 4),
  ),
];

List<BoxShadow> get floatShadow => [
  BoxShadow(
    color: Colors.black.withOpacity(0.10),
    blurRadius: 20,
    spreadRadius: 0,
    offset: const Offset(0, 8),
  ),
];

List<BoxShadow> get primaryShadow => [
  BoxShadow(
    color: AppColors.primary.withOpacity(0.30),
    blurRadius: 16,
    spreadRadius: 0,
    offset: const Offset(0, 6),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Theme
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get light {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: base,

        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),

        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12),
        ),

        // Inputs: fondo blanco, borde sutil #E0E0E0, padding 16px
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),

        // Botones: 52px altura, radius 16px, naranja
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // Bottom nav
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryBg,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final active = states.contains(WidgetState.selected);
            return GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.primary : AppColors.textSecondary,
              letterSpacing: 0.5,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final active = states.contains(WidgetState.selected);
            return IconThemeData(
              color: active ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            );
          }),
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),

    );
  }
}
