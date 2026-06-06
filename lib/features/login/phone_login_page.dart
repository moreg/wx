import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_state.dart';
import '../../data/repositories/auth_repo.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  static const AuthRepository _repo = AuthRepository();
  static const Color _background = Color(0xFF111111);
  static const Color _primaryText = Color(0xFFC9C9C9);
  static const Color _secondaryText = Color(0xFF707070);
  static const Color _linkText = Color(0xFF8EA0BA);
  static const Color _divider = Color(0xFF1F1F1F);
  static const Color _cursor = Color(0xFF07C160);

  late final TextEditingController _phoneCtrl;
  bool _loggingIn = false;

  bool get _canContinue => _phoneCtrl.text.trim().length == 11 && !_loggingIn;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController()..addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneCtrl
      ..removeListener(_onPhoneChanged)
      ..dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    setState(() {});
  }

  Future<void> _onContinue() async {
    if (!_canContinue) {
      return;
    }
    FocusScope.of(context).unfocus();

    final account = _repo.findByPhone(_phoneCtrl.text.trim());
    if (account == null) {
      _toast('未找到该手机号对应的测试账号');
      return;
    }

    setState(() => _loggingIn = true);
    try {
      final auth = await AuthState.create();
      await auth.setCurrent(account.wxid);
    } finally {
      if (mounted) {
        setState(() => _loggingIn = false);
      }
    }

    if (!mounted) {
      return;
    }
    context.go('/home');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 84),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _background,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final sidePadding = width * 0.05;

              return Stack(
                children: [
                  Positioned(
                    top: 18,
                    left: sidePadding - 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 32),
                      color: Colors.white,
                      splashRadius: 28,
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: sidePadding),
                      child: Column(
                        children: [
                          SizedBox(height: height * 0.135),
                          const Text(
                            '手机号登录',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _primaryText,
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                              height: 1,
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(height: height * 0.08),
                          const _RegionRow(),
                          const _Hairline(),
                          _PhoneRow(controller: _phoneCtrl),
                          const _Hairline(),
                          const SizedBox(height: 28),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '上述手机号仅用于登录验证',
                              style: TextStyle(
                                color: _secondaryText,
                                fontSize: 17,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 34),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _TextLink(
                              label: '用微信号/QQ号/邮箱登录',
                              onTap: () => _toast('该登录方式暂未开放'),
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: height * 0.21),
                          SizedBox(
                            width: width * 0.46,
                            height: 52,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF242424),
                                disabledBackgroundColor: const Color(
                                  0xFF242424,
                                ),
                                foregroundColor: _primaryText,
                                disabledForegroundColor: const Color(
                                  0xFF5E5E5E,
                                ),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _canContinue ? _onContinue : null,
                              child: _loggingIn
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _primaryText,
                                      ),
                                    )
                                  : const Text(
                                      '同意并继续',
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0,
                                      ),
                                    ),
                            ),
                          ),
                          const Spacer(),
                          _TextLink(
                            label: '作为平板登录',
                            onTap: () => _toast('平板登录暂未开放'),
                            fontSize: 20,
                          ),
                          SizedBox(height: height * 0.075),
                          const _BottomLinks(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
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

class _RegionRow extends StatelessWidget {
  const _RegionRow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 68,
      child: Row(
        children: [
          SizedBox(
            width: 106,
            child: Text(
              '国家/地区',
              style: TextStyle(
                color: _PhoneLoginPageState._primaryText,
                fontSize: 21,
                height: 1,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '中国大陆（+86）',
              style: TextStyle(
                color: _PhoneLoginPageState._primaryText,
                fontSize: 21,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  final TextEditingController controller;

  const _PhoneRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Row(
        children: [
          const SizedBox(
            width: 106,
            child: Text(
              '手机号',
              style: TextStyle(
                color: _PhoneLoginPageState._primaryText,
                fontSize: 21,
                height: 1,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.phone,
              cursorColor: _PhoneLoginPageState._cursor,
              cursorWidth: 2,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              style: const TextStyle(
                color: _PhoneLoginPageState._primaryText,
                fontSize: 21,
                height: 1,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '请填写手机号码',
                hintStyle: TextStyle(
                  color: Color(0xFF5A5A5A),
                  fontSize: 21,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.6,
      color: _PhoneLoginPageState._divider,
    );
  }
}

class _TextLink extends StatelessWidget {
  final String label;
  final double fontSize;
  final VoidCallback onTap;

  const _TextLink({
    required this.label,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: _PhoneLoginPageState._linkText,
            fontSize: fontSize,
            height: 1,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _BottomLinks extends StatelessWidget {
  const _BottomLinks();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '找回密码',
          style: TextStyle(
            color: _PhoneLoginPageState._linkText,
            fontSize: 16,
            height: 1,
          ),
        ),
        _VerticalDivider(),
        Text(
          '导出聊天记录',
          style: TextStyle(
            color: _PhoneLoginPageState._linkText,
            fontSize: 16,
            height: 1,
          ),
        ),
        _VerticalDivider(),
        Text(
          '更多',
          style: TextStyle(
            color: _PhoneLoginPageState._linkText,
            fontSize: 16,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: _PhoneLoginPageState._divider,
    );
  }
}
