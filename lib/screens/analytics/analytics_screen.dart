import 'package:flutter/material.dart';

import '../../database/sqlite_database.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/ios_kit.dart';
import '../../utils/formatters.dart';
import '../../widgets/category_pie_chart.dart';
import '../../widgets/mascot_widget.dart';
import '../../widgets/monthly_bar_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _db = SQLiteDatabase();
  bool _loading = true;
  bool _hadError = false;

  double _monthTotal = 0;
  double _monthIncome = 0;
  double _avgDaily = 0;
  int _txCount = 0;
  Map<String, double> _categoryTotals = const {};
  List<MapEntry<DateTime, double>> _last6Months = const [];
  String? _topCategory;
  double _topCategoryAmount = 0;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

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

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final daysElapsed = now.day;

    try {
      final results = await Future.wait([
        _db.getSpendingThisMonth(),
        _db.getCategoryTotalsBetween(monthStart, monthEnd),
        _db.getExpenseCountBetween(monthStart, monthEnd),
        _db.getLastNMonthTotals(monthsBack: 6),
        _db.getIncomeThisMonth(),
      ]);

      final monthTotal = results[0] as double;
      final categoryTotals = results[1] as Map<String, double>;
      final txCount = results[2] as int;
      final last6 = results[3] as List<MapEntry<DateTime, double>>;
      final income = results[4] as double;

      String? topCat;
      double topAmt = 0;
      for (final e in categoryTotals.entries) {
        if (e.value > topAmt) {
          topAmt = e.value;
          topCat = e.key;
        }
      }

      if (!mounted) return;
      setState(() {
        _monthTotal = monthTotal;
        _monthIncome = income;
        _avgDaily = daysElapsed == 0 ? 0 : monthTotal / daysElapsed;
        _txCount = txCount;
        _categoryTotals = categoryTotals;
        _last6Months = last6;
        _topCategory = topCat;
        _topCategoryAmount = topAmt;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Theme(
        data: IosKit.theme(context),
        child: Stack(
          children: [
            IosKit.ambientBackground(Theme.of(context).colorScheme),
            SafeArea(
              bottom: false,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _hadError
                      ? _errorView()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: Theme.of(context).colorScheme.primary,
                          child: ListView(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xxxl,
                            ),
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
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screenPadding,
                                ),
                                child: _quickStrip(),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              if (_monthIncome > 0 || _monthTotal > 0) ...[
                                _sectionLabel('INCOME VS EXPENSES'),
                                const SizedBox(height: AppSpacing.md),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.screenPadding,
                                  ),
                                  child: _incomeVsExpense(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                              ],
                              _sectionLabel('BY CATEGORY'),
                              const SizedBox(height: AppSpacing.md),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screenPadding,
                                ),
                                child: CategoryPieChart(data: _categoryTotals),
                              ),
                              if (_last6Months.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xxl),
                                _sectionLabel('LAST 6 MONTHS'),
                                const SizedBox(height: AppSpacing.md),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.screenPadding + 4,
                                    0,
                                    AppSpacing.screenPadding - 4,
                                    0,
                                  ),
                                  child: MonthlyBarChart(data: _last6Months),
                                ),
                              ],
                              if (_last6Months.length >= 2) ...[
                                const SizedBox(height: AppSpacing.xxl),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.screenPadding,
                                  ),
                                  child: _comparisonBlock(),
                                ),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotView(
              pose: MascotPose.error,
              size: 120,
              motion: MascotMotion.shake,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Could not load analytics',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please try again.',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 14,
                letterSpacing: -0.1,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            IosPrimaryButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onTap: _load,
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monthName = _monthNames[now.month - 1];
    final caption = _txCount == 0
        ? '$monthName · no expenses yet'
        : '$monthName · $_txCount '
            '${_txCount == 1 ? "transaction" : "transactions"}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ANALYTICS', style: IosKit.kicker(scheme)),
              const SizedBox(height: 2),
              Text(
                'Insights',
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
                caption,
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
        const SizedBox(width: AppSpacing.sm),
        IosIconButton(icon: Icons.refresh_rounded, onTap: _load),
      ],
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
            Formatters.money(_monthTotal),
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
      ],
    );
  }

  Widget _quickStrip() {
    final scheme = Theme.of(context).colorScheme;
    final topColor = _topCategory == null
        ? scheme.onSurface
        : AppColors.categoryColor(
            _topCategory!,
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
              label: 'AVG / DAY',
              value: Formatters.money(_avgDaily),
            ),
          ),
          _statDivider(),
          Expanded(
            child: _inlineStat(
              label: 'TRANSACTIONS',
              value: _txCount.toString(),
            ),
          ),
          _statDivider(),
          Expanded(
            child: _inlineStat(
              label: 'TOP CATEGORY',
              value: _topCategory ?? '—',
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

  Widget _incomeVsExpense() {
    final scheme = Theme.of(context).colorScheme;
    final total = _monthIncome + _monthTotal;
    final incomeRatio = total == 0 ? 0.0 : _monthIncome / total;
    final expenseRatio = total == 0 ? 0.0 : _monthTotal / total;
    final net = _monthIncome - _monthTotal;
    final netPositive = net >= 0;
    final netColor = netPositive ? AppColors.success : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                if (_monthIncome > 0)
                  Expanded(
                    flex: (incomeRatio * 1000).round().clamp(1, 999),
                    child: Container(color: AppColors.success),
                  ),
                if (_monthTotal > 0)
                  Expanded(
                    flex: (expenseRatio * 1000).round().clamp(1, 999),
                    child: Container(color: scheme.primary),
                  ),
                if (_monthIncome == 0 && _monthTotal == 0)
                  Expanded(
                    child: Container(
                      color: scheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _vsStat(
                label: 'INCOME',
                value: Formatters.money(_monthIncome),
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _vsStat(
                label: 'EXPENSES',
                value: Formatters.money(_monthTotal),
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _vsStat(
                label: 'NET',
                value: netPositive
                    ? '+ ${Formatters.money(net)}'
                    : '- ${Formatters.money(-net)}',
                color: netColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _vsStat({
    required String label,
    required String value,
    required Color color,
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
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _comparisonBlock() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final current = _last6Months.last.value;
    final previous = _last6Months[_last6Months.length - 2].value;
    if (previous == 0 && current == 0) return const SizedBox.shrink();

    late Color accent;
    late String title;
    late String message;
    late MascotPose pose;

    if (previous == 0) {
      accent = scheme.primary;
      title = 'First month';
      message = 'This is your first month with tracked expenses.';
      pose = MascotPose.welcome;
    } else {
      final diff = ((current - previous) / previous) * 100;
      final abs = diff.abs().toStringAsFixed(0);
      if (diff > 5) {
        accent = AppColors.error;
        title = 'Spent more';
        message = 'You spent $abs% more this month than last month.';
        pose = MascotPose.warning;
      } else if (diff < -5) {
        accent = AppColors.success;
        title = 'Spent less';
        message = 'You spent $abs% less this month. Nice work.';
        pose = MascotPose.celebrate;
      } else {
        accent = AppColors.warning;
        title = 'About the same';
        message = 'Spending is about the same as last month.';
        pose = MascotPose.aiListening;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MascotView(pose: pose, size: 56, motion: MascotMotion.float),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MONTH OVER MONTH',
                  style: IosKit.kicker(scheme, color: accent),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: IosKit.systemFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: IosKit.systemFont,
                    fontSize: 14,
                    height: 1.45,
                    letterSpacing: -0.1,
                    color: scheme.onSurface.withValues(alpha: 0.78),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Text(text, style: IosKit.kicker(scheme)),
    );
  }
}