import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Alkan's Material 3 theme.
///
/// Two modes:
///   [light] — warm off-white background, deep purple text, soft tints.
///   [dark]  — purple-tinted near-black background, off-white lavender text.
///
/// The theme provides sensible defaults for Material widgets (dialogs,
/// snackbars, inputs, buttons, FABs, popups). Most screens in the redesigned
/// app use their own custom components and reach into `Theme.of(context)
/// .colorScheme` directly — the theme's job is to keep those tokens coherent
/// across both brightnesses, and to style the handful of Material widgets
/// that still appear (dialogs, snackbars, text fields, FABs).
///
/// Every color choice here is derived from [AppColors]. If a color is needed
/// in a new theme section, pull it from [AppColors] rather than hard-coding.
class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────────────────────
  // LIGHT
  // ─────────────────────────────────────────────────────────────

  static ThemeData light() {
    final scheme = _lightScheme();
    return _base(scheme, isDark: false);
  }

  // ─────────────────────────────────────────────────────────────
  // DARK
  // ─────────────────────────────────────────────────────────────

  static ThemeData dark() {
    final scheme = _darkScheme();
    return _base(scheme, isDark: true);
  }

  // ─────────────────────────────────────────────────────────────
  // COLOR SCHEMES
  // ─────────────────────────────────────────────────────────────

  static ColorScheme _lightScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppColors.alkanPurple,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.alkanPurple,
      onPrimary: Colors.white,
      primaryContainer: AppColors.alkanPurpleSoft,
      onPrimaryContainer: AppColors.alkanPurpleDark,

      secondary: AppColors.alkanGold,
      onSecondary: AppColors.alkanBellyDark,
      secondaryContainer: AppColors.alkanCream,
      onSecondaryContainer: AppColors.alkanGoldDark,

      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,

      // M3 surface container tiers — the redesign leans heavily on
      // surfaceContainerHighest for chips, search bars, sort pills, and
      // tile backgrounds, so that tier must resolve to lightSurfaceAlt.
      // The lower tiers fill in the steps M3 widgets (bottom sheets,
      // popup menus, dialogs) expect when they request elevation.
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: AppColors.lightBackground,
      surfaceContainer: AppColors.lightSurface,
      surfaceContainerHigh: const Color(0xFFF0EBFA),
      surfaceContainerHighest: AppColors.lightSurfaceAlt,

      outline: AppColors.lightTextTertiary,
      outlineVariant: AppColors.lightBorder,

      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
    );
  }

  static ColorScheme _darkScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppColors.alkanPurpleLight,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.alkanPurpleLight,
      onPrimary: AppColors.alkanBellyDark,
      primaryContainer: AppColors.darkSurfaceAlt,
      onPrimaryContainer: AppColors.alkanPurpleLight,

      secondary: AppColors.alkanGold,
      onSecondary: AppColors.alkanBellyDark,
      secondaryContainer: const Color(0xFF3D2E10),
      onSecondaryContainer: AppColors.alkanGold,

      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,

      // Dark surface tiers — same idea as light, inverted. The top tier
      // (surfaceContainerHighest) matches darkSurfaceAlt, which every chip
      // and search bar in the redesign reads from.
      surfaceContainerLowest: const Color(0xFF100D19),
      surfaceContainerLow: const Color(0xFF1A1726),
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: const Color(0xFF2A2535),
      surfaceContainerHighest: AppColors.darkSurfaceAlt,

      outline: AppColors.darkTextTertiary,
      outlineVariant: AppColors.darkBorder,

      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BASE THEME
  // ─────────────────────────────────────────────────────────────

  static ThemeData _base(ColorScheme scheme, {required bool isDark}) {
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final onPrimaryFg = isDark ? AppColors.alkanBellyDark : Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      dividerColor: border,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      // ── AppBar ────────────────────────────────────────────────
      // Most screens now use custom in-body headers, but the AppBar
      // theme stays consistent in case any screen still relies on it.
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h2.copyWith(color: textPrimary),
      ),

      // ── Card ──────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Inputs ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: AppTypography.body.copyWith(
          color: textSecondary.withValues(alpha: 0.7),
        ),
        labelStyle: AppTypography.body.copyWith(color: textSecondary),
        floatingLabelStyle: AppTypography.caption.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: AppTypography.caption.copyWith(color: scheme.error),
        border: _inputBorder(border),
        enabledBorder: _inputBorder(border),
        focusedBorder: _inputBorder(scheme.primary, width: 1.6),
        errorBorder: _inputBorder(scheme.error, width: 1.4),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.6),
      ),

      // ── Text selection ────────────────────────────────────────
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.28),
        selectionHandleColor: scheme.primary,
      ),

      // ── Buttons ───────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: onPrimaryFg,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.35),
          disabledForegroundColor:
              onPrimaryFg.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: AppSpacing.lg,
          ),
          side: BorderSide(
            color: scheme.primary.withValues(alpha: 0.5),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: AppTypography.button,
        ),
      ),

      // ── Icon button ───────────────────────────────────────────
      // A quiet press state so custom headers (X, back, sort, refresh)
      // feel consistent across screens.
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(
            textPrimary.withValues(alpha: 0.8),
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return scheme.primary.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return scheme.primary.withValues(alpha: 0.06);
            }
            return null;
          }),
        ),
      ),

      // ── Navigation Bar ────────────────────────────────────────
      // The MainShell now uses a custom nav bar; this theme remains so
      // any screen that still uses Material NavigationBar renders
      // consistently with the rest of the shell.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.label.copyWith(
            fontSize: 11.5,
            color: selected ? scheme.primary : textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.primary : textSecondary,
          );
        }),
      ),

      // ── Chip ──────────────────────────────────────────────────
      // Screens now use custom pills for categories and filters. This
      // theme remains for any Material Chip that survives (rare).
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceAlt
            : AppColors.lightSurfaceMuted,
        selectedColor: scheme.primary,
        side: BorderSide(color: border),
        labelStyle: AppTypography.caption.copyWith(color: textPrimary),
        secondaryLabelStyle: AppTypography.caption.copyWith(
          color: onPrimaryFg,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),

      // ── Divider ───────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: border.withValues(alpha: 0.7),
        thickness: 1,
        space: 1,
      ),

      // ── List tile ─────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: scheme.primary.withValues(alpha: 0.08),
        iconColor: textSecondary,
        textColor: textPrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
      ),

      // ── Popup menu ────────────────────────────────────────────
      // Used by the sort menu on the expense list and any future menus.
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border),
        ),
        textStyle: AppTypography.bodyMedium.copyWith(color: textPrimary),
      ),

      // ── SnackBar ──────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? AppColors.darkSurfaceAlt : AppColors.alkanBellyDark,
        contentTextStyle: AppTypography.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
      ),

      // ── Dialog ────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.h3.copyWith(color: textPrimary),
        contentTextStyle: AppTypography.body.copyWith(color: textSecondary),
      ),

      // ── Bottom sheet ──────────────────────────────────────────
      // Reserved for future use; no current screen opens a bottom sheet,
      // but if one does, the shape and drag handle will match Alkan.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        modalBarrierColor: Colors.black.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: border,
      ),

      // ── Tooltip ───────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceAlt
              : AppColors.alkanBellyDark,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: AppTypography.caption.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),

      // ── Progress ──────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: border,
        circularTrackColor: border,
      ),

      // ── FAB ───────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: onPrimaryFg,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}