import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../database/sqlite_database.dart';
import '../../models/income.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/ios_kit.dart';
import '../../utils/formatters.dart';
import '../../widgets/state_view.dart';
import 'add_income_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _db = SQLiteDatabase();
  bool _loading = true;
  bool _hadError = false;
  bool _busy = false;
  List<Income> _items = const [];
  double _thisMonth = 0;

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
      final list = await _db.getAllIncome();
      final total = await _db.getIncomeThisMonth();
      if (!mounted) return;
      setState(() {
        _items = list;
        _thisMonth = total;
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
        IosKit.route(const AddIncomeScreen()),
      );
      if (saved == true) await _load();
    } finally {
      _busy = false;
    }
  }

  Future<void> _openEdit(Income income) async {
    if (_busy) return;
    _busy = true;
    try {
      final saved = await Navigator.push<bool>(
        context,
        IosKit.route(AddIncomeScreen(existing: income)),
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
                          message: 'Could not load income. Please try again.',
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenPadding,
                              ),
                              child: _hero(),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Expanded(child: _listArea()),
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
          color: AppColors.success,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_rounded,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Add income',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final scheme = Theme.of(context).colorScheme;
    final count = _items.length;
    final countText = count == 0
        ? 'No entries'
        : '$count ${count == 1 ? "entry" : "entries"}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('INCOME', style: IosKit.kicker(scheme)),
              const SizedBox(height: 2),
              Text(
                'Earnings',
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
                countText,
                style: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 13,
                  letterSpacing: -0.1,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hero() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INCOME THIS MONTH', style: IosKit.kicker(scheme)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '+ ${Formatters.money(_thisMonth)}',
            style: TextStyle(
              fontFamily: IosKit.systemFont,
              fontSize: 44,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: AppColors.success,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _listArea() {
    if (_items.isEmpty) {
      return StateView.emptyIncome(onAdd: _openAdd);
    }
    final groups = _groupByDay(_items);
    return RefreshIndicator(
      onRefresh: _load,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final g = groups[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dayHeader(g.label),
              for (int j = 0; j < g.items.length; j++) ...[
                _incomeRow(g.items[j]),
                if (j < g.items.length - 1) _rowDivider(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _dayHeader(String label) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: IosKit.systemFont,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: scheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _rowDivider() {
    final scheme = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: AppSpacing.screenPadding + 40 + AppSpacing.md,
      endIndent: AppSpacing.screenPadding,
      color: scheme.onSurface.withValues(alpha: 0.08),
    );
  }

  Widget _incomeRow(Income e) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = e.description?.isNotEmpty == true
        ? '${e.source} · ${Formatters.timeLabel(e.incomeDate)}'
        : Formatters.timeLabel(e.incomeDate);

    return PressableOpacity(
      onTap: () => _openEdit(e),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_downward_rounded,
                size: 18,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.description?.isNotEmpty == true
                        ? e.description!
                        : e.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: IosKit.systemFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: IosKit.systemFont,
                      fontSize: 12,
                      letterSpacing: -0.1,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '+ ${Formatters.money(e.amount)}',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.success,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_DayGroup> _groupByDay(List<Income> items) {
    final map = <DateTime, List<Income>>{};
    for (final e in items) {
      final k = DateTime(
        e.incomeDate.year,
        e.incomeDate.month,
        e.incomeDate.day,
      );
      map.putIfAbsent(k, () => []).add(e);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return keys
        .map((k) => _DayGroup(
              label: Formatters.dayLabel(k),
              items: map[k]!,
            ))
        .toList();
  }
}

class _DayGroup {
  final String label;
  final List<Income> items;
  const _DayGroup({required this.label, required this.items});
}