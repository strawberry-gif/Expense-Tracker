import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../database/sqlite_database.dart';
import '../../models/budget.dart';
import '../../services/sync_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/ios_kit.dart';
import '../../utils/constants.dart';

class AddBudgetScreen extends StatefulWidget {
  final Budget? existing;
  const AddBudgetScreen({super.key, this.existing});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = SQLiteDatabase();
  final _uuid = const Uuid();

  late final TextEditingController _amount;
  late String _categoryChoice;
  bool _saving = false;
  bool _busy = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amount = TextEditingController(
      text: e == null ? '' : e.amount.toStringAsFixed(2),
    );
    _categoryChoice = e?.category ?? AppConstants.overallBudgetLabel;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final amount = double.parse(_amount.text.trim());
      final category = _categoryChoice == AppConstants.overallBudgetLabel
          ? null
          : _categoryChoice;

      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(9999, 12, 31);

      if (_isEditing) {
        final updated = Budget(
          localId: widget.existing!.localId,
          serverId: widget.existing!.serverId,
          clientUuid: widget.existing!.clientUuid,
          userId: widget.existing!.userId,
          category: category,
          amount: amount,
          period: 'monthly',
          startDate: widget.existing!.startDate,
          endDate: widget.existing!.endDate,
          syncStatus: 'pending',
          createdAt: widget.existing!.createdAt,
          updatedAt: now,
        );
        await _db.updateBudget(updated);
      } else {
        final existingBudget = await _db.findBudgetByCategory(category);
        if (existingBudget != null) {
          final updated = Budget(
            localId: existingBudget.localId,
            serverId: existingBudget.serverId,
            clientUuid: existingBudget.clientUuid,
            userId: existingBudget.userId,
            category: category,
            amount: amount,
            period: 'monthly',
            startDate: existingBudget.startDate,
            endDate: existingBudget.endDate,
            syncStatus: 'pending',
            createdAt: existingBudget.createdAt,
            updatedAt: now,
          );
          await _db.updateBudget(updated);
        } else {
          final newBudget = Budget(
            clientUuid: _uuid.v4(),
            userId: '',
            category: category,
            amount: amount,
            period: 'monthly',
            startDate: start,
            endDate: end,
            createdAt: now,
            updatedAt: now,
          );
          await _db.insertBudget(newBudget);
        }
      }

      try {
        await SyncService.refreshPendingCount();
      } catch (_) {}

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      IosKit.snack(
        context,
        'Could not save budget. Please try again.',
        error: true,
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (!_isEditing || _busy) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete budget?'),
        content: const Text(
          'This removes the budget. Existing expenses are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    _busy = true;
    try {
      await _db.softDeleteBudget(widget.existing!.localId!);
      try {
        await SyncService.refreshPendingCount();
      } catch (_) {}
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      IosKit.snack(
        context,
        'Could not delete budget. Please try again.',
        error: true,
      );
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
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _header(scheme),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          AppSpacing.md,
                          AppSpacing.screenPadding,
                          AppSpacing.xxxl,
                        ),
                        children: [
                          _amountHero(),
                          const SizedBox(height: AppSpacing.xxl),
                          Text('CATEGORY', style: IosKit.kicker(scheme)),
                          const SizedBox(height: AppSpacing.sm),
                          _categoryBlock(),
                          const SizedBox(height: AppSpacing.sm),
                          _categoryHint(),
                          const SizedBox(height: AppSpacing.xxxl),
                        ],
                      ),
                    ),
                    _bottomBar(scheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
            icon: Icons.close_rounded,
            onTap: _saving ? null : () => Navigator.pop(context),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'EDIT BUDGET' : 'NEW BUDGET',
                  style: IosKit.kicker(scheme),
                ),
                Text(
                  _isEditing ? 'Update the cap' : 'Set a monthly cap',
                  style: TextStyle(
                    fontFamily: IosKit.systemFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing)
            IosIconButton(
              icon: Icons.delete_outline_rounded,
              onTap: _saving || _busy ? null : _confirmDelete,
              color: scheme.error.withValues(alpha: 0.85),
            ),
        ],
      ),
    );
  }

  Widget _amountHero() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MONTHLY AMOUNT', style: IosKit.kicker(scheme)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppConstants.currencySymbol,
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.8,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: !_isEditing,
                style: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  color: scheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                cursorColor: scheme.primary,
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    fontFamily: IosKit.systemFont,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    color: scheme.onSurface.withValues(alpha: 0.2),
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null) return 'Enter a valid number';
                  if (parsed <= 0) return 'Amount must be greater than zero';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 2,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(
              Icons.autorenew_rounded,
              size: 14,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Resets every month. Existing expenses are not affected.',
                style: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 13,
                  letterSpacing: -0.1,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _categoryBlock() {
    final scheme = Theme.of(context).colorScheme;

    final choices = <String>[
      AppConstants.overallBudgetLabel,
      ...AppConstants.defaultCategories,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: choices.map((c) {
        final selected = _categoryChoice == c;
        final isOverall = c == AppConstants.overallBudgetLabel;
        final color = isOverall
            ? scheme.primary
            : AppColors.categoryColor(c, brightness: scheme.brightness);

        return Opacity(
          opacity: _isEditing && !selected ? 0.55 : 1.0,
          child: IosKit.chip(
            label: c,
            selected: selected,
            accent: color,
            scheme: scheme,
            onTap: _isEditing || _saving
                ? null
                : () => setState(() => _categoryChoice = c),
          ),
        );
      }).toList(),
    );
  }

  Widget _categoryHint() {
    final scheme = Theme.of(context).colorScheme;
    final isOverall =
        _categoryChoice == AppConstants.overallBudgetLabel;
    final text = isOverall
        ? 'Tracks your total spending this month.'
        : 'Tracks spending in the "$_categoryChoice" category only.';

    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: scheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
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

  Widget _bottomBar(ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? AppSpacing.md
            : AppSpacing.lg,
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
          label: _isEditing ? 'Save changes' : 'Set budget',
          icon: Icons.check_rounded,
          isLoading: _saving,
          onTap: _save,
        ),
      ),
    );
  }
}