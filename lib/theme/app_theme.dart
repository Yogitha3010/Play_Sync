import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0D1B2A);
  static const Color secondary = Color(0xFF00C896);
  static const Color accent = Color(0xFF4DA8FF);
  static const Color background = Color(0xFFF3F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color mutedText = Color(0xFF6B7A90);
  static const Color border = Color(0xFFD9E3EE);

  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Segoe UI',
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: secondary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      surface: surface,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: primary,
      titleTextStyle: TextStyle(
        color: primary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: secondary, width: 1.4),
      ),
      prefixIconColor: primary,
      suffixIconColor: mutedText,
      labelStyle: const TextStyle(color: mutedText),
      hintStyle: const TextStyle(color: mutedText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: primary.withValues(alpha: 0.55),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        backgroundColor: surface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        side: const BorderSide(color: border),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: primary,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: secondary.withValues(alpha: 0.12),
      selectedColor: secondary.withValues(alpha: 0.22),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: mutedText,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
    ),
  );

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, Color(0xFF16314B), secondary],
        stops: [0, 0.55, 1],
      );

  static LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary,
          const Color(0xFF17395B),
          secondary.withValues(alpha: 0.9),
        ],
      );

  static BoxDecoration pageDecoration() {
    return BoxDecoration(
      color: background,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFEAF5F6),
          background,
          const Color(0xFFF8FBFF),
        ],
      ),
    );
  }

  static BoxDecoration surfaceCardDecoration({bool elevated = true}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: border),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: primary.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration tintedCardDecoration(Color tone) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tone.withValues(alpha: 0.16),
          Colors.white,
        ],
      ),
      border: Border.all(color: tone.withValues(alpha: 0.18)),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
