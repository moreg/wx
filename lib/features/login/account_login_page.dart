import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_state.dart';
import '../../data/models/login_account.dart';
import '../../data/repositories/auth_repo.dart';
import 'widgets/dark_login_layout.dart';

class AccountLoginPage extends StatefulWidget {
  const AccountLoginPage({super.key});

  @override
  State<AccountLoginPage> createState() => _AccountLoginPageState();
}

class _AccountLoginPageState extends State<AccountLoginPage> {
  static const AuthRepository _repo = AuthRepository();

  late final TextEditingController _accountCtrl;
  late final TextEditingController _passwordCtrl;
  bool _loggingIn = false;

  bool get _canLogin =>
      _accountCtrl.text.trim().isNotEmpty &&
      _passwordCtrl.text.isNotEmpty &&
      !_loggingIn;

  @override
  void initState() {
    super.initState();
    _accountCtrl = TextEditingController()..addListener(_onInputChanged);
    _passwordCtrl = TextEditingController()..addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _accountCtrl
      ..removeListener(_onInputChanged)
      ..dispose();
    _passwordCtrl
      ..removeListener(_onInputChanged)
      ..dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
  }

  Future<void> _onLogin() async {
    if (!_canLogin) {
      return;
    }
    FocusScope.of(context).unfocus();

    final account = _findAccount(_accountCtrl.text.trim());
    if (account == null || account.password != _passwordCtrl.text) {
      _toast('账号或密码错误');
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

  LoginAccount? _findAccount(String input) {
    for (final account in _repo.allAccounts) {
      if (account.wxid == input || account.phone == input) {
        return account;
      }
    }
    return null;
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
        title: '微信号/QQ号/邮箱登录',
        buttonEnabled: _canLogin,
        loading: _loggingIn,
        buttonLabel: '同意并登录',
        onButtonPressed: _onLogin,
        onTabletLogin: () => _toast('平板登录暂未开放'),
        formChildren: [
          DarkLoginRow.input(
            label: '账号',
            hint: '请填写微信号/QQ号/邮箱',
            controller: _accountCtrl,
            autofocus: true,
            textInputAction: TextInputAction.next,
          ),
          const DarkLoginHairline(),
          DarkLoginRow.input(
            label: '密码',
            hint: '请填写密码',
            controller: _passwordCtrl,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onLogin(),
          ),
          const DarkLoginHairline(),
          const SizedBox(height: 26),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '上述微信号/QQ号/邮箱仅用于登录验证',
              style: TextStyle(
                color: DarkLoginColors.secondaryText,
                fontSize: 15,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: DarkLoginTextLink(
              label: '用手机号登录',
              onTap: () => context.go('/login/phone'),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
