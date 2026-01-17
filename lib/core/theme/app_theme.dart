import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configuration with "Eclipse & Emerald" palette.
class AppTheme {
  AppTheme._();

  // Colors
  static const Color slateDark = Color(0xFF0F172A);
  static const Color slateLight = Color(0xFF1E293B);
  static const Color emeraldDeep = Color(0xFF004D40);
  static const Color emeraldLight = Color(0xFF2DD4BF);
  static const Color offWhite = Color(0xFFF8FAFC);

  // Light Theme
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emeraldDeep,
        primary: emeraldDeep,
        secondary: emeraldLight,
        surface: offWhite,
        brightness: Brightness.light,
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          color: slateDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        color: Colors.white,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emeraldLight,
        primary: emeraldLight,
        secondary: emeraldLight,
        surface: slateDark,
        surfaceContainer: slateLight,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: slateDark,
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        color: slateLight,
      ),
    );
  }
}
