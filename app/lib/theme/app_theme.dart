import 'package:flutter/material.dart';

/// Locked live-demo tokens. mintzer.in website purple is not used here.
class MintzerColors {
  static const primary = Color(0xFF7B61FF);
  static const primaryDark = Color(0xFFB39DFF);
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const earnGreen = Color(0xFF188038);
  static const earnFill = Color(0xFFE6F4EA);
  static const subtitleLilac = Color(0xFFDDD4FF);
  static const spendFill = Color(0xFFEDE7FF);
  static const spendBorder = Color(0xFFDDD4FF);
  static const ink = Color(0xFF202124);
  static const muted = Color(0xFF5F6368);
  static const line = Color(0xFFE8EAED);
  static const gstFill = Color(0xFFE0F2F1);
  static const gstText = Color(0xFF00796B);
  static const gstBorder = Color(0xFF80CBC4);
  static const hotFill = Color(0xFFFCE8E6);
  static const hotText = Color(0xFFD93025);
  /// On-photo urgency (text only)
  static const urgencyHot = Color(0xFFFF8A80);
  static const urgencySlots = Color(0xFFFFD54F);
  static const urgencyTrending = Color(0xFFE8DEF8);
  static const wa = Color(0xFF25D366);
  static const fabPurple = Color(0xFF5B4BDB);
}

class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: MintzerColors.primary,
      onPrimary: Colors.white,
      secondary: MintzerColors.primary,
      onSecondary: Colors.white,
      surface: MintzerColors.surface,
      onSurface: MintzerColors.ink,
      error: MintzerColors.hotText,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MintzerColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: MintzerColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MintzerColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MintzerColors.ink,
          minimumSize: const Size(0, 44),
          shape: const StadiumBorder(),
          side: const BorderSide(color: MintzerColors.line),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: MintzerColors.spendFill,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: MintzerColors.primaryDark,
      onPrimary: Color(0xFF202124),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE8EAED),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Color(0xFFE8EAED),
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MintzerColors.primaryDark,
          foregroundColor: const Color(0xFF202124),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
