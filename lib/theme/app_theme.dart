import 'package:flutter/material.dart';

class AppTheme {
  // --- Colors ---
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color accentColor = Color(0xFF03DAC5);
  static const Color background = Color(0xFFF5F5F7);
  
  // Sensor Specific Colors
  static const Color tempColor = Color(0xFFFF6B6B);
  static const Color phColor = Color(0xFF4D96FF);
  static const Color gravityColor = Color(0xFF6BCB77);

  // --- Text Styles ---
  static const TextStyle headerStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    letterSpacing: -0.5,
  );

  static const TextStyle subHeaderStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
  );

  static const TextStyle valueStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  // --- Global Theme Data ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      
      // FIX IS HERE: We removed 'const' from CardTheme entirely.
      // Now we can use flexible values like BorderRadius.circular without errors.
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black12, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // This is now allowed
        ),
      ),
    );
  }
}