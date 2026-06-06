import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _backgroundScale;
  late final Animation<double> _controlsOpacity;
  late final Animation<Offset> _controlsOffset;
  late final Animation<double> _languageOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    _backgroundScale = Tween<double>(
      begin: 1,
      end: 0.985,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controlsOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.9, curve: Curves.easeOutCubic),
    );
    _controlsOffset =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.38, 0.9, curve: Curves.easeOutCubic),
          ),
        );
    _languageOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.48, 0.92, curve: Curves.easeOutCubic),
    );

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final buttonWidth = width * 0.3085;
            final buttonHeight = height * 0.0672;

            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: AnimatedBuilder(
                    animation: _backgroundScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _backgroundScale.value,
                        alignment: Alignment.center,
                        child: child,
                      );
                    },
                    child: Image.asset(
                      'assets/images/earth_splash.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                Positioned(
                  top: height * 0.072,
                  right: width * 0.041,
                  child: FadeTransition(
                    opacity: _languageOpacity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        minimumSize: Size(width * 0.068, height * 0.028),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _toast(context, '语言切换暂未开放'),
                      child: const Text(
                        '语言',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1,
                          color: Colors.white,
                          fontWeight: WxFontWeight.regular,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: width * 0.052,
                  right: width * 0.05,
                  bottom: height * 0.0325,
                  child: FadeTransition(
                    opacity: _controlsOpacity,
                    child: SlideTransition(
                      position: _controlsOffset,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BigButton(
                            width: buttonWidth,
                            height: buttonHeight,
                            label: '登录',
                            backgroundColor: WxColors.green,
                            foregroundColor: Colors.white,
                            onPressed: () => context.push('/login/account'),
                          ),
                          _BigButton(
                            width: buttonWidth,
                            height: buttonHeight,
                            label: '注册',
                            backgroundColor: const Color(0xFF1C1C1C),
                            foregroundColor: const Color(0xFFBEBEBE),
                            onPressed: () => _toast(context, '注册功能暂未开放'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 80),
        ),
      );
  }
}

class _BigButton extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  const _BigButton({
    required this.width,
    required this.height,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: WxFontWeight.medium,
              color: foregroundColor,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
