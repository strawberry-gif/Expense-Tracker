import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/ios_kit.dart';
import '../widgets/mascot_widget.dart';
import 'auth/login_screen.dart';
import 'main_shell.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _welcomeSeenKey = 'has_seen_welcome';

  late final AnimationController _c;

  late final Animation<double> _mascotFade;
  late final Animation<double> _mascotScale;
  late final Animation<double> _wordmarkFade;
  late final Animation<Offset> _wordmarkSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _mascotFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.00, 0.55, curve: Curves.easeOut),
    );
    _mascotScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.00, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _wordmarkFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.30, 0.75, curve: Curves.easeOut),
    );
    _wordmarkSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.30, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.50, 0.90, curve: Curves.easeOut),
    );
    _loaderFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.70, 1.00, curve: Curves.easeOut),
    );
    _c.forward();
    _decide();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _decide() async {
    await Future.delayed(const Duration(milliseconds: 1600));

    Widget next = const LoginScreen();
    try {
      final hasSession = await AuthService.hasSession();
      if (hasSession) {
        next = const MainShell();
      } else {
        final prefs = await SharedPreferences.getInstance();
        final seen = prefs.getBool(_welcomeSeenKey) ?? false;
        if (!seen) next = const WelcomeScreen();
      }
    } catch (_) {
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, a, __) =>
            FadeTransition(opacity: a, child: next),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.35),
            radius: 1.1,
            colors: [
              AppColors.alkanPurple.withValues(alpha: 0.22),
              AppColors.darkBackground,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _mascotFade,
                    child: ScaleTransition(
                      scale: _mascotScale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.alkanPurple
                                      .withValues(alpha: 0.35),
                                  AppColors.alkanPurple
                                      .withValues(alpha: 0.00),
                                ],
                              ),
                            ),
                          ),
                          const MascotView(
                            state: MascotState.welcome,
                            size: 200,
                            motion: MascotMotion.breathe,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SlideTransition(
                    position: _wordmarkSlide,
                    child: FadeTransition(
                      opacity: _wordmarkFade,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Alkan',
                            style: TextStyle(
                              fontFamily: IosKit.systemFont,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                              color: AppColors.alkanPurpleLight,
                            ),
                          ),
                          Text(
                            '.',
                            style: TextStyle(
                              fontFamily: IosKit.systemFont,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                              color: AppColors.alkanGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'EXPENSE TRACKER',
                      style: TextStyle(
                        fontFamily: IosKit.systemFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3.5,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                  FadeTransition(
                    opacity: _loaderFade,
                    child: const _ShimmerLine(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatefulWidget {
  const _ShimmerLine();

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 3,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final k = 2 * t - 1;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment(-1 + k, 0),
                end: Alignment(1 + k, 0),
                colors: [
                  AppColors.alkanPurpleLight.withValues(alpha: 0.08),
                  AppColors.alkanPurpleLight.withValues(alpha: 0.55),
                  AppColors.alkanGold,
                  AppColors.alkanPurpleLight.withValues(alpha: 0.55),
                  AppColors.alkanPurpleLight.withValues(alpha: 0.08),
                ],
                stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}