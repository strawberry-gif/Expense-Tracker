import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/ios_kit.dart';

class TrendBarChart extends StatelessWidget {
  final Map<DateTime, double> data;

  const TrendBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxValue = entries
        .map((e) => e.value)
        .fold<double>(0, (a, b) => a > b ? a : b);

    final today = DateTime.now();

    return SizedBox(
      height: 168,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: entries.map((entry) {
              return Expanded(
                child: _column(entry, maxValue, today, scheme, t),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _column(
    MapEntry<DateTime, double> entry,
    double maxValue,
    DateTime today,
    ColorScheme scheme,
    double t,
  ) {
    final value = entry.value;
    final ratio = maxValue == 0 ? 0.0 : value / maxValue;
    final barHeight = (4 + ratio * 92) * t;

    final isToday = _isSameDay(entry.key, today);
    final hasValue = value > 0;

    final Color barColor;
    if (!hasValue) {
      barColor = scheme.outlineVariant.withValues(alpha: 0.5);
    } else if (isToday) {
      barColor = scheme.primary;
    } else {
      barColor = scheme.primary.withValues(alpha: 0.35);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 14,
            child: hasValue
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      _compactNumber(value),
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: IosKit.systemFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _weekday(entry.key),
            style: TextStyle(
              fontFamily: IosKit.systemFont,
              fontSize: 10,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 0.4,
              color: isToday
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${entry.key.day}',
            style: TextStyle(
              fontFamily: IosKit.systemFont,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: scheme.onSurface.withValues(alpha: 0.4),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _weekday(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
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