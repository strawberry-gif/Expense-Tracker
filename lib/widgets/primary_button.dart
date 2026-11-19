import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Button variants for Alkan.
///
///   [primary]     — filled, brand-colored. The default action on a
///                   screen (Save, Add expense, Continue).
///   [outline]     — bordered, primary-colored. Secondary actions
///                   that are still meaningful (Cancel alongside a
///                   save, "Try again" on a recoverable state).
///   [destructive] — filled, error-colored. Only for confirmations
///                   that remove or overwrite data (Delete).
enum AppButtonVariant { primary, outline, destructive }

/// Alkan's primary action button.
///
/// Wraps [FilledButton] / [OutlinedButton] with a consistent height,
/// radius, typography, and loading treatment so every screen's CTA
/// looks and feels the same.
///
/// Loading behavior: when [isLoading] is true, the button becomes
/// non-interactive, the icon is replaced by a spinner, and the label
/// swaps to [loadingLabel] if provided (otherwise it stays as-is).
/// The button's width does not change during loading — the layout
/// reserves the natural width of the label, so tapping Save doesn't
/// cause the button to jump.
///
/// ```dart
/// PrimaryButton(
///   label: 'Add expense',
///   icon: Icons.check_rounded,
///   isLoading: _saving,
///   onPressed: _save,
/// )
/// ```
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  /// Icon shown before the label. Replaced by a spinner while
  /// [isLoading] is true.
  final IconData? icon;

  /// Icon shown after the label. Useful for directional actions
  /// ("See all ›"). Not shown while [isLoading].
  final IconData? trailingIcon;

  final bool isLoading;

  /// Whether the button stretches to fill its parent's width.
  /// Defaults to true — most CTAs are full-width.
  final bool expanded;

  final AppButtonVariant variant;

  /// Optional label to show while loading. When null, [label] stays
  /// visible during the load. Providing this lets a button read
  /// "Saving…" instead of "Save" without losing the visual width.
  final String? loadingLabel;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expanded = true,
    this.variant = AppButtonVariant.primary,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Resolve the foreground used for the spinner and icon so the
    // loading state stays legible on every variant.
    final Color spinnerColor;
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.destructive:
        spinnerColor = Colors.white;
        break;
      case AppButtonVariant.outline:
        spinnerColor = scheme.primary;
        break;
    }

    final effectiveOnPressed = isLoading ? null : onPressed;

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: effectiveOnPressed,
          style: _filledStyle(scheme, scheme.primary, Colors.white),
          child: _content(context, spinnerColor),
        ),
      AppButtonVariant.destructive => FilledButton(
          onPressed: effectiveOnPressed,
          style: _filledStyle(scheme, scheme.error, Colors.white),
          child: _content(context, spinnerColor),
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: _outlineStyle(scheme),
          child: _content(context, spinnerColor),
        ),
    };

    final sized = expanded
        ? SizedBox(width: double.infinity, height: 52, child: button)
        : SizedBox(height: 52, child: button);

    // Accessibility: announce the button's purpose, its busy state,
    // and merge its children into a single semantics node so screen
    // readers don't read the icon separately from the label.
    return Semantics(
      button: true,
      enabled: !isLoading && onPressed != null,
      label: isLoading ? (loadingLabel ?? label) : label,
      child: ExcludeSemantics(child: sized),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Button content
  // ─────────────────────────────────────────────────────────────

  Widget _content(BuildContext context, Color spinnerColor) {
    final displayLabel =
        isLoading && loadingLabel != null ? loadingLabel! : label;

    final leading = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spinnerColor,
            ),
          )
        : (icon != null ? Icon(icon, size: 20) : null);

    final trailing = (!isLoading && trailingIcon != null)
        ? Icon(trailingIcon, size: 20)
        : null;

    // No icons, no spinner → plain label, centered.
    if (leading == null && trailing == null) {
      return Text(displayLabel);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) leading,
        if (leading != null) const SizedBox(width: 10),
        Flexible(
          child: Text(
            displayLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Styles
  // ─────────────────────────────────────────────────────────────

  ButtonStyle _filledStyle(
    ColorScheme scheme,
    Color background,
    Color foreground,
  ) {
    return FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: background.withValues(alpha: 0.35),
      disabledForegroundColor: foreground.withValues(alpha: 0.7),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      minimumSize: const Size(0, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      textStyle: AppTypography.button,
    );
  }

  ButtonStyle _outlineStyle(ColorScheme scheme) {
    return OutlinedButton.styleFrom(
      foregroundColor: scheme.primary,
      disabledForegroundColor: scheme.primary.withValues(alpha: 0.4),
      side: BorderSide(
        color: scheme.primary.withValues(alpha: 0.5),
        width: 1.2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      minimumSize: const Size(0, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      textStyle: AppTypography.button,
    );
  }
}