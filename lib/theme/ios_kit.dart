import 'dart:ui';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

class IosKit {
  IosKit._();

  static String get systemFont {
    if (kIsWeb) return 'Inter';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? '.SF Pro Text'
        : 'Inter';
  }

  static ThemeData theme(BuildContext context) {
    return Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
  }

  static Route<T> route<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  static Widget ambientBackground(ColorScheme scheme) {
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
                    scheme.primary.withValues(alpha: 0.10),
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
                      scheme.tertiary.withValues(alpha: 0.14),
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
                      scheme.secondary.withValues(alpha: 0.10),
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

  static List<BoxShadow> get softShadows => [
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
      ];

  static Widget glassCard({
    required ColorScheme scheme,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(24),
    double radius = 24,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.06),
              width: 0.5,
            ),
            boxShadow: softShadows,
          ),
          child: child,
        ),
      ),
    );
  }

  static InputDecoration inputDecoration({
    required ColorScheme scheme,
    String? hint,
    IconData? icon,
    Widget? suffix,
    EdgeInsets? contentPadding,
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
        fontFamily: systemFont,
        fontSize: 15,
        color: scheme.onSurface.withValues(alpha: 0.35),
        letterSpacing: -0.1,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              size: 20,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
      suffixIcon: suffix,
      filled: true,
      fillColor: scheme.onSurface.withValues(alpha: 0.04),
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        fontFamily: systemFont,
        fontSize: 12,
        letterSpacing: -0.1,
      ),
    );
  }

  static TextStyle inputStyle(ColorScheme scheme) => TextStyle(
        fontFamily: systemFont,
        fontSize: 15,
        letterSpacing: -0.1,
        color: scheme.onSurface,
      );

  static TextStyle kicker(ColorScheme scheme, {Color? color}) => TextStyle(
        fontFamily: systemFont,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: color ?? scheme.onSurface.withValues(alpha: 0.5),
      );

  static Widget fieldLabel(String text, ColorScheme scheme) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: systemFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: scheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }

  static void snack(
    BuildContext context,
    String message, {
    bool error = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: systemFont,
            fontSize: 14,
            letterSpacing: -0.1,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? scheme.error : null,
      ),
    );
  }

  static Widget chip({
    required String label,
    required bool selected,
    required Color accent,
    required ColorScheme scheme,
    VoidCallback? onTap,
    bool showCheck = false,
  }) {
    return PressableOpacity(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.15)
              : scheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCheck && selected) ...[
              Icon(Icons.check_rounded, size: 14, color: accent),
              const SizedBox(width: 6),
            ] else if (selected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: systemFont,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
                color: selected
                    ? accent
                    : scheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PressableOpacity extends StatefulWidget {
  const PressableOpacity({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedOpacity = 0.7,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedOpacity;

  @override
  State<PressableOpacity> createState() => _PressableOpacityState();
}

class _PressableOpacityState extends State<PressableOpacity> {
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

class IosPrimaryButton extends StatelessWidget {
  const IosPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isLoading = false,
    this.color,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.primary;
    final fg = scheme.onPrimary;

    return PressableOpacity(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.24),
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
                    valueColor: AlwaysStoppedAnimation(fg),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: IosKit.systemFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: fg,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 6),
                      Icon(icon, size: 18, color: fg),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class IosIconButton extends StatelessWidget {
  const IosIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.iconSize = 18,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressableOpacity(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.onSurface.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: color ?? scheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}