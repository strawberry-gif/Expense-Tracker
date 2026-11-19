/// Alkan's corner-radius system.
///
/// Radii carry meaning: tight corners on small elements, generous
/// corners on containers that hold other content. Picking the wrong
/// radius is one of the fastest ways to make a UI feel off, so the
/// values here are deliberately opinionated.
///
/// Picking a radius:
///
///   8  (xs)   — small square chips (20–24 px), tiny icon plaques.
///   10 (sm)   — list-row tiles (40 px), settings tiles (36 px),
///               the pill-adjacent squares used inside a row.
///   14 (md)   — inputs, buttons, snackbars, dialogs. The default
///               "control" radius.
///   18 (lg)   — hero containers, date tiles, AI blocks, bottom
///               sheets, and any large surface holding other content.
///   24 (xl)   — full-screen cards. Reserved; the redesign moved
///               most surfaces to [lg] to reduce visual weight.
///   pill      — chips, progress bars, circular buttons, badges.
///               Also used anywhere a rectangular container would
///               otherwise read as a card.
///
/// Semantic aliases map component names to scale values so that a
/// widget reads as `AppRadius.card` rather than an arbitrary number:
///
///   card   → lg
///   button → md
///   input  → md
///   chip   → pill
///   tile   → sm
///
/// Consistency note: if a component seems to need a radius that
/// isn't here, first check whether it belongs to one of the semantic
/// aliases above. New numeric steps should be rare.
class AppRadius {
  AppRadius._();

  // ─────────────────────────────────────────────────────────────
  // SCALE
  // ─────────────────────────────────────────────────────────────

  /// 8 — small square chips (20–24 px), tiny icon plaques.
  static const double xs = 8;

  /// 10 — list-row tiles (40 px), settings tiles (36 px).
  static const double sm = 10;

  /// 14 — inputs, buttons, snackbars, dialogs. The control radius.
  static const double md = 14;

  /// 18 — hero containers, date tiles, AI blocks, large surfaces.
  static const double lg = 18;

  /// 24 — full-screen cards. Reserved; the redesign favors [lg].
  static const double xl = 24;

  /// Fully rounded. Chips, progress bars, circular buttons, badges.
  static const double pill = 999;

  // ─────────────────────────────────────────────────────────────
  // SEMANTIC ALIASES
  // ─────────────────────────────────────────────────────────────

  /// Corners for a card surface.
  static const double card = lg;

  /// Corners for a primary / outline button.
  static const double button = md;

  /// Corners for a text input.
  static const double input = md;

  /// Corners for a chip, badge, or pill-shaped container.
  static const double chip = pill;

  /// Corners for a list-row tile — the 40 px category square in
  /// transaction rows, or the 36 px icon tile in settings.
  static const double tile = sm;
}