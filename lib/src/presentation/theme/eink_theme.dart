import 'package:flutter/material.dart';

class EInkTheme {
  static const Color background = Color(0xFFF3F1E8); // Off-white/paper
  static const Color textPrimary = Color(0xFF222222); // Dark gray, not pure black
  static const Color textSecondary = Color(0xFF555555); // Mid gray
  static const Color surface = Color(0xFFEBE8DC); // Slightly darker for cards
  static const Color divider = Color(0xFFD4D1C6); // Subtle lines

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: textPrimary,
        secondary: textSecondary,
        surface: surface,
        surfaceContainerHighest: divider, // Used by some Material 3 components
        onSurface: textPrimary,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
        titleLarge: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0, // Prevent Material 3 color shift on scroll
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: textPrimary,
        unselectedItemColor: textSecondary,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: divider, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      // E-ink screens hate animations. Reduce them at the theme level if possible.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(), // Softer than zoom
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(), // Safe default for iOS, cupertino needs import
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
