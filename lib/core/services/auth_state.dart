// 登录态服务
//
// 用 shared_preferences 持久化"当前登录的 wxid"。
// - 启动时 SplashPage 调用 [read]，未登录跳 /login、已登录跳 /home
// - 登录成功时调用 [setCurrent] 写入 wxid
// - 切换/退出登录时调用 [clear] 清除
//
// 当前账号对象（昵称/头像/手机号）从 [AuthRepository.findByWxid] 解析，
// 不重复写 prefs，减小存储和同步成本。
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/login_account.dart';
import '../../data/repositories/auth_repo.dart';

class AuthState {
  static const String _kCurrentWxidKey = 'current_account_id';

  final AuthRepository _repo;
  final SharedPreferences _prefs;

  const AuthState._(this._repo, this._prefs);

  /// 工厂：初始化 SharedPreferences 并构造实例。
  static Future<AuthState> create({
    AuthRepository repository = const AuthRepository(),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return AuthState._(repository, prefs);
  }

  /// 读取已保存的 wxid（如果有），不命中返回 null。
  String? get currentWxid {
    final v = _prefs.getString(_kCurrentWxidKey);
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// 是否已登录。
  bool get isLoggedIn {
    final id = currentWxid;
    if (id == null) return false;
    return _repo.findByWxid(id) != null;
  }

  /// 当前登录账号对象，未登录返回 null。
  LoginAccount? get currentAccount {
    final id = currentWxid;
    if (id == null) return null;
    return _repo.findByWxid(id);
  }

  /// 写入当前登录 wxid。
  Future<void> setCurrent(String wxid) async {
    await _prefs.setString(_kCurrentWxidKey, wxid);
  }

  /// 清除登录态（退出登录 / 切换账号前调用）。
  Future<void> clear() async {
    await _prefs.remove(_kCurrentWxidKey);
  }

  /// 静态便捷方法：读一次登录态（仅返回 bool，足够 SplashPage 用）。
  /// HomePage / LoginPage 拿到 AuthState 后用 instance 方法拿到完整账号。
  static Future<bool> isLoggedInStatic() async {
    final state = await AuthState.create();
    return state.isLoggedIn;
  }
}
