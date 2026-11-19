import 'package:flutter/material.dart';

import '../../database/sqlite_database.dart';
import '../../models/budget.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/ios_kit.dart';
import '../../utils/formatters.dart';
import '../../widgets/mascot_widget.dart';
import '../../widgets/state_view.dart';
import 'add_budget_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _db = SQLiteDatabase();
  bool _loading = true;
  bool _hadError = false;
  bool _busy = false;
  List<Budget> _budgets = const [];
  Map<int, double> _spent = const {};

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
      final budgets = await _db.getAllBudgets();
      final spent = <int, double>{};
      for (final b in budgets) {
        if (b.localId == null) continue;
        final value = b.category == null
            ? await _db.getSpendingThisMonth()
            : await _db.getSpendingForCategoryThisMonth(b.category!);
        spent[b.localId!] = value;
      }
      if (!mounted) return;
      setState(() {
        _budgets = budgets;
        _spent = spent;
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

  Future<void> _openAdd() async {
    if (_busy) return;
    _busy = true;
    try {
      final saved = await Navigator.push<bool>(
        context,
        IosKit.route(const AddBudgetScreen()),
      );
      if (saved == true) await _load();
    } finally {
      _busy = false;
    }
  }

  Future<void> _openEdit(Budget budget) async {
    if (_busy) return;
    _busy = true;
    try {
      final saved = await Navigator.push<bool>(
        context,
        IosKit.route(AddBudgetScreen(existing: budget)),
      );
      if (saved == true) await _load();
    } finally {
      _busy = false;
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _hadError
                      ? StateView.error(
                          message: 'Could not load budgets. Please try again.',
                          onRetry: _load,
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.screenPadding,
                                AppSpacing.lg,
                                AppSpacing.screenPadding,
                                AppSpacing.md,
                              ),
                              child: _header(),
                            ),
                            Expanded(
                              child: _budgets.isEmpty
                                  ? _empty()
                                  : _listArea(),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _iosFab(scheme),
    );
  }

  Widget _iosFab(ColorScheme scheme) {
    return PressableOpacity(
      onTap: _openAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 20, color: scheme.onPrimary),
            const SizedBox(width: 8),
            Text(
              'Set budget',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final scheme = Theme.of(context).colorScheme;
    final count = _budgets.length;
    final overCount = _budgets.where((b) {
      final spent = _spent[b.localId] ?? 0;
      return spent > b.amount;
    }).length;

    final String sub;
    if (count == 0) {
      sub = 'No active budgets';
    } else if (overCount == 0) {
      sub = '$count ${count == 1 ? "budget" : "budgets"} · on track';
    } else if (overCount == 1) {
      sub = '$count ${count == 1 ? "budget" : "budgets"} · 1 over limit';
    } else {
      sub = '$count budgets · $overCount over limit';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BUDGETS', style: IosKit.kicker(scheme)),
        const SizedBox(height: 2),
        Text(
          'This month',
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 13,
            letterSpacing: -0.1,
            color: overCount > 0
                ? AppColors.error
                : scheme.onSurface.withValues(alpha: 0.55),
            fontWeight:
                overCount > 0 ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _empty() {
    return StateView(
      pose: MascotPose.empty,
      title: 'No budgets yet',
      message: 'Set a monthly budget to keep your spending in check.',
      actionLabel: 'Set budget',
      onAction: _openAdd,
    );
  }

  Widget _listArea() {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _load,
      color: scheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 140),
        itemCount: _budgets.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 0.5,
          indent: AppSpacing.screenPadding,
          endIndent: AppSpacing.screenPadding,
          color: scheme.onSurface.withValues(alpha: 0.08),
        ),
        itemBuilder: (context, i) => _budgetBlock(_budgets[i]),
      ),
    );
  }

  Widget _budgetBlock(Budget b) {
    final scheme = Theme.of(context).colorScheme;
    final spent = _spent[b.localId] ?? 0;
    final remaining = b.amount - spent;
    final ratio = b.amount <= 0 ? 0.0 : spent / b.amount;
    final percent = (ratio * 100).clamp(0, 999).toStringAsFixed(0);

    Color barColor;
    if (ratio >= 1.0) {
      barColor = AppColors.error;
    } else if (ratio >= 0.8) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.success;
    }

    final isOver = ratio >= 1.0;
    final isNear = ratio >= 0.8 && !isOver;

    return PressableOpacity(
      onTap: () => _openEdit(b),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    b.displayName,
                    style: TextStyle(
                      fontFamily: IosKit.systemFont,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  Formatters.money(b.amount),
                  style: TextStyle(
                    fontFamily: IosKit.systemFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor:
                    scheme.onSurface.withValues(alpha: 0.08),
                color: barColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  'Spent ${Formatters.money(spent)} · $percent%',
                  style: TextStyle(
                    fontFamily: IosKit.systemFont,
                    fontSize: 13,
                    letterSpacing: -0.1,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Text(
                  remaining >= 0
                      ? '${Formatters.money(remaining)} left'
                      : '${Formatters.money(-remaining)} over',
                  style: TextStyle(
                    fontFamily: IosKit.systemFont,
                    fontSize: 13,
                    letterSpacing: -0.1,
                    color: remaining < 0
                        ? AppColors.error
                        : scheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (isNear || isOver) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  MascotView(
                    pose: isOver ? MascotPose.anomaly : MascotPose.warning,
                    size: 36,
                    motion: MascotMotion.pulse,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isOver
                          ? "You're over budget on this one."
                          : "Getting close to the limit.",
                      style: TextStyle(
                        fontFamily: IosKit.systemFont,
                        fontSize: 13,
                        letterSpacing: -0.1,
                        color: isOver ? AppColors.error : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}