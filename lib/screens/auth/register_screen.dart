import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/mascot_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _busy = false;
  bool _obscure = true;
  bool _typing = false;
  bool _celebrating = false;
  bool _validationConcern = false;
  Timer? _typingTimer;
  Timer? _validationReset;

  String get _systemFont {
    if (kIsWeb) return 'Inter';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? '.SF Pro Text'
        : 'Inter';
  }

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(_onFocusChange);
    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
    _confirmFocus.addListener(_onFocusChange);
    _name.addListener(_handleTypingState);
    _email.addListener(_handleTypingState);
    _password.addListener(_handleTypingState);
    _confirm.addListener(_handleTypingState);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _validationReset?.cancel();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _handleTypingState() {
    final hasText = _name.text.trim().isNotEmpty ||
        _email.text.trim().isNotEmpty ||
        _password.text.trim().isNotEmpty ||
        _confirm.text.trim().isNotEmpty;

    _typingTimer?.cancel();

    if (!hasText || _busy || _celebrating) {
      if (_typing && mounted) setState(() => _typing = false);
      return;
    }

    if (!_typing && mounted) setState(() => _typing = true);

    _typingTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted && _typing) setState(() => _typing = false);
    });
  }

  MascotState get _mascotState {
    if (_celebrating) return MascotState.celebrating;
    if (_busy) return MascotState.loading;
    if (_validationConcern) return MascotState.concerned;
    if (_confirmFocus.hasFocus || _passwordFocus.hasFocus) {
      return MascotState.hidingEyes;
    }
    if (_nameFocus.hasFocus || _emailFocus.hasFocus) {
      return MascotState.looking;
    }
    if (_typing) return MascotState.typing;
    return MascotState.idle;
  }

  MascotMotion get _mascotMotion {
    if (_celebrating) return MascotMotion.bounce;
    if (_busy) return MascotMotion.pulse;
    if (_validationConcern) return MascotMotion.shake;
    return MascotMotion.breathe;
  }

  Future<void> _register() async {
    if (_busy) return;

    if (!_formKey.currentState!.validate()) {
      _validationReset?.cancel();
      if (mounted) setState(() => _validationConcern = true);
      _validationReset = Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _validationConcern = false);
      });
      return;
    }

    setState(() {
      _busy = true;
      _validationConcern = false;
      _typing = false;
      _celebrating = false;
    });

    try {
      await AuthService.register(_name.text, _email.text, _password.text);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _celebrating = true;
      });
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _busy = false;
        _validationConcern = true;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _validationConcern = false);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: Stack(
          children: [
            _ambientBackground(scheme),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _glassCard(
                      scheme: scheme,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _topBar(context),
                            const SizedBox(height: AppSpacing.md),

                            Center(
                              child: MascotView(
                                state: _mascotState,
                                motion: _mascotMotion,
                                size: 120,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            Text(
                              'Create your account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: _systemFont,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'A few details and you\u2019re ready to track.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: _systemFont,
                                fontSize: 14,
                                height: 1.4,
                                letterSpacing: -0.1,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            _label('Full name', scheme),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _name,
                              focusNode: _nameFocus,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              enabled: !_busy,
                              style: _inputStyle(scheme),
                              decoration: _inputDecoration(
                                scheme: scheme,
                                hint: 'Juan Dela Cruz',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                      ? 'Enter your name'
                                      : null,
                            ),
                            const SizedBox(height: AppSpacing.md),

                            _label('Email', scheme),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _email,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              enabled: !_busy,
                              style: _inputStyle(scheme),
                              decoration: _inputDecoration(
                                scheme: scheme,
                                hint: 'you@example.com',
                                icon: Icons.mail_outline_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter your email';
                                }
                                if (!v.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),

                            _label('Password', scheme),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _password,
                              focusNode: _passwordFocus,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.next,
                              enabled: !_busy,
                              style: _inputStyle(scheme),
                              decoration: _inputDecoration(
                                scheme: scheme,
                                hint: 'At least 6 characters',
                                icon: Icons.lock_outline_rounded,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  splashRadius: 20,
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  onPressed: _busy
                                      ? null
                                      : () => setState(
                                            () => _obscure = !_obscure,
                                          ),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'Password must be at least 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),

                            _label('Confirm password', scheme),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _confirm,
                              focusNode: _confirmFocus,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              enabled: !_busy,
                              onFieldSubmitted: (_) =>
                                  _busy ? null : _register(),
                              style: _inputStyle(scheme),
                              decoration: _inputDecoration(
                                scheme: scheme,
                                hint: 'Re-enter your password',
                                icon: Icons.lock_outline_rounded,
                              ),
                              validator: (v) => v != _password.text
                                  ? 'Passwords do not match'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            _iosPrimaryButton(
                              scheme: scheme,
                              label: 'Create account',
                              isLoading: _busy,
                              onTap: _register,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account?',
                                  style: TextStyle(
                                    fontFamily: _systemFont,
                                    fontSize: 13,
                                    letterSpacing: -0.1,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                _PressableOpacity(
                                  onTap: _busy
                                      ? null
                                      : () =>
                                          Navigator.pop(context, false),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      'Sign in',
                                      style: TextStyle(
                                        fontFamily: _systemFont,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.1,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ambientBackground(ColorScheme scheme) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.6, -0.8),
                  radius: 1.6,
                  colors: [
                    scheme.primary.withValues(alpha: 0.12),
                    scheme.surface,
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
            Positioned(
              bottom: -140,
              right: -120,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scheme.tertiary.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scheme.secondary.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassCard({
    required ColorScheme scheme,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.06),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 48,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  TextStyle _inputStyle(ColorScheme scheme) {
    return TextStyle(
      fontFamily: _systemFont,
      fontSize: 15,
      letterSpacing: -0.1,
      color: scheme.onSurface,
    );
  }

  InputDecoration _inputDecoration({
    required ColorScheme scheme,
    required String hint,
    required IconData icon,
  }) {
    OutlineInputBorder border(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: _systemFont,
        fontSize: 15,
        color: scheme.onSurface.withValues(alpha: 0.35),
        letterSpacing: -0.1,
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: scheme.onSurface.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: scheme.onSurface.withValues(alpha: 0.04),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: true,
      enabledBorder: border(
        scheme.onSurface.withValues(alpha: 0.08),
        0.8,
      ),
      focusedBorder: border(scheme.primary, 1.5),
      errorBorder: border(scheme.error.withValues(alpha: 0.5), 0.8),
      focusedErrorBorder: border(scheme.error, 1.5),
      errorStyle: TextStyle(
        fontFamily: _systemFont,
        fontSize: 12,
        letterSpacing: -0.1,
      ),
    );
  }

  Widget _iosPrimaryButton({
    required ColorScheme scheme,
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return _PressableOpacity(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(scheme.onPrimary),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: _systemFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: scheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 18,
                      color: scheme.onPrimary,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _PressableOpacity(
          onTap: _busy ? null : () => Navigator.pop(context, false),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.onSurface.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: scheme.onSurface,
            ),
          ),
        ),
        const Spacer(),
        const _BrandMark(),
      ],
    );
  }

  Widget _label(String text, ColorScheme scheme) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: _systemFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: scheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppColors.alkanPurpleLight, AppColors.alkanPurple]
                  : [AppColors.alkanPurple, AppColors.alkanPurpleDark],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Center(
            child: Text(
              'A',
              style: AppTypography.h3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Alkan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: scheme.onSurface,
              ),
            ),
            Text(
              'Expense tracker',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PressableOpacity extends StatefulWidget {
  const _PressableOpacity({
    required this.child,
    required this.onTap,
    this.pressedOpacity = 0.7,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedOpacity;

  @override
  State<_PressableOpacity> createState() => _PressableOpacityState();
}

class _PressableOpacityState extends State<_PressableOpacity> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? widget.pressedOpacity : 1.0,
        child: widget.child,
      ),
    );
  }
}