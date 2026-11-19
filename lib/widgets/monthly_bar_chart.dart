import 'dart:ui' show FontFeature;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/ios_kit.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> data;

  const MonthlyBarChart({super.key, required this.data});

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final maxVal = data
        .map((e) => e.value)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 10.0 : maxVal * 1.25;

    return SizedBox(
      height: 200,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final entry = data[group.x.toInt()];
                    return BarTooltipItem(
                      entry.key.month == DateTime.now().month &&
                              entry.key.year == DateTime.now().year
                          ? '${_monthNames[entry.key.month - 1]} · this month\n'
                              '${_formatAmount(entry.value)}'
                          : '${_monthNames[entry.key.month - 1]} ${entry.key.year}\n'
                              '${_formatAmount(entry.value)}',
                      TextStyle(
                        fontFamily: IosKit.systemFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: scheme.onInverseSurface,
                      ),
                    );
                  },
                ),
              ),
              titlesData: _titlesData(scheme),
              barGroups: _barGroups(scheme, t),
            ),
          );
        },
      ),
    );
  }

  FlTitlesData _titlesData(ColorScheme scheme) {
    final muted = scheme.onSurface.withValues(alpha: 0.5);

    return FlTitlesData(
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 34,
          getTitlesWidget: (value, meta) {
            if (value <= 0 || value == meta.max) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                _compactNumber(value),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= data.length) {
              return const SizedBox.shrink();
            }
            final d = data[i].key;
            final isCurrent = _isCurrentMonth(d);
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _monthNames[d.month - 1],
                style: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 11,
                  letterSpacing: 0.4,
                  color: isCurrent
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.6),
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<BarChartGroupData> _barGroups(ColorScheme scheme, double t) {
    return data.asMap().entries.map((item) {
      final idx = item.key;
      final entry = item.value;
      final isCurrent = _isCurrentMonth(entry.key);

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: entry.value * t,
            color: isCurrent
                ? scheme.primary
                : scheme.primary.withValues(alpha: 0.35),
            width: 22,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();
  }

  bool _isCurrentMonth(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  String _formatAmount(double v) {
    final whole = v == v.roundToDouble();
    final grouped = v.toStringAsFixed(whole ? 0 : 2);
    final parts = grouped.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return parts.length > 1
        ? '₱${buf.toString()}.${parts[1]}'
        : '₱${buf.toString()}';
  }
}

String _compactNumber(double v) {
  final abs = v.abs();
  final sign = v < 0 ? '-' : '';
  if (abs < 1) return '0';
  if (abs >= 1000000) {
    final m = abs / 1000000;
    return '$sign${m >= 10 ? m.toStringAsFixed(0) : m.toStringAsFixed(1)}M';
  }
  if (abs >= 1000) {
    final k = abs / 1000;
    return '$sign${k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}k';
  }
  return '$sign${abs.toStringAsFixed(0)}';
}