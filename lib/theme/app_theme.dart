import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme system with tablet-optimized design tokens and a unique
/// "RAPID WRITE" design language – deep cosmic dark with vibrant electric accents.
class AppTheme {
  // ─── RAPID WRITE Brand Palette ───────────────────────────────────────────────
  static const Color primary      = Color(0xFF6C63FF); // Electric Violet
  static const Color primaryLight = Color(0xFFA78BFA); // Soft Lavender
  static const Color primaryDark  = Color(0xFF4C46C8); // Deep Indigo

  static const Color secondary    = Color(0xFF00D4AA); // Bioluminescent Teal
  static const Color accent       = Color(0xFFFF9F43); // Solar Amber
  static const Color accentPink   = Color(0xFFFF6B9D); // Neon Rose
  static const Color success      = Color(0xFF0ED97F); // Phosphorescent Mint
  static const Color warning      = Color(0xFFFFB347); // Warm Marigold
  static const Color error        = Color(0xFFFF5E6C); // Coral Red

  // ─── Cosmic Dark Canvas ──────────────────────────────────────────────────────
  static const Color bgDark       = Color(0xFF080B14); // Abyss Black
  static const Color bgDeep       = Color(0xFF0D1117); // Deep Cosmos
  static const Color surfaceDark  = Color(0xFF111827); // Midnight Card
  static const Color cardDark     = Color(0xFF1A2235); // Dark Sapphire Card
  static const Color cardMid      = Color(0xFF222D45); // Slate-Blue Card
  static const Color borderDark   = Color(0xFF2E3F5C); // Steel Blue Border

  // ─── Digital Paper Colors ────────────────────────────────────────────────────
  static const Color paperIvory       = Color(0xFFFAF9F6);
  static const Color paperWarm        = Color(0xFFFFFBEB);
  static const Color paperRuledLine   = Color(0xFFCBD5E1);
  static const Color paperMarginLine  = Color(0xFFFCA5A5);

  // ─── Inks ────────────────────────────────────────────────────────────────────
  static const Color inkMidnight  = Color(0xFF0F172A);
  static const Color inkRoyalBlue = Color(0xFF1E40AF);
  static const Color inkEmerald   = Color(0xFF065F46);
  static const Color inkCrimson   = Color(0xFF991B1B);

  // ─── Glassmorphism Helpers ───────────────────────────────────────────────────
  static BoxDecoration glassCard({
    Color? borderColor,
    double borderRadius = 20,
    double opacity = 0.08,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withOpacity(0.12),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: (borderColor ?? primary).withOpacity(0.06),
          blurRadius: 30,
          spreadRadius: -5,
        ),
      ],
    );
  }

  static BoxDecoration glowCard({
    Color glowColor = const Color(0xFF6C63FF),
    double borderRadius = 18,
    List<Color>? gradient,
    Color? solidColor,
  }) {
    return BoxDecoration(
      gradient: gradient != null
          ? LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: gradient == null ? (solidColor ?? cardDark) : null,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: glowColor.withOpacity(0.35), width: 1.0),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.2),
          blurRadius: 28,
          spreadRadius: -6,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ─── Light Theme ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        surface: surfaceDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
