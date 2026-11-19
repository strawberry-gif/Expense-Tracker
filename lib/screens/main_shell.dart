import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/ios_kit.dart';
import '../widgets/sync_status_banner.dart';
import 'analytics/analytics_screen.dart';
import 'budget/budget_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'expenses/expense_list_screen.dart';
import 'income/income_screen.dart';

/// MainShell — the tabbed root that hosts the five primary screens.
///
/// Structure:
///   Column
///     ├─ SyncStatusBanner   (collapses to 0 height when idle)
///     └─ IndexedStack       (keeps visited tabs mounted so scroll
///                            position and form state survive tab
///                            switches)
///   bottomNavigationBar: custom _AlkanNavBar
///
/// Lazy loading: only the first tab is built at startup. Other tabs
/// are built the first time the user visits them, then kept alive.
/// This keeps the app's first frame fast even as more tabs are added.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// Tabs that have been visited at least once. Only these are
  /// built; unvisited tabs render as zero-size placeholders.
  final Set<int> _visited = {0};

  static const _destinations = <_NavDestination>[
    _NavDestination(
      label: 'Home',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
    ),
    _NavDestination(
      label: 'Expenses',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    _NavDestination(
      label: 'Budget',
      icon: Icons.savings_outlined,
      selectedIcon: Icons.savings_rounded,
    ),
    _NavDestination(
      label: 'Income',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
    ),
    _NavDestination(
      label: 'Analytics',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Theme(
      data: IosKit.theme(context),
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: Column(
          children: [
            const SizedBox(height: AppSpacing.xs),
            const SyncStatusBanner(),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: List.generate(5, _buildTab),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _AlkanNavBar(
          destinations: _destinations,
          selectedIndex: _index,
          onSelect: _onSelect,
        ),
      ),
    );
  }

  void _onSelect(int i) {
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  Widget _buildTab(int i) {
    if (!_visited.contains(i)) return const SizedBox.shrink();
    switch (i) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ExpenseListScreen();
      case 2:
        return const BudgetScreen();
      case 3:
        return const IncomeScreen();
      case 4:
        return const AnalyticsScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _NavDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class _AlkanNavBar extends StatelessWidget {
  final List<_NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _AlkanNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        boxShadow: AppColors.softShadow(dark: isDark),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          child: Row(
            children: [
              for (int i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final muted = scheme.onSurface.withValues(alpha: 0.55);

    return PressableOpacity(
      onTap: onTap,
      pressedOpacity: 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 22,
                color: selected ? primary : muted,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 10.5,
                letterSpacing: -0.1,
                color: selected ? primary : muted,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}