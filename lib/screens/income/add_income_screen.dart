import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../database/sqlite_database.dart';
import '../../models/income.dart';
import '../../services/sync_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/ios_kit.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class AddIncomeScreen extends StatefulWidget {
  final Income? existing;
  const AddIncomeScreen({super.key, this.existing});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = SQLiteDatabase();
  final _uuid = const Uuid();

  late final TextEditingController _amount;
  late final TextEditingController _description;

  String _source = AppConstants.incomeSources.first;
  DateTime _incomeDate = DateTime.now();
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
    _description = TextEditingController(text: e?.description ?? '');
    if (e != null) {
      _source = AppConstants.incomeSources.contains(e.source)
          ? e.source
          : AppConstants.incomeSources.first;
      _incomeDate = e.incomeDate;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incomeDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _incomeDate = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final amount = double.parse(_amount.text.trim());
      final desc = _description.text.trim();

      if (_isEditing) {
        final updated = Income(
          localId: widget.existing!.localId,
          serverId: widget.existing!.serverId,
          clientUuid: widget.existing!.clientUuid,
          userId: widget.existing!.userId,
          amount: amount,
          source: _source,
          description: desc.isEmpty ? null : desc,
          incomeDate: _incomeDate,
          syncStatus: 'pending',
          createdAt: widget.existing!.createdAt,
          updatedAt: now,
        );
        await _db.updateIncome(updated);
      } else {
        final newIncome = Income(
          clientUuid: _uuid.v4(),
          userId: '',
          amount: amount,
          source: _source,
          description: desc.isEmpty ? null : desc,
          incomeDate: _incomeDate,
          createdAt: now,
          updatedAt: now,
        );
        await _db.insertIncome(newIncome);
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
        'Could not save income. Please try again.',
        error: true,
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (!_isEditing || _busy) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete income?',
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        content: Text(
          'This will remove the income record.',
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 14,
            height: 1.45,
            letterSpacing: -0.1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              'Delete',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    _busy = true;
    try {
      await _db.softDeleteIncome(widget.existing!.localId!);
      try {
        await SyncService.refreshPendingCount();
      } catch (_) {}
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      IosKit.snack(
        context,
        'Could not delete income. Please try again.',
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
                          Text('DETAILS', style: IosKit.kicker(scheme)),
                          const SizedBox(height: AppSpacing.sm),
                          _descriptionField(),
                          const SizedBox(height: AppSpacing.xxl),
                          Text('SOURCE', style: IosKit.kicker(scheme)),
                          const SizedBox(height: AppSpacing.sm),
                          _sourceBlock(),
                          const SizedBox(height: AppSpacing.xxl),
                          Text('DATE', style: IosKit.kicker(scheme)),
                          const SizedBox(height: AppSpacing.sm),
                          _dateRow(),
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
                  _isEditing ? 'EDIT INCOME' : 'NEW INCOME',
                  style: IosKit.kicker(scheme),
                ),
                Text(
                  _isEditing ? 'Update details' : 'Record earnings',
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
        Text('AMOUNT', style: IosKit.kicker(scheme)),
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
                cursorColor: AppColors.success,
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
            color: AppColors.success,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _descriptionField() {
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: _description,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      style: IosKit.inputStyle(scheme),
      decoration: IosKit.inputDecoration(
        scheme: scheme,
        hint: 'What was it for? (optional)',
        icon: Icons.edit_note_rounded,
      ),
    );
  }

  Widget _sourceBlock() {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.incomeSources.map((s) {
        final selected = _source == s;
        return IosKit.chip(
          label: s,
          selected: selected,
          accent: AppColors.success,
          scheme: scheme,
          showCheck: true,
          onTap: _saving ? null : () => setState(() => _source = s),
        );
      }).toList(),
    );
  }

  Widget _dateRow() {
    final scheme = Theme.of(context).colorScheme;
    return PressableOpacity(
      onTap: _saving ? null : _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: scheme.onSurface.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.weekdayLabel(_incomeDate),
                    style: TextStyle(
                      fontFamily: IosKit.systemFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.longDate(_incomeDate),
                    style: TextStyle(
                      fontFamily: IosKit.systemFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
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
          label: _isEditing ? 'Save changes' : 'Add income',
          icon: Icons.check_rounded,
          isLoading: _saving,
          onTap: _save,
          color: AppColors.success,
        ),
      ),
    );
  }
}