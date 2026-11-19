import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'mascot_widget.dart';
import 'primary_button.dart';

/// Unified loading / empty / error / offline view with the Alkan mascot.
///
/// Two layouts:
///
///   Default (screen-level) — vertical, centered. A soft radial halo
///   in the state's accent color sits behind the mascot, then the
///   title, message, and optional action button stack below. Use this
///   when a whole screen has no content to show.
///
///   Compact (inline) — horizontal. A small tinted circle with the
///   mascot on the left, title + optional message on the right, and
///   the optional action as a text button. Use this inside a list or
///   a card where a full-screen state would feel too heavy.
///
/// Accent color is derived from the pose so each state reads as its
/// own mood without the caller having to think about it:
///
///   error / anomaly                  → error (red)
///   offline / warning                → warning (amber)
///   empty income / celebrate         → success (green)
///   everything else (empty, loading,
///   peek, welcome, AI states, etc.)  → primary (brand)
///
/// Pass [accent] to override — useful if a specific screen wants a
/// state to carry a different emphasis.
class StateView extends StatelessWidget {
  final MascotPose pose;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final MascotMotion motion;
  final bool compact;

  /// Optional accent override. When null, the accent is derived from
  /// [pose] — see the class docs for the mapping.
  final Color? accent;

  const StateView({
    super.key,
    required this.pose,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.motion = MascotMotion.float,
    this.compact = false,
    this.accent,
  });

  // ─────────────────────────────────────────────────────────────
  // Factories
  // ─────────────────────────────────────────────────────────────

  factory StateView.loading({String title = 'Loading…'}) => StateView(
        pose: MascotPose.loading,
        title: title,
        motion: MascotMotion.breathe,
      );

  factory StateView.emptyExpenses({VoidCallback? onAdd}) => StateView(
        pose: MascotPose.empty,
        title: 'No expenses yet',
        message: 'Add your first expense to start tracking your money.',
        actionLabel: onAdd == null ? null : 'Add expense',
        onAction: onAdd,
      );

  factory StateView.emptyIncome({VoidCallback? onAdd}) => StateView(
        pose: MascotPose.emptyIncome,
        title: 'No income yet',
        message: 'Record your allowance, salary, or any money coming in.',
        actionLabel: onAdd == null ? null : 'Add income',
        onAction: onAdd,
      );

  factory StateView.error({String? message, VoidCallback? onRetry}) =>
      StateView(
        pose: MascotPose.error,
        title: 'Something went wrong',
        message: message ?? 'Please try again in a moment.',
        actionLabel: onRetry == null ? null : 'Try again',
        onAction: onRetry,
        motion: MascotMotion.shake,
      );

  factory StateView.offline({VoidCallback? onRetry}) => StateView(
        pose: MascotPose.offline,
        title: "You're offline",
        message: 'Changes will sync automatically when you reconnect.',
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
        motion: MascotMotion.pulse,
      );

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = accent ?? _defaultAccent(scheme);

    return compact
        ? _buildCompact(context, scheme, accentColor)
        : _buildFull(context, scheme, accentColor);
  }

  Color _defaultAccent(ColorScheme scheme) {
    switch (pose) {
      case MascotPose.error:
      case MascotPose.anomaly:
        return scheme.error;
      case MascotPose.offline:
      case MascotPose.warning:
        return AppColors.warning;
      case MascotPose.emptyIncome:
      case MascotPose.celebrate:
        return AppColors.success;
      case MascotPose.welcome:
      case MascotPose.peek:
      case MascotPose.loading:
      case MascotPose.goodbye:
      case MascotPose.empty:
      case MascotPose.aiAnswering:
      case MascotPose.aiThinking:
      case MascotPose.aiListening:
        return scheme.primary;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Full (screen-level) layout
  // ─────────────────────────────────────────────────────────────

  Widget _buildFull(BuildContext context, ColorScheme scheme, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: isDark ? 0.18 : 0.12),
                          accent.withValues(alpha: 0.0),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  MascotView(
                    pose: pose,
                    size: 140,
                    motion: motion,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.h3,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.62),
                    height: 1.5,
                  ),
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Compact (inline) layout
  // ─────────────────────────────────────────────────────────────

  Widget _buildCompact(
    BuildContext context,
    ColorScheme scheme,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: MascotView(pose: pose, size: 52, motion: motion),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium,
                ),
                if (message != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    message!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: AppTypography.caption.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}