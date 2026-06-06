// 新手引导页（3 页横向 PageView）
//
// 首次启动展示：用 shared_preferences 的 hasShownOnboarding 标记。
// - 任意页点击右上角"跳过" → 标记 + 跳 /login
// - 滑到第 3 页点击底部"开始" → 标记 + 跳 /login
// - 已经登录的，标记 + 跳 /home（极端边界：直接进主页）
//
// 设计参考微信早期版本：
// - 顶部右上"跳过"按钮（TextButton，无背景）
// - 中部 icon + 主文案 + 副文案
// - 底部 PageView 指示器（PageController 自带效果，这里用自定义圆点）
// - 第 3 页多一个绿色"开始"按钮
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_state.dart';
import '../../core/theme/design_tokens.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  /// shared_preferences key —— 标记是否已完成首次引导。
  static const String prefsKey = 'hasShownOnboarding';

  /// 静态便捷方法：首次启动判定。
  static Future<bool> hasShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  /// 静态便捷方法：标记已完成引导。
  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_OnboardPage> _pages = <_OnboardPage>[
    _OnboardPage(
      icon: Icons.chat_bubble_rounded,
      iconColor: WxColors.green,
      title: '聊天',
      subtitle: '与好友畅所欲言',
    ),
    _OnboardPage(
      icon: Icons.account_balance_wallet_rounded,
      iconColor: WxColors.warning,
      title: '账单',
      subtitle: '清晰记录每一笔',
    ),
    _OnboardPage(
      icon: Icons.photo_library_rounded,
      iconColor: WxColors.linkBlue,
      title: '分享',
      subtitle: '记录生活精彩瞬间',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onFinish() async {
    await OnboardingPage.markShown();
    if (!mounted) return;
    final isLoggedIn = await AuthState.isLoggedInStatic();
    if (!mounted) return;
    context.go(isLoggedIn ? '/home' : '/login');
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            // 主 PageView
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (ctx, i) => _OnboardingSlide(page: _pages[i]),
                  ),
                ),
                // 底部指示器 + 第 3 页的"开始"按钮
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WxSpace.xxl,
                    WxSpace.md,
                    WxSpace.xxl,
                    WxSpace.huge,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PageDots(
                        count: _pages.length,
                        index: _index,
                      ),
                      const SizedBox(height: WxSpace.xl),
                      if (_index == _pages.length - 1)
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: WxColors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(WxRadius.sm),
                              ),
                            ),
                            onPressed: _onFinish,
                            child: const Text(
                              '开 始',
                              style: TextStyle(
                                fontSize: WxFontSize.bodyLarge,
                                color: WxColors.textOnGreen,
                                fontWeight: WxFontWeight.medium,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 44,
                          child: TextButton(
                            onPressed: _next,
                            child: const Text(
                              '下一张',
                              style: TextStyle(
                                fontSize: WxFontSize.body,
                                color: WxColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // 顶部"跳过"按钮（任意页可点）
            Positioned(
              top: WxSpace.xs,
              right: WxSpace.sm,
              child: SafeArea(
                bottom: false,
                child: TextButton(
                  onPressed: _onFinish,
                  child: const Text(
                    '跳过',
                    style: TextStyle(
                      fontSize: WxFontSize.body,
                      color: WxColors.textSecondary,
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
}

/// 单页引导内容数据。
class _OnboardPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _OnboardPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

/// 单页引导布局：中部 icon + 主文案 + 副文案。
class _OnboardingSlide extends StatelessWidget {
  final _OnboardPage page;
  const _OnboardingSlide({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WxSpace.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 顶部 icon：浅色圆形背景 + 大 icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: page.iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              page.icon,
              size: 80,
              color: page.iconColor,
            ),
          ),
          const SizedBox(height: WxSpace.huge),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: WxFontSize.huge,
              fontWeight: WxFontWeight.medium,
              color: WxColors.textPrimary,
            ),
          ),
          const SizedBox(height: WxSpace.md),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: WxFontSize.bodyLarge,
              color: WxColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// PageView 底部圆点指示器。
class _PageDots extends StatelessWidget {
  final int count;
  final int index;
  const _PageDots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? WxColors.green : WxColors.textHint,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
