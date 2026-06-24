import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Soft UI Colors (Updated to vibrant blue theme)
  static const Color slateBlue = Color(0xFF2563EB); // Vibrant Primary Blue
  static const Color pastelBlue = Color(0xFFDBEAFE); // Light Blue Backgrounds
  static const Color navy = Color(0xFF1E3A8A); // Deep Blue for Text
  static const Color softGrey = Color(0xFFF8FAFC);
  static const Color offWhite = Color(0xFFFFFFFF);
  static const Color accentGreen = Color(0xFF10B981);

  // Admin Theme Colors
  static const Color adminPrimary = Color(0xFF10B981); // Emerald Green
  static const Color adminText = Color(0xFF111827); // Deep Black/Grey
  static const Color adminBackground = Color(0xFFECFDF5); // Very soft green/white background

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: slateBlue,
      scaffoldBackgroundColor: softGrey,
      colorScheme: const ColorScheme.light(
        primary: slateBlue,
        secondary: navy,
        tertiary: pastelBlue,
        background: softGrey,
        surface: offWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: navy,
      ),
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: navy,
        displayColor: navy,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: slateBlue),
        titleTextStyle: GoogleFonts.mPlusRounded1c(
          color: slateBlue,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: slateBlue,
          foregroundColor: Colors.white,
          elevation: 20,
          shadowColor: Colors.black.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: pastelBlue, width: 2),
        ),
        hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.mPlusRounded1c(
          color: navy,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: GoogleFonts.nunito(
          color: Colors.grey.shade700,
          fontSize: 16,
        ),
      ),
    );
  }
}
