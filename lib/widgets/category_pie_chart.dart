import 'dart:ui' show FontFeature;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/ios_kit.dart';
import '../utils/formatters.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> data;

  const CategoryPieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final entries = data.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) return _empty(scheme);

    final total = entries.fold<double>(0, (a, e) => a + e.value);
    if (total <= 0) return _empty(scheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ring(entries, total, scheme),
        const SizedBox(height: AppSpacing.lg),
        _legend(entries, total, scheme),
      ],
    );
  }

  Widget _ring(
    List<MapEntry<String, double>> entries,
    double total,
    ColorScheme scheme,
  ) {
    final top = entries.first;
    final topPct = (top.value / total) * 100;

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 52,
              startDegreeOffset: -90,
              sections: entries.map((entry) {
                final pct = (entry.value / total) * 100;
                final color = AppColors.categoryColor(
                  entry.key,
                  brightness: scheme.brightness,
                );
                final onSlice = color.computeLuminance() > 0.55
                    ? Colors.black.withValues(alpha: 0.85)
                    : Colors.white;
                return PieChartSectionData(
                  value: entry.value,
                  color: color,
                  title: pct >= 7 ? '${pct.toStringAsFixed(0)}%' : '',
                  radius: 56,
                  titleStyle: TextStyle(
                    fontFamily: IosKit.systemFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: onSlice,
                  ),
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          ),
          SizedBox(
            width: 88,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    top.key.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: IosKit.systemFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${topPct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: IosKit.systemFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: scheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(
    List<MapEntry<String, double>> entries,
    double total,
    ColorScheme scheme,
  ) {
    return Column(
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          _legendRow(entries[i], total, scheme),
          if (i < entries.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _legendRow(
    MapEntry<String, double> entry,
    double total,
    ColorScheme scheme,
  ) {
    final color = AppColors.categoryColor(
      entry.key,
      brightness: scheme.brightness,
    );
    final pct = total <= 0 ? 0.0 : (entry.value / total) * 100;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            entry.key,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: IosKit.systemFont,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          Formatters.money(entry.value),
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: scheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _empty(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.donut_large_rounded,
                size: 22,
                color: scheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No category data yet',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}