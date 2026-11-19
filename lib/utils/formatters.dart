import 'package:intl/intl.dart';

import 'constants.dart';

/// Display formatters for every user-facing value in the app.
///
/// These are stateless, pure functions — no `BuildContext`, no state,
/// no side effects. The underlying [NumberFormat] and [DateFormat]
/// instances are cached at class-load time because construction is
/// expensive (locale lookup + pattern parsing) and every list row and
/// chart label calls into this class during rebuild.
///
/// Locale: formatters use the default locale resolved by the `intl`
/// package. The app currently ships English-only; adding locales
/// later will flow through here automatically as long as
/// `Intl.defaultLocale` is set before the first format call.
///
/// Sections:
///   MONEY      — full, compact, signed variants
///   DATES      — long / short / datetime / time
///   LABELS     — relative, group-header, weekday tile
///   HELPERS    — isToday and the shared day-diff calculator
class Formatters {
  Formatters._();

  // ─────────────────────────────────────────────────────────────
  // MONEY — full precision
  // ─────────────────────────────────────────────────────────────

  /// Symbol + thousands separators + two decimals. `₱1,234.50`.
  ///
  /// The default for every exact amount: transaction rows, detail
  /// screens, budget caps, totals, exports.
  static final NumberFormat _currency = NumberFormat.currency(
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  static String money(double amount) => _currency.format(amount);

  // ─────────────────────────────────────────────────────────────
  // MONEY — compact
  // ─────────────────────────────────────────────────────────────

  /// Compact money with symbol. `₱250`, `₱1.5k`, `₱12k`, `₱1.2M`.
  ///
  /// Thresholds:
  ///   0–999          → `₱250`    (no decimal)
  ///   1,000–9,999    → `₱1.5k`   (one decimal)
  ///   10,000–999,999 → `₱12k`    (no decimal)
  ///   1M–9.99M       → `₱1.5M`   (one decimal)
  ///   10M+           → `₱12M`    (no decimal)
  ///
  /// For inline stats, quick-strip values, and any place where the
  /// full `₱1,234.50` would overflow or dominate the layout.
  static String moneyCompact(double amount) {
    final sign = amount < 0 ? '-' : '';
    return '$sign${AppConstants.currencySymbol}'
        '${_compactMagnitude(amount.abs())}';
  }

  /// Compact money without the symbol. `250`, `1.5k`, `12k`, `1.2M`.
  ///
  /// Same thresholds as [moneyCompact] but omits the currency symbol
  /// — for chart axes and labels where the symbol is already
  /// established by the surrounding context.
  static String moneyCompactBare(double amount) {
    final sign = amount < 0 ? '-' : '';
    return '$sign${_compactMagnitude(amount.abs())}';
  }

  static String _compactMagnitude(double abs) {
    if (abs < 1) return '0';
    if (abs >= 1000000) {
      final m = abs / 1000000;
      return m >= 10
          ? '${m.toStringAsFixed(0)}M'
          : '${m.toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      final k = abs / 1000;
      return k >= 10
          ? '${k.toStringAsFixed(0)}k'
          : '${k.toStringAsFixed(1)}k';
    }
    return abs.toStringAsFixed(0);
  }

  // ─────────────────────────────────────────────────────────────
  // MONEY — signed
  // ─────────────────────────────────────────────────────────────
  // For transaction rows where the sign carries the "money in vs.
  // money out" meaning. Input is treated as a magnitude — the sign
  // is decided by which function you call, not by the value's own
  // sign.

  /// Expense amount with a leading minus. `-₱250.00`.
  static String moneyExpense(double amount) =>
      '-${_currency.format(amount.abs())}';

  /// Income amount with a leading plus. `+₱250.00`.
  static String moneyIncome(double amount) =>
      '+${_currency.format(amount.abs())}';

  // ─────────────────────────────────────────────────────────────
  // DATES — full
  // ─────────────────────────────────────────────────────────────

  /// `September 10, 2026`. Detail screens, headers, any place with
  /// horizontal room for the full month name.
  static final DateFormat _longDate = DateFormat('MMMM d, y');
  static String longDate(DateTime date) => _longDate.format(date);

  /// `Sep 10, 2026`. Default for compact date contexts: list row
  /// subtitles, group headers older than a week.
  static final DateFormat _shortDate = DateFormat('MMM d, y');
  static String shortDate(DateTime date) => _shortDate.format(date);

  /// `Sep 10, 2026 · 3:45 PM`. Date and time on one line. Detail
  /// screens only — the full string is wide.
  static final DateFormat _dateTime = DateFormat('MMM d, y · h:mm a');
  static String dateTime(DateTime date) => _dateTime.format(date);

  // ─────────────────────────────────────────────────────────────
  // DATES — time only
  // ─────────────────────────────────────────────────────────────

  /// `3:45 PM` / `12:30 AM`. 12-hour clock, no leading zero on the
  /// hour.
  static final DateFormat _timeOnly = DateFormat('h:mm a');
  static String timeOnly(DateTime date) => _timeOnly.format(date);

  // ─────────────────────────────────────────────────────────────
  // LABELS — relative
  // ─────────────────────────────────────────────────────────────

  /// `Today` / `Yesterday` / `Tomorrow` / `Sep 10, 2026`.
  ///
  /// For subtitles and secondary contexts where the day matters more
  /// than the exact date. Falls back to [shortDate] beyond a one-day
  /// window. Tomorrow is included because the add screens allow
  /// picking future dates.
  static String relativeDate(DateTime date) {
    final diff = _dayDiff(date);
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    return shortDate(date);
  }

  /// Compact row subtitle that blends time-of-day with relative date.
  ///
  /// Today     → `3:45 PM`
  /// Yesterday → `Yesterday`
  /// Older     → `Sep 10, 2026`
  ///
  /// Used as the right half of a transaction row's subtitle (the left
  /// half is the category). Replaces the per-screen `_subLabel` and
  /// `_timeLabel` helpers that were duplicated in the expense and
  /// income list screens.
  static String timeLabel(DateTime date) {
    final diff = _dayDiff(date);
    if (diff == 0) return timeOnly(date);
    if (diff == 1) return 'Yesterday';
    return shortDate(date);
  }

  /// `TODAY` / `YESTERDAY` / `TOMORROW` / `MON` / `SEP 10, 2026`.
  ///
  /// Group-header label for a date-grouped list. Within the last
  /// week shows the weekday abbreviation; older shows the short
  /// date. Always uppercase — the caller renders it as-is.
  static String dayLabel(DateTime date) {
    final diff = _dayDiff(date);
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    if (diff == -1) return 'TOMORROW';
    if (diff > 1 && diff < 7) return _weekdayShort[date.weekday - 1];
    return shortDate(date).toUpperCase();
  }

  /// `Today` / `Yesterday` / `Tomorrow` / `Monday` / … / `Sunday`.
  ///
  /// Long-form label used by the date tile on the add-expense and
  /// add-income screens. Full day name for anything outside the
  /// three-day window so the user can tell at a glance which day
  /// they're about to record against.
  static String weekdayLabel(DateTime date) {
    final diff = _dayDiff(date);
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    return _weekdayLong[date.weekday - 1];
  }

  /// Full weekday name with no relative special-casing. `Monday` …
  /// `Sunday`. Prefer [weekdayLabel] when the caller wants "Today"
  /// and "Yesterday" folded in.
  static String weekdayName(DateTime date) =>
      _weekdayLong[date.weekday - 1];

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  /// True when [date]'s calendar day matches today's. Time-of-day is
  /// ignored, so a 23:59 timestamp still counts as today.
  static bool isToday(DateTime date) => _dayDiff(date) == 0;

  /// Whole-day difference between [date]'s calendar day and today.
  /// Positive = past, negative = future. Time-of-day is ignored so
  /// a timestamp from 23:59 yesterday still counts as one day back.
  static int dayDiff(DateTime date) => _dayDiff(date);

  static int _dayDiff(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return today.difference(target).inDays;
  }

  // ─────────────────────────────────────────────────────────────
  // Internal
  // ─────────────────────────────────────────────────────────────

  static const List<String> _weekdayShort = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN',
  ];

  static const List<String> _weekdayLong = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
    'Saturday', 'Sunday',
  ];
}