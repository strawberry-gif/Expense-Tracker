import 'package:flutter/material.dart';

import '../../services/ai_service.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/ios_kit.dart';
import '../../widgets/mascot_widget.dart';
import 'add_expense_screen.dart';

class AIInputScreen extends StatefulWidget {
  const AIInputScreen({super.key});

  @override
  State<AIInputScreen> createState() => _AIInputScreenState();
}

class _AIInputScreenState extends State<AIInputScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  final List<String> _examples = const [
    '₱150 lunch',
    'I spent 280 pesos for Grab going to school',
    'Bought coffee for 120',
    'Spent 500 on groceries yesterday',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    if (_busy) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _busy = true);
    try {
      final parsed = await AIService.parseExpense(text);
      if (!mounted) return;
      if (parsed == null) {
        IosKit.snack(
          context,
          'Could not understand the input. Try again.',
          error: true,
        );
        return;
      }
      final confirm = await _showPreview(parsed);
      if (confirm != true) return;
      if (!mounted) return;
      final saved = await Navigator.push<bool>(
        context,
        IosKit.route(AddExpenseScreen(prefill: parsed)),
      );
      if (!mounted) return;
      if (saved == true) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (!mounted) return;
      IosKit.snack(
        context,
        'Could not parse the expense. Please try again.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _showPreview(ParsedExpense parsed) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              parsed.isLocal
                  ? Icons.offline_bolt_rounded
                  : Icons.auto_awesome_rounded,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              parsed.isLocal ? 'Offline parse' : 'AI parsed',
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _previewRow(
                'Amount',
                parsed.amount == null
                    ? '—'
                    : '₱${parsed.amount!.toStringAsFixed(2)}',
              ),
              _previewRow('Category', parsed.category),
              _previewRow('Description', parsed.description),
              if (parsed.merchant != null)
                _previewRow('Merchant', parsed.merchant!),
              if (parsed.paymentMethod != null)
                _previewRow('Payment', parsed.paymentMethod!),
              if (parsed.expenseDate != null)
                _previewRow('Date', parsed.expenseDate!),
              const SizedBox(height: 10),
              Text(
                'You can still edit before saving.',
                style: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 12,
                  letterSpacing: -0.1,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
            ],
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
            child: Text(
              'Continue',
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
  }

  Widget _previewRow(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 13,
                letterSpacing: -0.1,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
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
                  _header(scheme),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        AppSpacing.sm,
                        AppSpacing.screenPadding,
                        AppSpacing.xxxl,
                      ),
                      children: [
                        _hero(),
                        const SizedBox(height: AppSpacing.xxl),
                        _inputBlock(),
                        const SizedBox(height: AppSpacing.md),
                        _parseButton(),
                        const SizedBox(height: AppSpacing.xxxl),
                        Text('TRY THESE', style: IosKit.kicker(scheme)),
                        const SizedBox(height: AppSpacing.sm),
                        _examplesBlock(),
                      ],
                    ),
                  ),
                ],
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
            onTap: _busy ? null : () => Navigator.pop(context),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI INPUT', style: IosKit.kicker(scheme)),
                Text(
                  'Tell Alkan',
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

  Widget _hero() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.16),
                      scheme.primary.withValues(alpha: 0.0),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              MascotView(
                pose: _busy
                    ? MascotPose.aiThinking
                    : MascotPose.aiListening,
                size: 140,
                motion:
                    _busy ? MascotMotion.pulse : MascotMotion.float,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _busy ? 'Reading…' : 'Describe the expense',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: IosKit.systemFont,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            _busy
                ? 'Extracting amount, category, merchant, and date.'
                : 'Plain words work best. Alkan fills in the rest.',
            textAlign: TextAlign.center,
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

  Widget _inputBlock() {
    final scheme = Theme.of(context).colorScheme;
    final hasText = _controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasText
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.onSurface.withValues(alpha: 0.08),
          width: hasText ? 1.5 : 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 3,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              readOnly: _busy,
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 15,
                height: 1.5,
                letterSpacing: -0.1,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'What did you spend on?',
                hintStyle: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 15,
                  letterSpacing: -0.1,
                  color: scheme.onSurface.withValues(alpha: 0.4),
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (hasText)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: PressableOpacity(
                onTap: _busy
                    ? null
                    : () => setState(() => _controller.clear()),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _parseButton() {
    final hasText = _controller.text.trim().isNotEmpty;
    return IosPrimaryButton(
      label: _busy ? 'Reading…' : 'Parse expense',
      icon: Icons.auto_fix_high_rounded,
      isLoading: _busy,
      onTap: hasText ? _parse : null,
    );
  }

  Widget _examplesBlock() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
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
      child: Column(
        children: [
          for (int i = 0; i < _examples.length; i++) ...[
            _exampleRow(_examples[i]),
            if (i < _examples.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: AppSpacing.md + 20 + AppSpacing.md,
                endIndent: AppSpacing.md,
                color: scheme.onSurface.withValues(alpha: 0.08),
              ),
          ],
        ],
      ),
    );
  }

  Widget _exampleRow(String text) {
    final scheme = Theme.of(context).colorScheme;
    return PressableOpacity(
      onTap: _busy
          ? null
          : () {
              _controller.text = text;
              setState(() {});
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.north_east_rounded,
                size: 12,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: IosKit.systemFont,
                  fontSize: 14,
                  letterSpacing: -0.1,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}