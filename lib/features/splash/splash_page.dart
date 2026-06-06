import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _minimumVisibleTime = Duration(milliseconds: 1400);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final bootStartedAt = DateTime.now();
    final isLoggedIn = await AuthState.isLoggedInStatic();
    final elapsed = DateTime.now().difference(bootStartedAt);

    if (elapsed < _minimumVisibleTime) {
      await Future.delayed(_minimumVisibleTime - elapsed);
    }
    if (!mounted) {
      return;
    }

    context.go(isLoggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(backgroundColor: Colors.black, body: _SplashScene()),
    );
  }
}

class _SplashScene extends StatefulWidget {
  const _SplashScene();

  @override
  State<_SplashScene> createState() => _SplashSceneState();
}

class _SplashSceneState extends State<_SplashScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(
      begin: 1.018,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Image.asset(
              'assets/images/earth_splash.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        const _SplashToneOverlay(),
      ],
    );
  }
}

class _SplashToneOverlay extends StatelessWidget {
  const _SplashToneOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.18),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.08),
              Colors.black.withValues(alpha: 0.34),
            ],
            stops: const [0, 0.34, 0.76, 1],
          ),
        ),
      ),
    );
  }
}
