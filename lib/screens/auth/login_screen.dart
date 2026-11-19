import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/ios_kit.dart';
import '../../widgets/mascot_widget.dart';
import '../main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _busy = false;
  bool _obscure = true;
  bool _hadError = false;
  bool _typing = false;
  bool _celebrating = false;
  Timer? _typingTimer;

  String get _systemFont {
    if (kIsWeb) return 'Inter';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? '.SF Pro Text'
        : 'Inter';
  }

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
    _email.addListener(_handleTypingState);
    _password.addListener(_handleTypingState);
    _email.addListener(_clearError);
    _password.addListener(_clearError);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _handleTypingState() {
    final hasText =
        _email.text.trim().isNotEmpty || _password.text.trim().isNotEmpty;

    _typingTimer?.cancel();

    if (!hasText || _busy || _celebrating) {
      if (_typing && mounted) setState(() => _typing = false);
      return;
    }

    if (!_typing && mounted) setState(() => _typing = true);

    _typingTimer = Timer(const Duration(milliseconds: 750), () {
      if (mounted && _typing) setState(() => _typing = false);
    });
  }

  void _clearError() {
    if (_hadError && mounted) setState(() => _hadError = false);
  }

  Future<void> _login() async {
    if (_busy) return;

    if (!_formKey.currentState!.validate()) {
      if (mounted) setState(() => _hadError = true);
      return;
    }

    setState(() {
      _busy = true;
      _hadError = false;
      _typing = false;
      _celebrating = false;
    });

    try {
      await AuthService.login(_email.text, _password.text);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _celebrating = true;
      });
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        IosKit.route(const MainShell()),
        (_) => false,
      );
      unawaited(SyncService.syncAll());
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
        _hadError = true;
        _celebrating = false;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _hadError = false);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  Future<void> _openRegister() async {
    final ok = await Navigator.push<bool>(
      context,
      IosKit.route(const RegisterScreen()),
    );
    if (!mounted) return;
    if (ok == true) {
      Navigator.of(context).pushAndRemoveUntil(
        IosKit.route(const MainShell()),
        (_) => false,
      );
      unawaited(SyncService.syncAll());
    }
  }

  MascotState get _mascotState {
    if (_celebrating) return MascotState.celebrating;
    if (_busy) return MascotState.loading;
    if (_hadError) return MascotState.sad;
    if (_passwordFocus.hasFocus) return MascotState.hidingEyes;
    if (_emailFocus.hasFocus) return MascotState.looking;
    if (_typing) return MascotState.typing;
    return MascotState.idle;
  }

  MascotMotion get _mascotMotion {
    if (_celebrating) return MascotMotion.bounce;
    if (_busy) return MascotMotion.pulse;
    if (_hadError) return MascotMotion.shake;
    return MascotMotion.breathe;
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
            _ambientBackground(scheme),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight.isFinite
                      ? constraints.maxHeight - AppSpacing.xl * 2
                      : 0.0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xl,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: availableHeight > 0 ? availableHeight : 0,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: _glassCard(
                            scheme: scheme,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _brand(scheme),
                                  const SizedBox(height: AppSpacing.md),

                                  Center(
                                    child: MascotView(
                                      state: _mascotState,
                                      motion: _mascotMotion,
                                      size: 160,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  Text(
                                    'Welcome back',
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
                                    'Sign in to keep your expenses in sync.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: _systemFont,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                      letterSpacing: -0.1,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),

                                  _label('Email', scheme),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _email,
                                    focusNode: _emailFocus,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    textInputAction: TextInputAction.next,
                                    enabled: !_busy,
                                    style: TextStyle(
                                      fontFamily: _systemFont,
                                      fontSize: 15,
                                      letterSpacing: -0.1,
                                    ),
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
                                    enabled: !_busy,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _login(),
                                    style: TextStyle(
                                      fontFamily: _systemFont,
                                      fontSize: 15,
                                      letterSpacing: -0.1,
                                    ),
                                    decoration: _inputDecoration(
                                      scheme: scheme,
                                      hint: '••••••••',
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
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Enter your password'
                                        : null,
                                  ),

                                  const SizedBox(height: AppSpacing.lg),

                                  _iosPrimaryButton(
                                    scheme: scheme,
                                    label: 'Sign in',
                                    isLoading: _busy,
                                    onTap: _login,
                                  ),

                                  const SizedBox(height: AppSpacing.lg),
                                  _footer(scheme),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
    return PressableOpacity(
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
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: scheme.onPrimary,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _brand(ColorScheme scheme) {
    return Column(
      children: [
        Text(
          'Alkan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: _systemFont,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'EXPENSE TRACKER',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: _systemFont,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
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

  Widget _footer(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'New to Alkan?',
          style: TextStyle(
            fontFamily: _systemFont,
            fontSize: 13,
            letterSpacing: -0.1,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(width: 4),
        PressableOpacity(
          onTap: _busy ? null : _openRegister,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Text(
              'Create one',
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
    );
  }
}