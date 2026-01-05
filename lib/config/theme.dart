import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42D4);

  // Secondary Colors
  static const Color secondaryColor = Color(0xFFFF6584);
  static const Color accentColor = Color(0xFF00D9FF);

  // Background Colors
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLight = Color(0xFFB2BEC3);

  // Status Colors
  static const Color successColor = Color(0xFF00B894);
  static const Color warningColor = Color(0xFFFDAA2D);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color infoColor = Color(0xFF0984E3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, Color(0xFFFF8E9E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: backgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    ),
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      labelStyle: const TextStyle(
        color: textSecondary,
        fontFamily: 'Poppins',
      ),
      hintStyle: const TextStyle(
        color: textLight,
        fontFamily: 'Poppins',
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        fontFamily: 'Poppins',
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        fontFamily: 'Poppins',
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        fontFamily: 'Poppins',
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFamily: 'Poppins',
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFamily: 'Poppins',
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFamily: 'Poppins',
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        fontFamily: 'Poppins',
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        fontFamily: 'Poppins',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        fontFamily: 'Poppins',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        fontFamily: 'Poppins',
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: textLight,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withOpacity(0.1),
      labelStyle: const TextStyle(
        color: primaryColor,
        fontFamily: 'Poppins',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
    ),
    fontFamily: 'Poppins',
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Color(0xFF16213E),
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF16213E),
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF16213E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D3748)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D3748)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(
        color: Colors.white70,
        fontFamily: 'Poppins',
      ),
      hintStyle: const TextStyle(
        color: Colors.white38,
        fontFamily: 'Poppins',
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Colors.white70,
        fontFamily: 'Poppins',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Colors.white60,
        fontFamily: 'Poppins',
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF16213E),
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.white38,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    fontFamily: 'Poppins',
  );
}
