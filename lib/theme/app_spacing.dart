/// Alkan's spacing system.
///
/// The scale is built on an 8-point grid with a 4-point half-step at
/// the tightest end. Every gap in the app should resolve to one of
/// these values — do not introduce ad-hoc numbers.
///
/// Picking a gap:
///
///   4  (xs)   — half-step. Icon-to-text inside a chip or pill.
///   8  (sm)   — related items in a row; label-to-content gap.
///   12 (md)   — tightly coupled blocks (gaps inside a list row).
///   16 (lg)   — default padding inside a surface or block.
///   20 (xl)   — inner padding for hero blocks; equals screenPadding.
///   24 (xxl)  — between major sections on a screen.
///   32 (xxxl) — top-of-screen breathing room above the first section.
///   48 (huge) — very large vertical gap. Splash, onboarding only.
///
/// Horizontal insets:
///
///   screenPadding (20)      — the default screen inset for all list
///                             and detail screens.
///   screenPaddingLarge (24) — wider inset for auth, onboarding, and
///                             any screen where content is sparse.
///
/// FAB clearance:
///
///   fabClearance (140) — bottom padding a scrolling list needs when
///                        an extended FAB floats above it, so the
///                        last row is never hidden behind the button.
///
/// Consistency note: the scale is intentionally small. If a layout
/// seems to need a value that isn't here, first check whether an
/// existing token would work by adjusting the surrounding padding —
/// nine times out of ten it will.
class AppSpacing {
  AppSpacing._();

  // ─────────────────────────────────────────────────────────────
  // SCALE
  // ─────────────────────────────────────────────────────────────

  /// 4 — half-step. Icon-to-text inside a chip or pill.
  static const double xs = 4;

  /// 8 — related items in a row; label-to-content gap.
  static const double sm = 8;

  /// 12 — tightly coupled blocks (gaps inside a list row).
  static const double md = 12;

  /// 16 — default padding inside a surface or block.
  static const double lg = 16;

  /// 20 — inner padding for hero blocks; equals [screenPadding].
  static const double xl = 20;

  /// 24 — between major sections on a screen.
  static const double xxl = 24;

  /// 32 — top-of-screen breathing room above the first section.
  static const double xxxl = 32;

  /// 48 — very large vertical gap. Splash, onboarding only.
  static const double huge = 48;

  // ─────────────────────────────────────────────────────────────
  // HORIZONTAL INSETS
  // ─────────────────────────────────────────────────────────────

  /// The default horizontal inset for list and detail screens.
  /// Used by every redesigned screen's outer padding.
  static const double screenPadding = 20;

  /// Wider horizontal inset for auth, onboarding, and any screen
  /// where content is intentionally sparse.
  static const double screenPaddingLarge = 24;

  // ─────────────────────────────────────────────────────────────
  // LAYOUT CONSTANTS
  // ─────────────────────────────────────────────────────────────

  /// Bottom padding a scrolling list needs when an extended FAB
  /// floats above it — enough clearance so the last row is never
  /// hidden behind the button. Use as `padding: EdgeInsets.only(
  /// bottom: AppSpacing.fabClearance)` on a list with a FAB.
  static const double fabClearance = 140;

  /// Maximum content width for very wide layouts (tablet / desktop).
  /// Not currently enforced by any screen — reserved for a future
  /// responsive wrapper.
  static const double maxContentWidth = 1200;

  /// Maximum reading width for long-form content.
  /// Not currently enforced by any screen.
  static const double maxReadingWidth = 720;
}