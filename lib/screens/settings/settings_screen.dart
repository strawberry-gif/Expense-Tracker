import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/export_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/ios_kit.dart';
import '../../widgets/mascot_widget.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  bool _loggingOut = false;

  Future<void> _export(
    String label,
    Future<ExportResult> Function() task,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await task();
      if (!mounted) return;

      if (!result.ok) {
        IosKit.snack(
          context,
          'Export failed: ${result.error ?? 'unknown'}',
          error: true,
        );
        return;
      }

      IosKit.snack(context, '$label exported');
      await _showExportComplete(label, result.path ?? '');
    } catch (e) {
      if (!mounted) return;
      IosKit.snack(context, 'Export failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showExportComplete(String label, String path) {
    final scheme = Theme.of(context).colorScheme;

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Export complete',
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kIsWeb ? 'Filename:' : 'Saved to:',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 14,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              path,
              style: TextStyle(
                fontSize: 12,
                fontFamily: IosKit.systemFont,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              kIsWeb
                  ? 'Your browser has started the download. '
                      'Check your downloads folder.'
                  : "You can find this file using your phone's Files app.",
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 12,
                letterSpacing: -0.1,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    if (_loggingOut) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const MascotView(
              pose: MascotPose.goodbye,
              size: 48,
              motion: MascotMotion.none,
            ),
            const SizedBox(width: 10),
            Text(
              'Log out?',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        content: Text(
          'Your local data stays on this device. '
          'You can log back in anytime.',
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 14,
            height: 1.45,
            letterSpacing: -0.1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              'Log out',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _loggingOut = true);

    try {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        IosKit.route(const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      IosKit.snack(
        context,
        'Could not log out. Please try again.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Theme(
        data: IosKit.theme(context),
        child: Stack(
          children: [
            IosKit.ambientBackground(scheme),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _header(scheme),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.xxxl,
                      ),
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        _sectionLabel('REPORTS'),
                        const SizedBox(height: AppSpacing.sm),
                        _group([
                          _tile(
                            icon: Icons.receipt_long_rounded,
                            title: 'Export expenses',
                            subtitle:
                                'Save all your expenses as a CSV file',
                            onTap: () => _export(
                              'Expenses',
                              ExportService.exportExpenses,
                            ),
                          ),
                          _tile(
                            icon: Icons.account_balance_wallet_rounded,
                            title: 'Export income',
                            subtitle:
                                'Save your income records as a CSV file',
                            onTap: () => _export(
                              'Income',
                              ExportService.exportIncome,
                            ),
                          ),
                          _tile(
                            icon: Icons.savings_rounded,
                            title: 'Export budgets',
                            subtitle:
                                'Save your budget setup as a CSV file',
                            onTap: () => _export(
                              'Budgets',
                              ExportService.exportBudgets,
                            ),
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.xxl),
                        _sectionLabel('ACCOUNT'),
                        const SizedBox(height: AppSpacing.sm),
                        _group([
                          _tile(
                            icon: Icons.logout_rounded,
                            title: 'Log out',
                            subtitle:
                                'Your local data stays on this device',
                            onTap: _confirmLogout,
                            color: scheme.error,
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.xxl),
                        _sectionLabel('ABOUT'),
                        const SizedBox(height: AppSpacing.sm),
                        _aboutBlock(scheme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IosIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconSize: 16,
            onTap: _busy || _loggingOut
                ? null
                : () => Navigator.pop(context),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ALKAN', style: IosKit.kicker(scheme)),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: IosKit.systemFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(List<Widget> children) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.08),
            width: 0.5,
          ),
          bottom: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 56 + AppSpacing.md,
                endIndent: AppSpacing.screenPadding,
                color: scheme.onSurface.withValues(alpha: 0.08),
              ),
          ],
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return PressableOpacity(
      onTap: _busy || _loggingOut ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: IosKit.systemFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      color: color ?? scheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: IosKit.systemFont,
                        fontSize: 12,
                        letterSpacing: -0.1,
                        color:
                            scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: scheme.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutBlock(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MascotView(
            pose: MascotPose.peek,
            size: 72,
            motion: MascotMotion.float,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alkan',
                  style: TextStyle(
                    fontFamily: IosKit.systemFont,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Offline / Online Personal Finance App',
                  style: TextStyle(
                    fontFamily: IosKit.systemFont,
                    fontSize: 13,
                    letterSpacing: -0.1,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Cjzzz Project · v1.0.0',
                    style: TextStyle(
                      fontFamily: IosKit.systemFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: Text(text, style: IosKit.kicker(scheme)),
    );
  }
}