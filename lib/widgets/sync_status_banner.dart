import 'dart:async';

import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/ios_kit.dart';

class SyncStatusBanner extends StatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner>
    with SingleTickerProviderStateMixin {
  bool _online = true;
  int _pending = 0;
  SyncStatus _status = SyncStatus.idle;

  StreamSubscription? _connSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _pendingSub;

  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ConnectivityService.isOnline().then((v) {
        if (mounted) setState(() => _online = v);
      }).catchError((_) {});
      SyncService.refreshPendingCount().catchError((_) {});
    });

    _connSub = ConnectivityService.onChange.listen((online) {
      if (!mounted) return;
      setState(() => _online = online);
      if (online) unawaited(SyncService.syncAll());
    });
    _statusSub = SyncService.onStatus.listen((s) {
      if (!mounted) return;
      setState(() => _status = s);
      _syncSpinState();
    });
    _pendingSub = SyncService.onPendingChange.listen((n) {
      if (mounted) setState(() => _pending = n);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSpinState();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _statusSub?.cancel();
    _pendingSub?.cancel();
    _spin.dispose();
    super.dispose();
  }

  void _syncSpinState() {
    final reduce =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldSpin = _status == SyncStatus.syncing && !reduce;

    if (shouldSpin && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!shouldSpin && _spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hidden = _online &&
        _status != SyncStatus.syncing &&
        _status != SyncStatus.error &&
        _pending == 0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: hidden
          ? const SizedBox(width: double.infinity, height: 0)
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Center(child: _pill(context)),
            ),
    );
  }

  Widget _pill(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color accent;
    late final IconData icon;
    late final String label;
    late final bool tappable;

    if (!_online) {
      accent = AppColors.warning;
      icon = Icons.cloud_off_rounded;
      label = _pending > 0
          ? 'OFFLINE · $_pending PENDING'
          : 'OFFLINE';
      tappable = false;
    } else if (_status == SyncStatus.syncing) {
      accent = scheme.primary;
      icon = Icons.sync_rounded;
      label = 'SYNCING';
      tappable = false;
    } else if (_status == SyncStatus.error) {
      accent = AppColors.error;
      icon = Icons.error_outline_rounded;
      label = 'SYNC FAILED · RETRY';
      tappable = true;
    } else {
      accent = scheme.primary;
      icon = Icons.cloud_upload_outlined;
      label = _pending == 1
          ? '1 PENDING · SYNC NOW'
          : '$_pending PENDING · SYNC NOW';
      tappable = true;
    }

    final bg = accent.withValues(alpha: isDark ? 0.16 : 0.12);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: PressableOpacity(
        onTap: tappable ? () => SyncService.syncAll() : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: child,
            ),
            child: _content(icon, label, accent, tappable),
          ),
        ),
      ),
    );
  }

  Widget _content(
    IconData icon,
    String label,
    Color accent,
    bool tappable,
  ) {
    final spinning =
        _status == SyncStatus.syncing && _online;

    Widget iconWidget = Icon(icon, size: 14, color: accent);
    if (spinning) {
      iconWidget = RotationTransition(
        turns: _spin,
        child: iconWidget,
      );
    }

    return Row(
      key: ValueKey('$icon|$label|$tappable'),
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.label.copyWith(
            color: accent,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (tappable) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.north_east_rounded,
            size: 12,
            color: accent.withValues(alpha: 0.7),
          ),
        ],
      ],
    );
  }
}