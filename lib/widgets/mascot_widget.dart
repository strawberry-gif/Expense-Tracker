import 'dart:async';

import 'package:flutter/material.dart';

enum MascotRenderer { png, rive }

const MascotRenderer kMascotRenderer = MascotRenderer.png;

enum MascotPose {
  welcome,
  peek,
  anomaly,
  error,
  loading,
  goodbye,
  offline,
  celebrate,
  empty,
  emptyIncome,
  warning,
  aiAnswering,
  aiThinking,
  aiListening,
}

enum MascotState {
  idle,
  welcome,
  happy,
  thinking,
  celebrating,
  loading,
  sad,
  concerned,
  hidingEyes,
  looking,
  typing,
}

enum MascotMotion {
  none,
  float,
  breathe,
  bounce,
  shake,
  pulse,
  think,
}

extension _PoseAsset on MascotPose {
  String get assetPath => switch (this) {
        MascotPose.welcome => 'assets/mascot/alkan_welcome.png',
        MascotPose.peek => 'assets/mascot/alkan_peek.png',
        MascotPose.anomaly => 'assets/mascot/alkan_anomaly.png',
        MascotPose.error => 'assets/mascot/alkan_error.png',
        MascotPose.loading => 'assets/mascot/alkan_loading.png',
        MascotPose.goodbye => 'assets/mascot/alkan_logout.png',
        MascotPose.offline => 'assets/mascot/alkan_offline.png',
        MascotPose.celebrate => 'assets/mascot/alkan_success.png',
        MascotPose.empty => 'assets/mascot/alkan_empty_expenses.png',
        MascotPose.emptyIncome => 'assets/mascot/alkan_empty_income.png',
        MascotPose.warning => 'assets/mascot/alkan_budget_warning.png',
        MascotPose.aiAnswering => 'assets/mascot/alkan_ai_answering.png',
        MascotPose.aiThinking => 'assets/mascot/alkan_ai_thinking.png',
        MascotPose.aiListening => 'assets/mascot/alkan_ai_listening.png',
      };
}

extension _StatePose on MascotState {
  MascotPose get pose => switch (this) {
        MascotState.idle => MascotPose.welcome,
        MascotState.welcome => MascotPose.welcome,
        MascotState.happy => MascotPose.celebrate,
        MascotState.thinking => MascotPose.aiThinking,
        MascotState.celebrating => MascotPose.celebrate,
        MascotState.loading => MascotPose.loading,
        MascotState.sad => MascotPose.error,
        MascotState.concerned => MascotPose.warning,
        MascotState.hidingEyes => MascotPose.peek,
        MascotState.looking => MascotPose.aiListening,
        MascotState.typing => MascotPose.aiListening,
      };

  int get riveIndex => index;
}

class MascotController extends ChangeNotifier {
  MascotState _state;
  MascotState get state => _state;

  Timer? _revertTimer;

  MascotController({MascotState initial = MascotState.idle})
      : _state = initial;

