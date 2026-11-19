import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../database/sqlite_database.dart';
import '../../models/expense.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/ios_kit.dart';
import '../../utils/formatters.dart';
import '../../widgets/state_view.dart';
import 'add_expense_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final int localId;
  const ExpenseDetailScreen({super.key, required this.localId});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final _db = SQLiteDatabase();

  Expense? _expense;
  bool _loading = true;
  bool _hadError = false;
  bool _changed = false;
  bool _busy = false;
  bool _popInProgress = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _hadError = false;
      });
    }
    try {
      final e = await _db.getExpenseById(widget.localId);
      if (!mounted) return;
      setState(() {
        _expense = e;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hadError = true;
      });
    }
  }

  Future<void> _edit() async {
    if (_busy || _expense == null) return;
    _busy = true;
    try {
      final saved = await Navigator.push<bool>(
        context,
        IosKit.route(AddExpenseScreen(existing: _expense)),
      );
      if (saved == true) {
        _changed = true;
        await _load();
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _confirmDelete() async {
    if (_busy || _expense == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete expense?',
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        content: Text(
          'This will remove the expense from your list. '
          'It will also be removed from the server on next sync.',
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
              'Delete',
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

    _busy = true;
    try {
      await _db.softDeleteExpense(widget.localId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      IosKit.snack(
        context,
        'Could not delete expense. Please try again.',
        error: true,
      );
    } finally {
      _busy = false;
    }
  }

  void _handleBack() {
    if (_popInProgress) return;
    _popInProgress = true;
    Navigator.pop(context, _changed);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: Theme(
          data: IosKit.theme(context),
          child: Stack(
            children: [
              IosKit.ambientBackground(scheme),
              SafeArea(
                bottom: false,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _hadError
                        ? _errorView()
                        : _expense == null
                            ? _notFound()
                            : _body(_expense!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorView() {
    return StateView.error(
      message: 'Could not load this expense.',
      onRetry: _load,
    );
  }

  Widget _notFound() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 44,
              color: scheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Expense not found.',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 14,
                letterSpacing: -0.1,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(Expense e) {
    final scheme = Theme.of(context).colorScheme;
    final catColor = AppColors.categoryColor(
      e.category,
      brightness: scheme.brightness,
    );

    return Column(
      children: [
        _header(scheme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.lg,
              AppSpacing.screenPadding,
              AppSpacing.xxxl,
            ),
            children: [
              _hero(e, catColor, scheme),
              const SizedBox(height: AppSpacing.xxxl),
              Text('DETAILS', style: IosKit.kicker(scheme)),
              const SizedBox(height: AppSpacing.sm),
              _detailsBlock(e, scheme),
              const SizedBox(height: AppSpacing.xxl),
              Text('TIMELINE', style: IosKit.kicker(scheme)),
              const SizedBox(height: AppSpacing.sm),
              _timelineBlock(e, scheme),
            ],
          ),
        ),
        _bottomBar(scheme),
      ],
    );
  }

  Widget _header(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IosIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconSize: 16,
            onTap: _busy ? null : _handleBack,
          ),
          const Spacer(),
          IosIconButton(
            icon: Icons.delete_outline_rounded,
            onTap: _busy ? null : _confirmDelete,
            color: scheme.error.withValues(alpha: 0.85),
          ),
        ],
      ),
    );
  }

  Widget _hero(Expense e, Color catColor, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: catColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                e.category,
                style: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: catColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          e.description,
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.25,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            Formatters.money(e.amount),
            style: TextStyle(
              fontFamily: IosKit.systemFont,
              fontSize: 44,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: catColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          Formatters.longDate(e.expenseDate),
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 13,
            letterSpacing: -0.1,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _detailsBlock(Expense e, ColorScheme scheme) {
    final isSynced = e.syncStatus == 'synced';
    final statusColor = isSynced ? AppColors.success : AppColors.warning;
    final statusLabel = isSynced ? 'Synced' : 'Pending sync';
    final statusIcon = isSynced
        ? Icons.cloud_done_rounded
        : Icons.cloud_upload_outlined;

    return Column(
      children: [
        _detailRow(
          label: 'Payment',
          value: e.paymentMethod ?? '—',
          scheme: scheme,
        ),
        _rowDivider(scheme),
        _detailRow(
          label: 'Merchant',
          value: e.merchant ?? '—',
          scheme: scheme,
        ),
        _rowDivider(scheme),
        _statusRow(
          label: 'Status',
          value: statusLabel,
          icon: statusIcon,
          color: statusColor,
          scheme: scheme,
        ),
      ],
    );
  }

  Widget _timelineBlock(Expense e, ColorScheme scheme) {
    return Column(
      children: [
        _detailRow(
          label: 'Created',
          value: Formatters.dateTime(e.createdAt),
          scheme: scheme,
        ),
        _rowDivider(scheme),
        _detailRow(
          label: 'Updated',
          value: Formatters.dateTime(e.updatedAt),
          scheme: scheme,
        ),
      ],
    );
  }

  Widget _detailRow({
    required String label,
    required String value,
    required ColorScheme scheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required ColorScheme scheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: IosKit.systemFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowDivider(ColorScheme scheme) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: scheme.onSurface.withValues(alpha: 0.08),
    );
  }

  Widget _bottomBar(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: IosPrimaryButton(
          label: 'Edit expense',
          icon: Icons.edit_rounded,
          onTap: _busy ? null : _edit,
        ),
      ),
    );
  }
}