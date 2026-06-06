// 写死账号运行时数据
//
// 数据源：lib/data/accounts.json
// 这里以常量列表形式提供给运行时使用，避免在每次登录时
// 都做 IO 解析。如果 Auth Track 后续要换成从 assets 读
// JSON，把 [kAllAccounts] 替换成 rootBundle.loadString +
// jsonDecode 即可，AuthRepository 不用改。
//
// ⚠️ 改这里时请同步改 lib/data/accounts.json。
import '../models/login_account.dart';

const List<LoginAccount> kAllAccounts = <LoginAccount>[
  LoginAccount(
    phone: '13800000001',
    password: '123456',
    nickname: '旅行家小王',
    avatar: 'assets/images/avatars/avatar_1.png',
    wxid: 'wxid_travel_wang',
  ),
  LoginAccount(
    phone: '13800000002',
    password: '123456',
    nickname: '程序猿阿杰',
    avatar: 'assets/images/avatars/avatar_2.png',
    wxid: 'wxid_dev_jay',
  ),
  LoginAccount(
    phone: '13800000003',
    password: '123456',
    nickname: '设计师 Linda',
    avatar: 'assets/images/avatars/avatar_3.png',
    wxid: 'wxid_design_linda',
  ),
  LoginAccount(
    phone: '13800000004',
    password: '123456',
    nickname: '吃货小李',
    avatar: 'assets/images/avatars/avatar_4.png',
    wxid: 'wxid_foodie_li',
  ),
  LoginAccount(
    phone: '13800000005',
    password: '123456',
    nickname: '财务小张',
    avatar: 'assets/images/avatars/avatar_5.png',
    wxid: 'wxid_finance_zhang',
  ),
];