  void set(MascotState next) {
    _revertTimer?.cancel();
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  void react(
    MascotState next, {
    Duration hold = const Duration(seconds: 2),
  }) {
    _revertTimer?.cancel();
    if (_state != next) {
      _state = next;
      notifyListeners();
    }
    _revertTimer = Timer(hold, () {
      _state = MascotState.idle;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }
}

@Deprecated(
  'Use MascotView. Kept for settings_screen.dart; will be removed after '
  'that screen migrates.',
)
class MascotWidget extends StatelessWidget {
  final double size;

  @Deprecated('Use MascotView for animated mascots.')
  final bool animate;

  final String? semanticsLabel;

  final MascotPose? _pose;
  final MascotState? _state;

  const MascotWidget({
    super.key,
    MascotPose? pose,
    MascotState? state,
    this.size = 120,
    this.animate = false,
    this.semanticsLabel,
  })  : assert(pose != null || state != null),
        _pose = pose,
        _state = state;

  MascotPose get pose => _pose ?? _state!.pose;

  @override
  Widget build(BuildContext context) {
    final child = _MascotArtwork(pose: pose, size: size);
    if (semanticsLabel == null) return child;
    return Semantics(image: true, label: semanticsLabel, child: child);
  }
}

class MascotView extends StatefulWidget {
  final double size;
  final MascotMotion motion;
  final Duration duration;
  final String? semanticsLabel;
  final bool enableLife;

  final MascotPose? _pose;
  final MascotState? _state;
  final MascotController? _controller;

  const MascotView({
    super.key,
    MascotPose? pose,
    MascotState? state,
    MascotController? controller,
    this.size = 140,
    this.motion = MascotMotion.float,
    this.duration = const Duration(milliseconds: 1800),
    this.semanticsLabel,
    this.enableLife = true,
  })  : assert(pose != null || state != null || controller != null),
        _pose = pose,
        _state = state,
        _controller = controller;

  MascotState get state =>
      _controller?.state ?? _state ?? MascotState.idle;

  MascotPose get pose =>
      _controller?.state.pose ?? _state?.pose ?? _pose!;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView>
    with TickerProviderStateMixin {
  late final AnimationController _motion;
  late final AnimationController _breath;

  late Animation<double> _motionValue;
  late Animation<double> _breathValue;

  bool _entered = false;
  bool _reducedMotion = false;

  MascotMotion _effective = MascotMotion.none;

  @override
  void initState() {
    super.initState();

    _motion = AnimationController(vsync: this, duration: widget.duration);
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _breathValue = Tween<double>(begin: 1.0, end: 1.012).animate(
      CurvedAnimation(parent: _breath, curve: Curves.easeInOut),
    );

    _applyMotion();
    widget._controller?.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _entered = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce != _reducedMotion) {
      _reducedMotion = reduce;
      _applyMotion();
    }
    _syncLife();
  }

  @override
  void didUpdateWidget(covariant MascotView old) {
    super.didUpdateWidget(old);
    if (old._controller != widget._controller) {
      old._controller?.removeListener(_onControllerChanged);
      widget._controller?.addListener(_onControllerChanged);
    }
    if (old.motion != widget.motion ||
        old.duration != widget.duration ||
        old.size != widget.size) {
      _applyMotion();
    }
    if (old.enableLife != widget.enableLife) {
      _syncLife();
    }
  }

  @override
  void dispose() {
    widget._controller?.removeListener(_onControllerChanged);
    _motion.dispose();
    _breath.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _syncLife() {
    if (kMascotRenderer == MascotRenderer.rive) return;

    final shouldRun = widget.enableLife && !_reducedMotion;

    if (shouldRun) {
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
    } else {
      if (_breath.isAnimating) _breath.stop();
      _breath.value = 0;
    }
  }

  void _applyMotion() {
    _motion.stop();
    _motion.reset();
    _motion.duration = widget.duration;

    _effective = _reducedMotion ? MascotMotion.none : widget.motion;

    switch (_effective) {
      case MascotMotion.none:
        _motionValue = const AlwaysStoppedAnimation(0);

      case MascotMotion.float:
        _motionValue = Tween<double>(
          begin: 0,
          end: -widget.size * 0.067,
        ).animate(
          CurvedAnimation(parent: _motion, curve: Curves.easeInOut),
        );
        _motion.repeat(reverse: true);

      case MascotMotion.breathe:
        _motion.duration = _scaled(1.6);
        _motionValue = Tween<double>(begin: 1.0, end: 1.03).animate(
          CurvedAnimation(parent: _motion, curve: Curves.easeInOut),
        );
        _motion.repeat(reverse: true);

      case MascotMotion.bounce:
        _motionValue = Tween<double>(
          begin: 0,
          end: -widget.size * 0.117,
        ).animate(
          CurvedAnimation(parent: _motion, curve: Curves.easeOut),
        );
        _motion.repeat(reverse: true);

      case MascotMotion.shake:
        _motion.duration = const Duration(milliseconds: 550);
        final amp = widget.size * 0.05;
        _motionValue = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0, end: amp)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: amp, end: -amp)
                .chain(CurveTween(curve: Curves.easeInOut)),
            weight: 2,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: -amp, end: amp * 0.5)
                .chain(CurveTween(curve: Curves.easeInOut)),
            weight: 1.5,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: amp * 0.5, end: 0)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 1.5,
          ),
        ]).animate(_motion);
        _motion.forward(from: 0);

      case MascotMotion.pulse:
        _motionValue = Tween<double>(begin: 1.0, end: 1.04).animate(
          CurvedAnimation(parent: _motion, curve: Curves.easeInOut),
        );
        _motion.repeat(reverse: true);

      case MascotMotion.think:
        _motion.duration = _scaled(1.4);
        _motionValue = Tween<double>(begin: -0.025, end: 0.025).animate(
          CurvedAnimation(parent: _motion, curve: Curves.easeInOut),
        );
        _motion.repeat(reverse: true);
    }
  }

  Duration _scaled(double factor) => Duration(
        milliseconds: (widget.duration.inMilliseconds * factor).round(),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _entered ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedScale(
        scale: _entered ? 1.0 : 0.94,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: _poseTransition,
          child: ListenableBuilder(
            key: ValueKey<MascotPose>(widget.pose),
            listenable: Listenable.merge([_motion, _breath]),
            builder: (context, _) {
              final img = _MascotArtwork(
                pose: widget.pose,
                size: widget.size,
              );
              final transformed = _applyTransforms(img);
              if (widget.semanticsLabel == null) return transformed;
              return Semantics(
                image: true,
                label: widget.semanticsLabel,
                child: transformed,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _applyTransforms(Widget child) {
    Widget out = child;

    final breathScale = _breathValue.value;
    if (breathScale != 1.0) {
      out = Transform.scale(scale: breathScale, child: out);
    }

    out = _applyMotionTransform(out);
    return out;
  }

  Widget _applyMotionTransform(Widget child) {
    final v = _motionValue.value;
    switch (_effective) {
      case MascotMotion.shake:
        return Transform.translate(offset: Offset(v, 0), child: child);

      case MascotMotion.pulse:
      case MascotMotion.breathe:
        return Transform.scale(scale: v, child: child);

      case MascotMotion.think:
        return Transform.rotate(angle: v, child: child);

      case MascotMotion.float:
        final amplitude = widget.size * 0.067;
        final pulse =
            1.0 + (v.abs() / amplitude).clamp(0.0, 1.0) * 0.015;
        return Transform.translate(
          offset: Offset(0, v),
          child: Transform.scale(scale: pulse, child: child),
        );

      case MascotMotion.bounce:
      case MascotMotion.none:
        return Transform.translate(offset: Offset(0, v), child: child);
    }
  }

  Widget _poseTransition(Widget child, Animation<double> anim) {
    final key = child.key;
    final pose = key is ValueKey<MascotPose> ? key.value : null;

    switch (pose) {
      case MascotPose.error:
      case MascotPose.anomaly:
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.08),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutBack,
            )),
            child: child,
          ),
        );

      case MascotPose.peek:
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.12, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );

      case MascotPose.celebrate:
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0)
                .animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutBack,
            )),
            child: child,
          ),
        );

      case MascotPose.loading:
      case MascotPose.aiThinking:
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0)
                .animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeOut,
            )),
            child: child,
          ),
        );

      case MascotPose.welcome:
      case MascotPose.aiListening:
      case MascotPose.goodbye:
      case MascotPose.offline:
      case MascotPose.warning:
      case MascotPose.empty:
      case MascotPose.emptyIncome:
      case MascotPose.aiAnswering:
      case null:
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
    }
  }
}

class _MascotArtwork extends StatelessWidget {
  final MascotPose pose;
  final double size;

  const _MascotArtwork({required this.pose, required this.size});

  @override
  Widget build(BuildContext context) {
    switch (kMascotRenderer) {
      case MascotRenderer.png:
        return _png(context);
      case MascotRenderer.rive:
        return _rive(context);
    }
  }

  Widget _png(BuildContext context) {
    return Image.asset(
      pose.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (c, _, __) => _fallback(c),
    );
  }

  Widget _rive(BuildContext context) {
    return _png(context);
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'A',
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: scheme.primary,
          letterSpacing: -1.5,
          height: 1,
        ),
      ),
    );
  }
}