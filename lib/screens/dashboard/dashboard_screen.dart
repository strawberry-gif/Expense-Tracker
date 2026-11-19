import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../database/sqlite_database.dart';
import '../../models/ai_insight.dart';
import '../../models/expense.dart';
import '../../models/user.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/ios_kit.dart';
import '../../utils/formatters.dart';
import '../../widgets/mascot_widget.dart';
import '../../widgets/trend_bar_chart.dart';
import '../expenses/expense_detail_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = SQLiteDatabase();

  bool _loading = true;
  bool _hadError = false;
  String? _userName;

  double _totalThisMonth = 0;
  double _totalToday = 0;
  double _totalIncomeThisMonth = 0;
  double _totalBudget = 0;
  MapEntry<String, double>? _topCategory;
  List<Expense> _recent = const [];
  Map<DateTime, double> _trend = const {};
  AiInsight? _insight;
  bool _refreshingInsight = false;
  DateTime? _lastInsightRefresh;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _hadError = false;
      });
    }

    var failures = 0;
    Future<T?> safe<T>(Future<T> Function() fn) async {
      try {
        return await fn();
      } catch (_) {
        failures++;
        return null;
      }
    }

    final results = await Future.wait<Object?>([
      safe(() => _db.getSpendingThisMonth()),
      safe(() => _db.getSpendingToday()),
      safe(() => _db.getTopCategoryThisMonth()),
      safe(() => _db.getRecentExpenses(limit: 5)),
      safe(() => _db.getDailyTotals(days: 7)),
      safe(() => _db.getTotalBudgetAmount()),
      safe(() => _db.getIncomeThisMonth()),
      safe(() => _db.getLatestAiInsight()),
      safe(() => AuthService.getStoredUser()),
    ]);

    if (!mounted) return;

    final user = results[8];
    setState(() {
      _totalThisMonth = (results[0] as double?) ?? 0;
      _totalToday = (results[1] as double?) ?? 0;
      _topCategory = results[2] as MapEntry<String, double>?;
      _recent = (results[3] as List<Expense>?) ?? const [];
      _trend = (results[4] as Map<DateTime, double>?) ?? const {};
      _totalBudget = (results[5] as double?) ?? 0;
      _totalIncomeThisMonth = (results[6] as double?) ?? 0;
      _insight = results[7] as AiInsight?;
      _userName = user is User ? user.name : null;
      _loading = false;
      _hadError = failures >= 3;
    });

    if (!_hadError) {
      _refreshInsight(silent: true);
    }
  }

  Future<void> _refreshInsight({bool silent = false}) async {
    if (_refreshingInsight) return;

    final now = DateTime.now();
    if (silent &&
        _lastInsightRefresh != null &&
        now.difference(_lastInsightRefresh!) < const Duration(minutes: 5)) {
      return;
    }

    if (mounted) setState(() => _refreshingInsight = true);
    try {
      final user = await AuthService.getStoredUser();
      final userId = user?.id.toString() ?? 'local_user';
      final fresh = await AIService.fetchInsight(userId: userId);
      if (fresh == null) {
        if (!silent && mounted) {
          IosKit.snack(context, 'Could not refresh insight.');
        }
        return;
      }
      await _db.insertAiInsight(fresh);
      await _db.pruneAiInsights(keep: 20);
      _lastInsightRefresh = now;
      if (!mounted) return;
      setState(() => _insight = fresh);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _refreshingInsight = false);
    }
  }

  Future<void> _openExpense(Expense e) async {
    final changed = await Navigator.push<bool>(
      context,
      IosKit.route(ExpenseDetailScreen(localId: e.localId!)),
    );
    if (changed == true) _loadAll();
  }

  Future<void> _openSettings() async {
    await Navigator.push(context, IosKit.route(const SettingsScreen()));
    if (mounted) _loadAll();
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
                  : RefreshIndicator(
                      onRefresh: _loadAll,
                      color: scheme.primary,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          AppSpacing.lg,
                          AppSpacing.screenPadding,
                          AppSpacing.xxxl,
                        ),
                        children: [
                          _header(),
                          if (_hadError) ...[
                            const SizedBox(height: AppSpacing.md),
                            _errorBanner(),
                          ],
                          const SizedBox(height: AppSpacing.xxxl),
                          _hero(),
                          const SizedBox(height: AppSpacing.xxl),
                          _quickStrip(),
                          const SizedBox(height: AppSpacing.xxl),
                          if (_totalBudget > 0) ...[
                            _budgetBlock(),
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                          _aiBlock(),
                          const SizedBox(height: AppSpacing.xxl),
                          _sectionLabel('LAST 7 DAYS'),
                          const SizedBox(height: AppSpacing.md),
                          _trendBlock(),
                          const SizedBox(height: AppSpacing.xxl),
                          _sectionLabel('RECENT'),
                          const SizedBox(height: AppSpacing.sm),
                          _recentBlock(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final scheme = Theme.of(context).colorScheme;
    final firstName = _userName?.split(' ').first ?? 'Welcome back';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting().toUpperCase(), style: IosKit.kicker(scheme)),
              const SizedBox(height: 2),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IosIconButton(icon: Icons.refresh_rounded, onTap: _loadAll),
        const SizedBox(width: AppSpacing.sm),
        IosIconButton(icon: Icons.settings_outlined, onTap: _openSettings),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _errorBanner() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: scheme.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Some data could not be loaded.',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 13,
                letterSpacing: -0.1,
                color: scheme.error,
              ),
            ),
          ),
          GestureDetector(
            onTap: _loadAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: scheme.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SPENT THIS MONTH', style: IosKit.kicker(scheme)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            Formatters.money(_totalThisMonth),
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
        _netLine(),
      ],
    );
  }

  Widget _netLine() {
    final scheme = Theme.of(context).colorScheme;

    if (_totalThisMonth == 0 && _totalIncomeThisMonth == 0) {
      return const SizedBox.shrink();
    }

    if (_totalIncomeThisMonth == 0) {
      return Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 12,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'No income recorded this month',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 13,
                letterSpacing: -0.1,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      );
    }

    final net = _totalIncomeThisMonth - _totalThisMonth;
    final positive = net >= 0;
    final color = positive ? AppColors.success : AppColors.error;

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            positive
                ? '${Formatters.money(net)} left of income'
                : '${Formatters.money(-net)} over income',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: IosKit.systemFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickStrip() {
    final scheme = Theme.of(context).colorScheme;
    final topColor = _topCategory == null
        ? scheme.onSurface
        : AppColors.categoryColor(
            _topCategory!.key,
            brightness: scheme.brightness,
          );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _inlineStat(
              label: 'TODAY',
              value: Formatters.money(_totalToday),
            ),
          ),
          _statDivider(),
          Expanded(
            child: _inlineStat(
              label: 'INCOME · MO',
              value: Formatters.money(_totalIncomeThisMonth),
              valueColor: AppColors.success,
            ),
          ),
          _statDivider(),
          Expanded(
            child: _inlineStat(
              label: 'TOP · MO',
              value: _topCategory?.key ?? '—',
              valueColor: topColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineStat({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: scheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontFamily: IosKit.systemFont,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: valueColor ?? scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 0.5,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: scheme.onSurface.withValues(alpha: 0.08),
    );
  }

  Widget _budgetBlock() {
    final scheme = Theme.of(context).colorScheme;
    final spent = _totalThisMonth;
    final remaining = _totalBudget - spent;
    final ratio = _totalBudget <= 0 ? 0.0 : spent / _totalBudget;
    final percent = (ratio * 100).clamp(0, 999).toStringAsFixed(0);

    Color barColor;
    if (ratio >= 1.0) {
      barColor = AppColors.error;
    } else if (ratio >= 0.8) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.success;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Budget',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: scheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '$percent% used',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 12,
            backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
            color: barColor,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Text(
              remaining >= 0
                  ? '${Formatters.money(remaining)} left'
                  : '${Formatters.money(-remaining)} over',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 13,
                letterSpacing: -0.1,
                color: remaining < 0 ? AppColors.error : scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              'of ${Formatters.money(_totalBudget)}',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 13,
                letterSpacing: -0.1,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _aiBlock() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insight = _insight;
    final type = insight?.type ?? 'info';

    late Color accent;
    switch (type) {
      case 'warning':
        accent = AppColors.error;
        break;
      case 'positive':
        accent = AppColors.success;
        break;
      default:
        accent = scheme.primary;
        break;
    }

    final MascotPose pose;
    final MascotMotion motion;
    if (_refreshingInsight) {
      pose = MascotPose.aiThinking;
      motion = MascotMotion.pulse;
    } else if (insight == null) {
      pose = MascotPose.aiListening;
      motion = MascotMotion.float;
    } else if (type == 'warning') {
      pose = MascotPose.warning;
      motion = MascotMotion.pulse;
    } else if (type == 'positive') {
      pose = MascotPose.celebrate;
      motion = MascotMotion.float;
    } else {
      pose = MascotPose.aiAnswering;
      motion = MascotMotion.float;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('ALKAN INSIGHT', style: IosKit.kicker(scheme, color: accent)),
              const Spacer(),
              if (_refreshingInsight)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.8, color: accent),
                )
              else
                PressableOpacity(
                  onTap: () => _refreshInsight(silent: false),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.refresh_rounded, size: 16, color: accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MascotView(pose: pose, size: 56, motion: motion),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _aiContent(insight, accent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aiContent(AiInsight? insight, Color accent) {
    final scheme = Theme.of(context).colorScheme;

    if (insight == null) {
      return Text(
        'Add a few expenses — Alkan will start analyzing your patterns.',
        style: TextStyle(
          fontFamily: IosKit.systemFont,
          fontSize: 14,
          height: 1.45,
          letterSpacing: -0.1,
          color: scheme.onSurface.withValues(alpha: 0.85),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          insight.title,
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          insight.message,
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 14,
            height: 1.45,
            letterSpacing: -0.1,
            color: scheme.onSurface.withValues(alpha: 0.78),
          ),
        ),
        if (insight.suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ...insight.suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s,
                      style: TextStyle(
                        fontFamily: IosKit.systemFont,
                        fontSize: 13,
                        height: 1.4,
                        letterSpacing: -0.1,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          'Updated ${Formatters.dateTime(insight.generatedAt)}',
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 11,
            letterSpacing: 0.2,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _trendBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TrendBarChart(data: _trend),
    );
  }

  Widget _recentBlock() {
    if (_recent.isEmpty) return _emptyRecent();
    return Column(
      children: [
        for (int i = 0; i < _recent.length; i++) ...[
          _recentRow(_recent[i]),
          if (i < _recent.length - 1) _recentDivider(),
        ],
      ],
    );
  }

  Widget _emptyRecent() {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const MascotView(
          pose: MascotPose.empty,
          size: 64,
          motion: MascotMotion.float,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'No expenses yet. Tap the plus icon in the Expenses tab to add one.',
            style: TextStyle(
              fontFamily: IosKit.systemFont,
              fontSize: 14,
              height: 1.45,
              letterSpacing: -0.1,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _recentRow(Expense e) {
    final scheme = Theme.of(context).colorScheme;
    final catColor = AppColors.categoryColor(
      e.category,
      brightness: scheme.brightness,
    );
    return PressableOpacity(
      onTap: () => _openExpense(e),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                e.category.isEmpty ? '?' : e.category.substring(0, 1).toUpperCase(),
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
                    '${e.category} · ${Formatters.shortDate(e.expenseDate)}',
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
              Formatters.money(e.amount),
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

  Widget _recentDivider() {
    final scheme = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 0.5,
      color: scheme.onSurface.withValues(alpha: 0.08),
    );
  }

  Widget _sectionLabel(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Text(text, style: IosKit.kicker(scheme));
  }
}