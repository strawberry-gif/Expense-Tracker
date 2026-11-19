import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

/// Alkan's typographic system.
///
/// The hierarchy is deliberately flat — six or seven tokens do most
/// of the work. Prefer picking an existing token over `copyWith`-ing
/// a new variant; if a variant appears in more than two places, it
/// should probably become a token here instead.
///
/// Reading order for a typical screen:
///
///   display           → splash wordmark
///   h1                → screen titles ("History", "Earnings", "Insights")
///   h2                → subscreen titles, dialog titles, task screens
///   h3                → block titles, transaction descriptions (emphasis)
///   body / bodyMedium → descriptions, list titles
///   caption           → metadata, subtitles, secondary information
///   label / kicker    → uppercase section markers and chip labels
///
/// Numeric tokens use tabular figures so digits align in lists and
/// charts. Always pick a numeric token for money and counts — never
/// `body` or `h*`.
class AppTypography {
  AppTypography._();

  // ─────────────────────────────────────────────────────────────
  // DISPLAY & HEADINGS
  // ─────────────────────────────────────────────────────────────

  /// Reserved for the splash wordmark and hero-scale brand moments.
  /// Not for screen titles — use [h1] for that.
  static const TextStyle display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.1,
  );

  /// Screen title. Used on list screens ("History", "Earnings",
  /// "Insights") and as the top-level heading on the dashboard.
  static const TextStyle h1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.2,
  );

  /// Subscreen title, dialog title, or a task-screen heading
  /// ("Record spending", "Update details", "Tell Alkan").
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.25,
  );

  /// Block title, transaction description emphasis, or budget name.
  static const TextStyle h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ─────────────────────────────────────────────────────────────
  // BODY
  // ─────────────────────────────────────────────────────────────

  /// Long-form body text — descriptions, empty-state copy, AI messages.
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Emphasised body — list item titles, dialog body, the primary
  /// sentence inside a block.
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// Metadata: subtitles under list rows, timestamps, secondary text.
  static const TextStyle caption = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // ─────────────────────────────────────────────────────────────
  // LABELS & KICKERS
  // ─────────────────────────────────────────────────────────────

  /// Compact uppercase label. Used for chips, badges, and any label
  /// that sits inline with body text (e.g. the "3 days in" pill).
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    height: 1.3,
  );

  /// Wide-tracked uppercase kicker above a section — "DETAILS",
  /// "LAST 7 DAYS", "ALKAN INSIGHT", "REPORTS". The wider tracking
  /// is what visually distinguishes a kicker from a chip label.
  static const TextStyle kicker = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    height: 1.3,
  );

  /// Tight-tracked uppercase label for use inside the 3-column
  /// quick-stat strips ("TODAY", "AVG / DAY", "TOP CATEGORY").
  /// Slightly narrower tracking than [kicker] so three of them fit
  /// across a narrow phone without ellipsis.
  static const TextStyle microLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    height: 1.3,
  );

  /// Text used inside buttons. Kept separate from [bodyMedium] so
  /// button weight can be tuned independently of body copy.
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  // ─────────────────────────────────────────────────────────────
  // NUMERIC — tabular figures so digits align in lists & charts
  // ─────────────────────────────────────────────────────────────

  /// The single most important number on a screen: "spent this
  /// month" on the dashboard, the amount on an expense detail, the
  /// cap on a budget form. This is the largest text anywhere it
  /// appears; do not override its size unless the screen has no
  /// other hero element.
  static const TextStyle hero = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.6,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Large money values inside a hero block that aren't the hero
  /// itself — e.g. the currency symbol beside [hero], or a secondary
  /// big number on a screen that already has a hero.
  static const TextStyle numericLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Medium-weight money values inside cards, summary rows, or the
  /// small stat pills in a grid.
  static const TextStyle numericMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// List-row money values and inline stat numbers. The workhorse
  /// numeric token — used in every transaction row across the app.
  static const TextStyle numericSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}