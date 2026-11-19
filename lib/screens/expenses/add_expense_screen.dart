import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../database/sqlite_database.dart';
import '../../models/expense.dart';
import '../../services/ai_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/ios_kit.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/mascot_widget.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existing;
  final ParsedExpense? prefill;

  const AddExpenseScreen({super.key, this.existing, this.prefill});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = SQLiteDatabase();
  final _uuid = const Uuid();

  late final TextEditingController _amount;
  late final TextEditingController _description;
  late final TextEditingController _merchant;

  String _category = AppConstants.defaultCategories.first;
  String _paymentMethod = AppConstants.paymentMethods.first;
  DateTime _expenseDate = DateTime.now();

  bool _saving = false;
  bool _categorizing = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final p = widget.prefill;

    if (e != null) {
      _amount = TextEditingController(text: e.amount.toStringAsFixed(2));
      _description = TextEditingController(text: e.description);
      _merchant = TextEditingController(text: e.merchant ?? '');
      _category = AppConstants.defaultCategories.contains(e.category)
          ? e.category
          : AppConstants.defaultCategories.first;
      _paymentMethod = e.paymentMethod ?? AppConstants.paymentMethods.first;
      _expenseDate = e.expenseDate;
    } else if (p != null) {
      _amount = TextEditingController(
        text: p.amount == null ? '' : p.amount!.toStringAsFixed(2),
      );
      _description = TextEditingController(text: p.description);
      _merchant = TextEditingController(text: p.merchant ?? '');
      _category = AppConstants.defaultCategories.contains(p.category)
          ? p.category
          : AppConstants.defaultCategories.first;
      _paymentMethod = AppConstants.paymentMethods.contains(p.paymentMethod)
          ? p.paymentMethod!
          : AppConstants.paymentMethods.first;
      if (p.expenseDate != null) {
        _expenseDate = DateTime.tryParse(p.expenseDate!) ?? DateTime.now();
      }
    } else {
      _amount = TextEditingController();
      _description = TextEditingController();
      _merchant = TextEditingController();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _merchant.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _suggestCategory() async {
    final desc = _description.text.trim();
    final merchant = _merchant.text.trim();
    if (desc.isEmpty && merchant.isEmpty) {
      IosKit.snack(context, 'Enter a description or merchant first.');
      return;
    }
    setState(() => _categorizing = true);
    try {
      final s = await AIService.categorize(
        text: desc.isEmpty ? merchant : desc,
        merchant: merchant.isEmpty ? null : merchant,
      );
      if (!mounted) return;
      if (!AppConstants.defaultCategories.contains(s.category)) {
        IosKit.snack(
          context,
          'AI suggested "${s.category}" which is not in the list.',
        );
        return;
      }
      setState(() => _category = s.category);
      final source = s.isLocal ? 'Offline guess' : 'AI';
      final msg = s.reason.isEmpty
          ? '$source: ${s.confidence} confidence'
          : '$source (${s.confidence}): ${s.reason}';
      IosKit.snack(context, msg);
    } catch (_) {
      if (!mounted) return;
      IosKit.snack(context, 'Could not suggest a category.', error: true);
    } finally {
      if (mounted) setState(() => _categorizing = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final amount = double.parse(_amount.text.trim());
      final merchantText = _merchant.text.trim();

      if (_isEditing) {
        final updated = Expense(
          localId: widget.existing!.localId,
          serverId: widget.existing!.serverId,
          clientUuid: widget.existing!.clientUuid,
          userId: widget.existing!.userId,
          amount: amount,
          category: _category,
          description: _description.text.trim(),
          merchant: merchantText.isEmpty ? null : merchantText,
          paymentMethod: _paymentMethod,
          expenseDate: _expenseDate,
          syncStatus: 'pending',
          createdAt: widget.existing!.createdAt,
          updatedAt: now,
        );
        await _db.updateExpense(updated);
      } else {
        final newExpense = Expense(
          clientUuid: _uuid.v4(),
          userId: '',
          amount: amount,
          category: _category,
          description: _description.text.trim(),
          merchant: merchantText.isEmpty ? null : merchantText,
          paymentMethod: _paymentMethod,
          expenseDate: _expenseDate,
          createdAt: now,
          updatedAt: now,
        );
        await _db.insertExpense(newExpense);
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
        'Could not save expense. Please try again.',
        error: true,
      );
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
                          _detailsBlock(),
                          const SizedBox(height: AppSpacing.xxl),
                          _categoryHeader(),
                          const SizedBox(height: AppSpacing.sm),
                          _categoryBlock(),
                          const SizedBox(height: AppSpacing.xxl),
                          Text('PAYMENT', style: IosKit.kicker(scheme)),
                          const SizedBox(height: AppSpacing.sm),
                          _paymentBlock(),
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
        AppSpacing.screenPadding,
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
                  _isEditing ? 'EDIT EXPENSE' : 'NEW EXPENSE',
                  style: IosKit.kicker(scheme),
                ),
                Text(
                  _isEditing ? 'Update details' : 'Record spending',
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsed = double.tryParse(value.trim());
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
      ],
    );
  }

  Widget _detailsBlock() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        TextFormField(
          controller: _description,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          style: IosKit.inputStyle(scheme),
          decoration: IosKit.inputDecoration(
            scheme: scheme,
            hint: 'What did you spend on?',
            icon: Icons.edit_note_rounded,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please enter a description'
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _merchant,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          style: IosKit.inputStyle(scheme),
          decoration: IosKit.inputDecoration(
            scheme: scheme,
            hint: 'Merchant (optional)',
            icon: Icons.storefront_outlined,
          ),
        ),
      ],
    );
  }

  Widget _categoryHeader() {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text('CATEGORY', style: IosKit.kicker(scheme)),
        const Spacer(),
        if (_categorizing)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.8),
              ),
              const SizedBox(width: 6),
              Text(
                'Thinking…',
                style: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  color: scheme.primary,
                ),
              ),
            ],
          )
        else
          PressableOpacity(
            onTap: _saving ? null : _suggestCategory,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Suggest',
                    style: TextStyle(
                      fontFamily: IosKit.systemFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _categoryBlock() {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.defaultCategories.map((c) {
        final selected = _category == c;
        final color = AppColors.categoryColor(c, brightness: scheme.brightness);
        return IosKit.chip(
          label: c,
          selected: selected,
          accent: color,
          scheme: scheme,
          onTap: _saving ? null : () => setState(() => _category = c),
        );
      }).toList(),
    );
  }

  Widget _paymentBlock() {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.paymentMethods.map((p) {
        final selected = _paymentMethod == p;
        return IosKit.chip(
          label: p,
          selected: selected,
          accent: scheme.primary,
          scheme: scheme,
          showCheck: true,
          onTap: _saving ? null : () => setState(() => _paymentMethod = p),
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
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: scheme.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.weekdayLabel(_expenseDate),
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
                    Formatters.longDate(_expenseDate),
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
          label: _isEditing ? 'Save changes' : 'Add expense',
          icon: Icons.check_rounded,
          isLoading: _saving,
          onTap: _save,
        ),
      ),
    );
  }
}