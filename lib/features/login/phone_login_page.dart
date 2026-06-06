import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/services/auth_state.dart';
import '../../data/repositories/auth_repo.dart';
import 'widgets/dark_login_layout.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  static const AuthRepository _repo = AuthRepository();

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
        statusBarColor: DarkLoginColors.background,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: DarkLoginColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: DarkLoginLayout(
        title: '手机号登录',
        buttonEnabled: _canContinue,
        loading: _loggingIn,
        buttonLabel: '同意并继续',
        onButtonPressed: _onContinue,
        onTabletLogin: () => _toast('平板登录暂未开放'),
        formChildren: [
          const DarkLoginRow.display(label: '国家/地区', value: '中国大陆（+86）'),
          const DarkLoginHairline(),
          DarkLoginRow.input(
            label: '手机号',
            hint: '请填写手机号码',
            controller: _phoneCtrl,
            autofocus: true,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            onSubmitted: (_) => _onContinue(),
          ),
          const DarkLoginHairline(),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '上述手机号仅用于登录验证',
              style: TextStyle(
                color: DarkLoginColors.secondaryText,
                fontSize: 12,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: DarkLoginTextLink(
              label: '用微信号/QQ号/邮箱登录',
              onTap: () => context.push('/login/account'),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
