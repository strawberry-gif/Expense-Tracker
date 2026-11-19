import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────────
  // BRAND
  // ─────────────────────────────────────────────────────────────
  // Alkan's identity is a warm royal purple paired with a playful
  // gold. The purple is the primary interactive color; the gold is
  // reserved for the mascot (coins, wordmark accent) and secondary
  // emphasis. Do not introduce a third brand hue.

  static const Color alkanPurple      = Color(0xFF8B5FD9);
  static const Color alkanPurpleDark  = Color(0xFF6E3FB5);
  static const Color alkanPurpleLight = Color(0xFFA78BFA);
  static const Color alkanPurpleSoft  = Color(0xFFE9DEFF);
  static const Color alkanCream       = Color(0xFFFAEFD5);
  static const Color alkanBellyDark   = Color(0xFF1A1F2E);
  static const Color alkanGold        = Color(0xFFF5C842);
  static const Color alkanGoldDark    = Color(0xFFD4A029);

  // ─────────────────────────────────────────────────────────────
  // SEMANTIC
  // ─────────────────────────────────────────────────────────────
  // Fixed meaning across the app. Used for status, feedback, and
  // budget thresholds. Never repurpose these for decoration.

  static const Color success  = Color(0xFF10B981);
  static const Color warning  = Color(0xFFF59E0B);
  static const Color error    = Color(0xFFEF4444);
  static const Color info     = Color(0xFF3B82F6);

  /// Reserved for AI-generated content markers. Renders slightly
  /// cooler than the brand purple so AI accents read as distinct
  /// from interactive brand elements on the same screen.
  static const Color aiAccent = Color(0xFF7C3AED);

  // ─────────────────────────────────────────────────────────────
  // CATEGORY PALETTE
  // ─────────────────────────────────────────────────────────────
  // Eight distinct hues, one per default category. Each one must
  // be distinguishable from every other AND from the semantic
  // colors above. Used for: category chips, row tiles, pie chart
  // slices, and the small accent bars on detail screens.

  static const Color catFood          = Color(0xFFEF4444); // red
  static const Color catTransport     = Color(0xFF3B82F6); // blue
  static const Color catShopping      = Color(0xFFD946EF); // fuchsia
  static const Color catUtilities     = Color(0xFFEAB308); // rich yellow
  static const Color catEntertainment = Color(0xFFEC4899); // pink
  static const Color catHealth        = Color(0xFF10B981); // green
  static const Color catEducation     = Color(0xFF06B6D4); // cyan
  static const Color catOther         = Color(0xFF64748B); // slate

  static const Map<String, Color> categoryColors = {
    'Food': catFood,
    'Transportation': catTransport,
    'Shopping': catShopping,
    'Utilities': catUtilities,
    'Entertainment': catEntertainment,
    'Health': catHealth,
    'Education': catEducation,
    'Other': catOther,
  };

  /// Category color for the current theme.
  ///
  /// On light backgrounds the base hue is used directly. On dark
  /// backgrounds the color is lightened slightly so it stays legible
  /// against `darkBackground` — this is the same technique used by
  /// polished finance apps to keep accent colors readable in dark
  /// mode without inventing a second palette.
  static Color categoryColor(String category, {Brightness? brightness}) {
    final base = categoryColors[category] ?? catOther;
    if (brightness == null || brightness == Brightness.light) return base;

    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0))
        .toColor();
  }

  // ─────────────────────────────────────────────────────────────
  // LIGHT SURFACES
  // ─────────────────────────────────────────────────────────────
  // Softly purple-tinted neutrals. The background is deliberately
  // warmer than pure white so purple accents and gold feel at home.

  static const Color lightBackground     = Color(0xFFFBF8FF);
  static const Color lightSurface        = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt     = Color(0xFFF5F0FF);
  static const Color lightSurfaceMuted   = Color(0xFFEEE9FA);
  static const Color lightBorder         = Color(0xFFEDE9F5);
  static const Color lightTextPrimary    = Color(0xFF1A1F2E);
  static const Color lightTextSecondary  = Color(0xFF6B7280);
  static const Color lightTextTertiary   = Color(0xFF9CA3AF);

  // ─────────────────────────────────────────────────────────────
  // DARK SURFACES
  // ─────────────────────────────────────────────────────────────
  // Not an inversion of light mode. Dark surfaces carry a faint
  // purple warmth, and text uses an off-white with a hint of
  // lavender so it reads as part of the same family.

  static const Color darkBackground      = Color(0xFF15121F);
  static const Color darkSurface         = Color(0xFF221E2E);
  static const Color darkSurfaceAlt      = Color(0xFF2D2838);
  static const Color darkSurfaceMuted    = Color(0xFF35304A);
  static const Color darkBorder          = Color(0xFF3A3446);
  static const Color darkTextPrimary     = Color(0xFFF5F3FF);
  static const Color darkTextSecondary   = Color(0xFFA5A0B5);
  static const Color darkTextTertiary    = Color(0xFF75708A);

  // ─────────────────────────────────────────────────────────────
  // SHADOWS
  // ─────────────────────────────────────────────────────────────

  /// Barely-there shadow for standard surfaces. Almost invisible on
  /// light theme; a soft ambient darkening on dark theme.
  static List<BoxShadow> softShadow({bool dark = false}) => [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.35)
              : const Color(0xFF1A1F2E).withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  /// Elevated shadow for hero / call-to-action surfaces. Carries a
  /// purple tint so shadows feel part of the brand, not a neutral
  /// grey drop.
  static List<BoxShadow> liftedShadow({bool dark = false}) => [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.5)
              : alkanPurple.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}