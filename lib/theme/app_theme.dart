/// app_theme.dart — Application theme configuration (light and dark).
///
/// Defines consistent styling across the app following iOS-inspired
/// design language. Configures colors, typography, card styles,
/// input decorations, button themes, and navigation bar appearance
/// for both light and dark modes.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ── Brand Colors ──
  static const Color _primaryLight = Color(0xFF0A84FF);
  static const Color _primaryDark = Color(0xFF0A84FF);

  // ── Light Theme ──
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: '.SF Pro Text',
      colorScheme: ColorScheme.light(
        primary: _primaryLight,
        onPrimary: Colors.white,
        surface: const Color(0xFFF2F2F7),
        onSurface: Colors.black,
        surfaceContainerHighest: Colors.white,
        outline: Colors.grey[300]!,
      ),
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0A84FF)),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: _primaryLight.withAlpha(30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: Colors.grey[200]!),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white.withAlpha(240),
        elevation: 0,
        selectedItemColor: _primaryLight,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryLight, width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryLight,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryLight,
          side: BorderSide(color: _primaryLight.withAlpha(80)),
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[200],
        thickness: 0.5,
        indent: 16,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          letterSpacing: -0.4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.grey[800],
      ),
    );
  }

  // ── Dark Theme ──
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: '.SF Pro Text',
      colorScheme: ColorScheme.dark(
        primary: _primaryDark,
        onPrimary: Colors.white,
        surface: const Color(0xFF1C1C1E),
        onSurface: Colors.white,
        surfaceContainerHighest: const Color(0xFF2C2C2E),
        outline: Colors.grey[700]!,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0A84FF)),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2C2C2E),
        selectedColor: _primaryDark.withAlpha(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1C1C1E).withAlpha(240),
        elevation: 0,
        selectedItemColor: _primaryDark,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryDark, width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryDark,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryDark,
          side: BorderSide(color: _primaryDark.withAlpha(80)),
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[800],
        thickness: 0.5,
        indent: 16,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: const Color(0xFF2C2C2E),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.grey[300],
        contentTextStyle: const TextStyle(color: Colors.black),
      ),
    );
  }
}
