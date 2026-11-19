import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../database/sqlite_database.dart';
import '../../models/expense.dart';
import '../../services/sync_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/ios_kit.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/mascot_widget.dart';
import '../../widgets/state_view.dart';
import 'add_expense_screen.dart';
import 'ai_input_screen.dart';
import 'expense_detail_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _db = SQLiteDatabase();
  final _searchController = TextEditingController();

  List<Expense> _expenses = const [];
  bool _loading = true;
  bool _hadError = false;
  String _selectedCategory = 'All';
  String _sortBy = 'date_desc';

  Timer? _searchDebounce;
  int _loadGeneration = 0;

  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _searchDebounceMs = 300;

  bool get _isDateSort => _sortBy == 'date_desc' || _sortBy == 'date_asc';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      _loadExpenses,
    );
  }

  void _reloadNow() {
    _searchDebounce?.cancel();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final gen = ++_loadGeneration;
    if (mounted) {
      setState(() {
        _loading = true;
        _hadError = false;
      });
    }

    try {
      final list = await _db.searchExpenses(
        query: _searchController.text,
        category: _selectedCategory,
        sortBy: _sortBy,
      );
      try {
        await SyncService.refreshPendingCount();
      } catch (_) {}

      if (!mounted || gen != _loadGeneration) return;

      setState(() {
        _expenses = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _loading = false;
        _hadError = true;
      });
    }
  }

  Future<void> _openAddScreen() async {
    final saved = await Navigator.push<bool>(
      context,
      IosKit.route(const AddExpenseScreen()),
    );
    if (saved == true) _loadExpenses();
  }

  Future<void> _openAIInput() async {
    final saved = await Navigator.push<bool>(
      context,
      IosKit.route(const AIInputScreen()),
    );
    if (saved == true) _loadExpenses();
  }

  Future<void> _openDetailScreen(Expense expense) async {
    final changed = await Navigator.push<bool>(
      context,
      IosKit.route(ExpenseDetailScreen(localId: expense.localId!)),
    );
    if (changed == true) _loadExpenses();
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
                    child: _searchBar(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(height: 44, child: _chipsRow()),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(child: _listArea()),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _fabColumn(scheme),
    );
  }

  Widget _header() {
    final scheme = Theme.of(context).colorScheme;
    final count = _expenses.length;
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
              Text('EXPENSES', style: IosKit.kicker(scheme)),
              const SizedBox(height: 2),
              Text(
                'History',
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
        _sortButton(),
      ],
    );
  }

  Widget _sortButton() {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      initialValue: _sortBy,
      tooltip: 'Sort',
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onSelected: (value) {
        setState(() => _sortBy = value);
        _reloadNow();
      },
      itemBuilder: (_) => AppConstants.sortOptions.entries
          .map(
            (e) => PopupMenuItem<String>(
              value: e.key,
              child: Text(
                e.value,
                style: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 14,
                  letterSpacing: -0.1,
                  color: scheme.onSurface,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.onSurface.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Icon(
          Icons.sort_rounded,
          size: 18,
          color: scheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _searchBar() {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _searchController,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: hasText
                  ? scheme.primary.withValues(alpha: 0.4)
                  : scheme.onSurface.withValues(alpha: 0.08),
              width: hasText ? 1.2 : 0.8,
            ),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: TextStyle(
              fontFamily: IosKit.systemFont,
              fontSize: 15,
              letterSpacing: -0.1,
              color: scheme.onSurface,
            ),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search expenses…',
              hintStyle: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 15,
                letterSpacing: -0.1,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
              suffixIcon: hasText
                  ? PressableOpacity(
                      onTap: () {
                        _searchController.clear();
                        _reloadNow();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _chipsRow() {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding - 3,
      ),
      children: [
        _chip('All'),
        ...AppConstants.defaultCategories.map(_chip),
      ],
    );
  }

  Widget _chip(String name) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedCategory == name;
    final color = name == 'All'
        ? scheme.primary
        : AppColors.categoryColor(name, brightness: scheme.brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: IosKit.chip(
        label: name,
        selected: selected,
        accent: color,
        scheme: scheme,
        onTap: () {
          setState(() => _selectedCategory = name);
          _reloadNow();
        },
      ),
    );
  }

  Widget _listArea() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hadError) {
      return StateView.error(
        message: 'Could not load expenses. Please try again.',
        onRetry: _loadExpenses,
      );
    }
    if (_expenses.isEmpty) {
      return _empty();
    }
    return RefreshIndicator(
      onRefresh: _loadExpenses,
      color: Theme.of(context).colorScheme.primary,
      child: _isDateSort ? _groupedList() : _flatList(),
    );
  }

  Widget _groupedList() {
    final groups = _groupByDay(_expenses);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final g = groups[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dayHeader(g.label),
            for (int j = 0; j < g.items.length; j++) ...[
              _expenseRow(g.items[j], showTime: true),
              if (j < g.items.length - 1) _rowDivider(),
            ],
          ],
        );
      },
    );
  }

  Widget _flatList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
      itemCount: _expenses.length,
      itemBuilder: (context, i) {
        final e = _expenses[i];
        return Column(
          children: [
            _expenseRow(e, showTime: false),
            if (i < _expenses.length - 1) _rowDivider(),
          ],
        );
      },
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

  Widget _expenseRow(Expense e, {required bool showTime}) {
    final scheme = Theme.of(context).colorScheme;
    final catColor = AppColors.categoryColor(
      e.category,
      brightness: scheme.brightness,
    );
    final sub = showTime
        ? '${e.category} · ${_subLabel(e.expenseDate)}'
        : '${e.category} · ${Formatters.shortDate(e.expenseDate)}';

    return PressableOpacity(
      onTap: () => _openDetailScreen(e),
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
                color: catColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Text(
                e.category.isEmpty
                    ? '?'
                    : e.category.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: catColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.description,
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
                    sub,
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
              '-${Formatters.money(e.amount)}',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    final hasFilter =
        _searchController.text.isNotEmpty || _selectedCategory != 'All';
    if (hasFilter) {
      return StateView(
        pose: MascotPose.peek,
        title: 'No matches',
        message: 'Try changing the search or filter.',
        motion: MascotMotion.pulse,
      );
    }
    return StateView.emptyExpenses(onAdd: _openAddScreen);
  }

  Widget _fabColumn(ColorScheme scheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _iosSmallFab(
          scheme: scheme,
          icon: Icons.auto_awesome_rounded,
          onTap: _openAIInput,
          tooltip: 'AI input',
        ),
        const SizedBox(height: 12),
        _iosExtendedFab(
          scheme: scheme,
          icon: Icons.add_rounded,
          label: 'Add expense',
          onTap: _openAddScreen,
        ),
      ],
    );
  }

  Widget _iosSmallFab({
    required ColorScheme scheme,
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final fab = PressableOpacity(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: scheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.onSurface.withValues(alpha: 0.08),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: scheme.primary),
      ),
    );
    if (tooltip == null) return fab;
    return Tooltip(message: tooltip, child: fab);
  }

  Widget _iosExtendedFab({
    required ColorScheme scheme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return PressableOpacity(
      onTap: onTap,
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
            Icon(icon, size: 20, color: scheme.onPrimary),
            const SizedBox(width: 8),
            Text(
              label,
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

  List<_DayGroup> _groupByDay(List<Expense> items) {
    final map = <DateTime, List<Expense>>{};
    for (final e in items) {
      final k = DateTime(
        e.expenseDate.year,
        e.expenseDate.month,
        e.expenseDate.day,
      );
      map.putIfAbsent(k, () => []).add(e);
    }
    final keys = map.keys.toList()
      ..sort((a, b) =>
          _sortBy == 'date_asc' ? a.compareTo(b) : b.compareTo(a));
    return keys
        .map((k) => _DayGroup(label: _groupLabel(k), items: map[k]!))
        .toList();
  }

  String _groupLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    if (diff < 7) return _weekdays[d.weekday - 1];
    return Formatters.shortDate(d).toUpperCase();
  }

  String _subLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) {
      final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
      final ampm = d.hour < 12 ? 'AM' : 'PM';
      final min = d.minute.toString().padLeft(2, '0');
      return '$h:$min $ampm';
    }
    if (diff == 1) return 'Yesterday';
    return Formatters.shortDate(d);
  }
}

class _DayGroup {
  final String label;
  final List<Expense> items;
  const _DayGroup({required this.label, required this.items});
}