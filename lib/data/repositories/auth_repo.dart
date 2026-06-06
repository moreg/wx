// 认证仓库
//
// 提供 5 个写死账号的查询、登录校验、状态读取能力。
// 登录态持久化由 [AuthState]（lib/core/services/auth_state.dart）
// 负责，本仓库只负责账号匹配和返回 [LoginAccount]。
import '../models/login_account.dart';
import 'accounts_data.dart';

class AuthResult {
  final bool success;
  final LoginAccount? account;
  final String? errorMessage;

  const AuthResult._({required this.success, this.account, this.errorMessage});

  const AuthResult.ok(LoginAccount account)
    : this._(success: true, account: account);

  const AuthResult.fail(String message)
    : this._(success: false, errorMessage: message);
}

class AuthRepository {
  const AuthRepository();

  /// 全部写死账号（不可变列表）。
  List<LoginAccount> get allAccounts => kAllAccounts;

  /// 根据 wxid 找账号，找不到返回 null。
  LoginAccount? findByWxid(String wxid) {
    for (final a in kAllAccounts) {
      if (a.wxid == wxid) return a;
    }
    return null;
  }

  /// 根据手机号找账号，找不到返回 null。
  LoginAccount? findByPhone(String phone) {
    for (final a in kAllAccounts) {
      if (a.phone == phone) return a;
    }
    return null;
  }

  /// 校验手机号 + 密码，成功返回账号。
  /// 校验规则：手机号 + 密码都必须和某个写死账号完全一致。
  AuthResult login({required String phone, required String password}) {
    final phoneTrim = phone.trim();
    if (phoneTrim.isEmpty || password.isEmpty) {
      return const AuthResult.fail('请输入手机号和密码');
    }
    if (phoneTrim.length != 11) {
      return const AuthResult.fail('手机号格式错误');
    }
    final account = findByPhone(phoneTrim);
    if (account == null || account.password != password) {
      return const AuthResult.fail('手机号或密码错误');
    }
    return AuthResult.ok(account);
  }
}
