import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/ios_kit.dart';
import '../widgets/mascot_widget.dart';
import 'auth/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  static const _welcomeSeenKey = 'has_seen_welcome';

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  static const _slides = [
    _Slide(
      state: MascotState.welcome,
      accent: AppColors.alkanPurple,
      title: 'Meet Alkan',
      description:
          'Your playful money buddy who helps you track every peso — even offline.',
    ),
    _Slide(
      state: MascotState.happy,
      accent: AppColors.alkanGold,
      title: 'Track in seconds',
      description:
          'Type something like "₱150 lunch" and Alkan handles the rest.',
    ),
    _Slide(
      state: MascotState.thinking,
      accent: AppColors.aiAccent,
      title: 'Smart insights',
      description:
          'Personalized tips, budget alerts, and AI-driven spending patterns.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(WelcomeScreen._welcomeSeenKey, true);
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      IosKit.route(const LoginScreen()),
    );
  }

  void _next() {
    if (_finishing) return;
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = _page == _slides.length - 1;
    final current = _slides[_page];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Theme(
        data: IosKit.theme(context),
        child: Stack(
          children: [
            IosKit.ambientBackground(scheme),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PressableOpacity(
                          onTap: _finishing ? null : _finish,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                fontFamily: IosKit.systemFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? current.accent
                                : scheme.onSurface
                                    .withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPaddingLarge,
                      0,
                      AppSpacing.screenPaddingLarge,
                      AppSpacing.lg,
                    ),
                    child: IosPrimaryButton(
                      label: isLast ? 'Get started' : 'Next',
                      icon: isLast
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      onTap: _finishing ? null : _next,
                      isLoading: _finishing,
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
}

class _Slide {
  final MascotState state;
  final Color accent;
  final String title, description;
  const _Slide({
    required this.state,
    required this.accent,
    required this.title,
    required this.description,
  });
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingLarge,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 260,
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
                        slide.accent.withValues(alpha: 0.18),
                        slide.accent.withValues(alpha: 0.0),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
                MascotView(
                  state: slide.state,
                  size: 200,
                  motion: MascotMotion.breathe,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: IosKit.systemFont,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              slide.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: IosKit.systemFont,
                fontSize: 15,
                height: 1.5,
                letterSpacing: -0.1,
                color: scheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ),
        ],
      ),
    );
  }
}