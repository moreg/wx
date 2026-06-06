// 登录账号模型
//
// 5 个写死账号的运行时模型。源数据在
// `lib/data/accounts.json`（人类可读），运行时由
// `lib/data/repositories/accounts_data.dart` 的常量列表提供。
// Auth Track 后续如果要换成从 assets 读 JSON，可以把
// [accountsData] 替换成 rootBundle.loadString + jsonDecode，
// 模型本身不变。
class LoginAccount {
  final String phone; // 手机号（登录用）
  final String password; // 密码
  final String nickname; // 昵称
  final String avatar; // 头像资源路径（assets/images/avatars/...）
  final String wxid; // 模拟微信 ID

  const LoginAccount({
    required this.phone,
    required this.password,
    required this.nickname,
    required this.avatar,
    required this.wxid,
  });

  factory LoginAccount.fromJson(Map<String, dynamic> json) {
    return LoginAccount(
      phone: json['phone'] as String,
      password: json['password'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String,
      wxid: json['wxid'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'password': password,
    'nickname': nickname,
    'avatar': avatar,
    'wxid': wxid,
  };

  @override
  String toString() => 'LoginAccount($wxid, $phone, $nickname)';
}
