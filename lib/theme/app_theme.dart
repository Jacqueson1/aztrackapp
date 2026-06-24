import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // CMYK Pastel Colors
  static const Color cyan = Color(0xFF00BFFF);
  static const Color magenta = Color(0xFFFF66CC);
  static const Color yellow = Color(0xFFFFE066);
  static const Color keyBlack = Color(0xFF2D2D2D);
  static const Color background = Color(0xFFF9F9FA);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: cyan,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: cyan,
        secondary: magenta,
        tertiary: yellow,
        background: background,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: keyBlack,
      ),
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: keyBlack,
        displayColor: keyBlack,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: keyBlack),
        titleTextStyle: GoogleFonts.mPlusRounded1c(
          color: keyBlack,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyan,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
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
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: magenta, width: 2),
        ),
        hintStyle: GoogleFonts.nunito(color: Colors.grey.shade500),
      ),
    );
  }
}
