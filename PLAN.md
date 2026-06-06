# 微信账单 App — 实施计划

> 状态：待评审
> 工作目录：`E:\minimax项目\wx`
> 核心定位：1:1 复刻微信移动端界面，**账单功能是核心**（查看 + 导入 + 统计），其他 Tab 均为装饰页
> 平台：Flutter（iOS + Android 同源代码）

---

## 1. 目标与边界

### 1.1 核心功能（必须完整）
1. **模拟登录** — 多个写死账号，登录态持久化，可切换账号 + 退出登录
2. **账单模块**（核心）
   - 查看：列表 + 详情 + 筛选（时间、收/支、类型）+ 搜索（商家/金额/备注）
   - 导入：解析微信官方导出的 CSV 账单文件，transId 去重
   - 导出：将当前账单导出为 CSV（导入的对称面）
   - 编辑：长按删除单条账单（带确认）
   - 统计：按月趋势线 + 按分类饼图

### 1.2 半装饰功能（轻交互）
- **聊天（Chats）Tab**：聊天列表可点击，支持右滑操作（标已读/删除）、长按置顶/免打扰；详情页查看模拟消息，图片可点开预览
- **通讯录 / 发现 / 我** 三个 Tab，单页占位，UI 复刻即可
- **通用增强**：iOS 状态栏适配、键盘适配、下拉刷新、空状态设计、首启动新手引导、关于微信、退出登录

### 1.3 明确不做
- 真实账号注册、验证码、找回密码
- 真实消息收发
- 支付、转账、红包
- 音视频通话、朋友圈发布、扫一扫识别

---

## 2. 技术选型

| 维度 | 选择 | 用途 |
|---|---|---|
| 框架 | **Flutter 3.x + Dart 3.x** | 1:1 视觉还原 + 跨平台出包 |
| 状态管理 | **Riverpod 2.x** | 全局登录态、账单状态、筛选条件 |
| 路由 | **go_router 14.x** | 声明式路由 + 深链 |
| CSV 解析 | **csv 6.x** | 解析微信官方账单 CSV |
| 文件选择 | **file_picker 8.x** | 从本地选择 CSV 文件 |
| 图表 | **fl_chart 0.68.x** | 月度趋势线 + 分类饼图 |
| 本地存储 | **shared_preferences** | 登录态、用户偏好 |
| 路径操作 | **path_provider** | 持久化导入历史 |
| 字体 | 系统默认 + 苹方/思源 fallback | 微信中文主用苹方 |

**技术栈理由**：账单模块需要 CSV 解析、图表渲染、文件选择，Flutter 生态里 `csv` + `fl_chart` + `file_picker` 是最成熟的组合，没有更合适的替代。

---

## 3. 微信官方账单 CSV 格式分析

### 3.1 真实格式（参考）
微信支付导出的 CSV 大致结构（**UTF-8 BOM 编码**，注意处理）：

```
微信支付账单明细
---
起始时间:[起始时间]  
截止时间:[截止时间]  
---
导出时间:[导出时间]
---

交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
2024-03-15 14:32:11,商户消费,星巴克,咖啡,-,38.00,零钱,支付成功,100001,202403150001,
2024-03-15 12:00:00,转账,朋友A,,-,200.00,零钱,支付成功,100002,,生日快乐
2024-03-14 09:15:00,微信红包,朋友B,红包,+ ,88.00,零钱,已存入零钱,100003,,
...
```

### 3.2 解析策略
- **跳过前 16 行头部**（微信账单固定格式，但版本可能略有差异，做容错）
- **识别分隔行** `---`（含横线的行）
- **数据列定义**：
  | 列名 | 字段 | 类型 | 示例 |
  |---|---|---|---|
  | 交易时间 | `transTime` | DateTime | 2024-03-15 14:32:11 |
  | 交易类型 | `type` | String | 商户消费 |
  | 交易对方 | `counterparty` | String | 星巴克 |
  | 商品 | `product` | String | 咖啡 |
  | 收/支 | `direction` | Enum | 支出/收入/中性 |
  | 金额(元) | `amount` | double | 38.00 |
  | 支付方式 | `payMethod` | String | 零钱/微信零钱通/招商银行(1234) |
  | 当前状态 | `status` | String | 支付成功/已退款 |
  | 交易单号 | `transId` | String | 100001 |
  | 商户单号 | `merchantId` | String? | 202403150001 |
  | 备注 | `remark` | String? | |

### 3.3 分类规则（用于饼图）
按 `交易类型` 自动归类为一级分类：
- 餐饮美食（外卖、商家消费含"餐"、"食"、"饮"等关键词）
- 交通出行（地铁、公交、出租车、滴滴、加油）
- 购物消费（淘宝、京东、拼多多、商场）
- 生活服务（话费、网费、水电、物业）
- 娱乐休闲（游戏、视频会员、KTV）
- 转账红包
- 退款退货
- 其他

**实现**：在仓库层写一个 `BillClassifier`，按关键词规则归类；后续可扩展为可配置的字典。

---

## 4. 信息架构与屏幕清单

### 4.1 顶层架构

```
┌─ Splash（启动页）
│
├─ Login（登录页）
│   ├─ 手机号输入
│   ├─ 密码输入
│   ├─ 账号切换器（点开显示 5 个写死账号）
│   └─ 隐私协议勾选
│
└─ Home（主框架，4 Tab）
    ├─ Tab 1: 微信（Chats）        ← 静态页
    ├─ Tab 2: 通讯录（Contacts）   ← 静态页
    ├─ Tab 3: 发现（Discover）     ← 静态页
    └─ Tab 4: 我（Me）             ← 静态页 + 入口
        └─ 支付（Pay Services）   ← 入口页
            └─ 钱包（Wallet）
                └─ 账单（Bills）  ← 核心
                    ├─ 列表视图
                    ├─ 筛选视图
                    ├─ 详情视图
                    ├─ 统计视图
                    └─ 导入对话框
```

### 4.2 屏幕清单

| # | 屏幕 | 类型 | 关键内容 |
|---|---|---|---|
| S01 | **启动页** | **核心** | 与微信 1:1 一致的启动屏：白底 + 绿色微信 Logo + "微信" + 底部版本号。含原生 splash（iOS LaunchScreen / Android windowBackground）+ Flutter 内 splash 两层 |
| S02 | 登录页 | **核心** | 手机号、密码、5 个可切换账号、登录按钮 |
| S03 | 主框架 | 装饰 | 4 Tab + BottomNavigationBar |
| S04 | 微信 Tab | 半装饰 | 12 个 mock 会话（头像、昵称、最后消息、时间、未读数），可点击 |
| S04b | **聊天详情** | **半核心** | 顶部栏（昵称 / 在线状态）、消息列表（气泡/时间分组/多种类型）、底部输入栏（可发送） |
| S05 | 通讯录 Tab | 装饰 | 30 个 mock 联系人 + 字母索引 + 4 个固定入口 |
| S06 | 发现 Tab | 装饰 | 9 宫格（朋友圈 / 视频号 / 直播 / 扫一扫 / 摇一摇 / 看一看 / 搜一搜 / 附近 / 购物）|
| S07 | 我 Tab | 装饰 | 头像、昵称、微信号、二级入口列表 |
| S08 | 支付/服务 | 装饰 | 16 宫格（收付款、钱包、信用卡还款、生活缴费、医疗健康等）|
| S09 | 钱包 | 装饰 | 余额 + 零钱通 + 银行卡 + **账单入口** |
| S10 | **账单列表** | **核心** | 搜索栏 + 按月分组列表 + 月度汇总 + 右上角"筛选"和"..."菜单 + 下拉刷新 + 长按删除 + 长按导出 |
| S11 | **账单筛选** | **核心** | 时间范围、收/支、类型、金额区间筛选 |
| S12 | **账单详情** | **核心** | 单笔交易完整信息展示 |
| S13 | **账单统计** | **核心** | 月度趋势折线图 + 分类饼图 + 收支汇总 |
| S14 | **账单导入** | **核心** | 文件选择 → 解析预览 → 确认导入 → 成功提示 |
| S15 | 设置 | 装饰 | 列表（账号安全、通用、聊天、隐私、帮助、关于）|
| S16 | **图片预览** | **半核心** | 全屏 + 双指缩放 + 单击关闭 + 保存到本地 + 长按菜单 |
| S17 | **新手引导** | 装饰 | 首次启动 3 页横向滑动教程，可跳过 |
| S18 | **关于微信** | 装饰 | 版本号、开源声明、隐私政策、用户协议、服务条款（占位文本）|
| S19 | 切换账号 / 退出登录 | **核心** | "我"页右上角 / 设置页底部，弹确认对话框 |

### 4.3 屏幕优先级
- **P0（必须完成）**：S01（含原生 + Flutter 双层 splash）、S02、S03、S04（含 S04b 详情 + S16 图片预览 + 右滑/长按）、S07（含 S19 切换/退出入口）、S09（仅含账单入口）、S10（含搜索/下拉刷新/长按删除）、S11、S12、S13、S14、S17、S18
- **P1（占位即可）**：S05、S06、S08、S15

---

## 5. 数据模型

### 5.1 核心实体

```dart
// 登录账号
class LoginAccount {
  final String phone;        // 13800000000
  final String password;     // 123456
  final String nickname;
  final String avatarUrl;
  final String wxid;         // 模拟 wxid
}

// 账单
enum BillDirection { expense, income, neutral }

class Bill {
  final String id;           // 唯一 ID（用 transId 去重）
  final DateTime transTime;
  final String type;         // 交易类型（原始）
  final String counterparty;
  final String? product;
  final BillDirection direction;
  final double amount;       // 始终为正数；方向由 direction 决定
  final String payMethod;
  final String status;
  final String transId;
  final String? merchantId;
  final String? remark;
  final String category;     // 自动归类（餐饮美食 / 交通出行 / ...）
}

// 账单仓库返回的聚合结果
class BillSummary {
  final double totalIncome;
  final double totalExpense;
  final int billCount;
  final Map<String, double> byCategory;   // category -> 金额
  final List<MonthlyStat> monthly;        // 月度统计
}

class MonthlyStat {
  final String month;        // "2024-03"
  final double income;
  final double expense;
}
```

### 5.2 写死账号清单
5 个账号，密码统一 `123456`：

| 手机号 | 昵称 | 头像 |
|---|---|---|
| 13800000001 | 旅行家小王 | 占位图 1 |
| 13800000002 | 程序猿阿杰 | 占位图 2 |
| 13800000003 | 设计师 Linda | 占位图 3 |
| 13800000004 | 吃货小李 | 占位图 4 |
| 13800000005 | 财务小张 | 占位图 5 |

> 注意：演示用 5 个账号，**账单数据全局共享一份**（不按账号分库），简化逻辑。

### 5.3 Mock 数据规模
- **初始账单**：预置 50 条 mock 账单（覆盖近 3 个月、各种类型、各种收/支）
- **导入演示文件**：在 `assets/sample/` 放一份 `wx_bill_sample.csv`（20 条样例），供"导入示例"功能使用
- **联系人/会话**：30 个联系人、12 个会话

---

## 6. 项目结构

```
E:\minimax项目\wx\
├── PLAN.md                       # 本文件
├── README.md                     # 启动说明
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── theme/                # 颜色、字号、间距 token
│   │   ├── router/               # go_router
│   │   └── widgets/              # 通用组件
│   ├── data/
│   │   ├── models/               # LoginAccount / Bill / MonthlyStat ...
│   │   ├── mock/
│   │   │   ├── accounts.json
│   │   │   ├── bills_seed.json   # 初始 50 条
│   │   │   ├── contacts.json
│   │   │   ├── chats.json
│   │   │   └── messages/         # 按 chatId
│   │   └── repositories/
│   │       ├── auth_repo.dart
│   │       ├── bill_repo.dart    # CRUD + 聚合 + 导入
│   │       └── mock_loader.dart
│   ├── features/
│   │   ├── splash/
│   │   ├── login/                # ★ 核心
│   │   ├── home/                 # 4 Tab 容器
│   │   ├── chats/                # 装饰
│   │   ├── contacts/             # 装饰
│   │   ├── discover/             # 装饰
│   │   ├── me/                   # 含支付入口
│   │   ├── pay/                  # 支付/服务
│   │   ├── wallet/               # 钱包
│   │   └── bills/                # ★ 核心
│   │       ├── bill_list_page.dart
│   │       ├── bill_filter_page.dart
│   │       ├── bill_detail_page.dart
│   │       ├── bill_stats_page.dart
│   │       ├── bill_import_page.dart
│   │       └── widgets/
│   └── shared/
│       ├── csv_parser.dart       # 微信 CSV 解析器
│       ├── classifier.dart       # 账单分类器
│       └── formatters.dart       # 时间、金额格式化
├── assets/
│   ├── images/                   # 头像、占位
│   ├── icons/                    # SVG 图标
│   ├── fonts/                    # 中文字体（如需）
│   ├── data/                     # Mock JSON
│   └── sample/
│       └── wx_bill_sample.csv    # 导入演示用
├── test/
│   ├── csv_parser_test.dart
│   ├── classifier_test.dart
│   └── bill_repo_test.dart
└── android/ ios/
```

---

## 7. 关键实现要点

### 7.1 设计 Token（`core/theme/tokens.dart`）
```dart
class WxColors {
  static const green = Color(0xFF07C160);
  static const linkBlue = Color(0xFF576B95);
  static const bg = Color(0xFFEDEDED);
  static const card = Color(0xFFFFFFFF);
  static const bubbleMe = Color(0xFF95EC69);
  static const bubbleOther = Color(0xFFFFFFFF);
  static const navBg = Color(0xFFF7F7F7);
  static const divider = Color(0xFFE5E5E5);
  static const textPrimary = Color(0xFF181818);
  static const textSecondary = Color(0xFF888888);
  static const income = Color(0xFF07C160);  // 收入绿
  static const expense = Color(0xFFE64340); // 支出红
}
```

### 7.2 登录页核心逻辑
```dart
// 1. 5 个写死账号写死在 LoginAccountRepository
// 2. 登录按钮：校验 phone+password 与 5 个账号之一匹配
// 3. 成功：写入 prefs（保存当前账号 wxid），跳转 Home
// 4. 失败：toast 提示"手机号或密码错误"
// 5. "切换账号"按钮：弹底部 ActionSheet 显示 5 个账号
// 6. "我"页右上角放"切换账号"，复用 ActionSheet
```

### 7.3 CSV 解析器
```dart
// 1. file_picker 选文件（限定 .csv 后缀）
// 2. csv 包解析，row[0] 是表头
// 3. 跳过空行、过滤 BOM
// 4. 用 transId 去重（已存在则跳过）
// 5. 返回 List<Bill> 给 UI 预览
// 6. 用户点"确认导入"才写入仓库
```

### 7.4 账单聚合查询
```dart
// BillRepository 暴露：
// - getBills({filter}) -> List<Bill>  按时间倒序
// - getSummary({dateRange}) -> BillSummary
// - importFromCsv(File) -> ImportResult
// - getByMonth(month) -> List<Bill>
```

### 7.5 图表
- **月度趋势线**：`fl_chart` 的 `LineChart`，双线（收入绿、支出红），X 轴为月份
- **分类饼图**：`fl_chart` 的 `PieChart`，取支出 Top 8 分类 + "其他"
- 顶部加收支汇总条（总支出 / 总收入 / 净支出）

### 7.6 1:1 视觉细节
- 头像：**方形 + 4px 圆角**（不是圆形！微信的标志）
- Tab 图标：SVG，1.5px 线宽
- 消息气泡圆角很小（约 4px）
- 字体：苹方 fallback（iOS）/ 思源黑体（Android）
- iOS 大标题 + Android 居中标题双适配

### 7.7 启动页（S01）实现要点 — 1:1 复刻微信

**为什么需要两层 splash**：
- **原生 splash**（iOS `LaunchScreen.storyboard` / Android `styles.xml`）：OS 在 Flutter 引擎启动前显示（0~300ms），避免黑屏
- **Flutter 内 splash**（`lib/features/splash/splash_page.dart`）：Flutter 引擎就绪后显示（300~1500ms），做初始化、读 prefs、检查登录态

两层视觉完全一致，避免出现"一闪"的不专业感。

**视觉规格**（严格按微信 iOS 启动屏）：

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│              ┌─────┐                │
│              │ 微信 │   ← Logo（绿色圆角方块内双气泡）   │
│              │ Logo │      尺寸：96×96dp（iOS）/ 96×96dp（Android）│
│              └─────┘                │
│                                     │
│              微 信                  │   ← 主标题：24sp / PingFang SC / weight 500
│                                     │   ← 颜色：#181818
│                                     │
│              WeChat                 │   ← 副标题：12sp / SF Pro / weight 400
│                                     │   ← 颜色：#888888 / letter-spacing: 1px
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│           微信 8.0.45               │   ← 底部版本号：11sp / #B2B2B2
│           ©1998-2024 Tencent        │   ← 版权：10sp / #B2B2B2
└─────────────────────────────────────┘
```

**Logo 复刻方案**（自绘 SVG，1:1 还原）：

> **说明**：使用自绘 SVG 实现视觉 1:1 还原，无需任何外部素材。

**SVG 规格**（`assets/icons/wechat_logo.svg`，viewBox 0 0 1024 1024）：

```xml
<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <!-- 1. 绿色外圆角方块（用 path 模拟 iOS 风格 squircle，比 rect+rx 更圆润） -->
  <path d="M 512 24
           C 200 24, 24 200, 24 512
           C 24 824, 200 1000, 512 1000
           C 824 1000, 1000 824, 1000 512
           C 1000 200, 824 24, 512 24 Z"
        fill="#07C160" />

  <!-- 2. 左上大白色对话气泡（带尾巴，向左下） -->
  <path d="M 280 270
           L 660 270
           C 720 270, 750 300, 750 360
           L 750 540
           C 750 600, 720 630, 660 630
           L 440 630
           L 360 700
           L 380 630
           L 320 630
           C 260 630, 230 600, 230 540
           L 230 360
           C 230 300, 260 270, 320 270
           C 320 270, 280 270, 280 270 Z"
        fill="#FFFFFF" />

  <!-- 3. 右下小白色对话气泡（带尾巴，向右上） -->
  <path d="M 540 470
           L 760 470
           C 810 470, 840 500, 840 550
           L 840 700
           C 840 750, 810 780, 760 780
           L 700 780
           L 720 840
           L 640 780
           L 540 780
           C 490 780, 460 750, 460 700
           L 460 550
           C 460 500, 490 470, 540 470
           C 540 470, 540 470, 540 470 Z"
        fill="#FFFFFF" />
</svg>
```

**使用方式**（`flutter_svg`）：
```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/icons/wechat_logo.svg',
  width: 96,
  height: 96,
)
```

**关键参数**：
- **外框颜色**：`#07C160`（微信绿 / WeChat Green）
- **气泡颜色**：纯白 `#FFFFFF`
- **外框形状**：用 `C`（贝塞尔曲线）模拟 iOS squircle，比 `rect rx="225"` 更圆润
- **气泡比例**：大泡 ~520×360，小泡 ~380×310，错位 16px 让两个泡的尾巴互不干扰
- **尾巴角度**：大泡尾巴向**左下**指，小泡尾巴向**右下**指，模拟"对话"感

**精度验证**：
- [ ] 启动页 Logo 与微信官方图标在 96×96 下肉眼无差
- [ ] 在 16×16（Tab 栏）下边缘不糊
- [ ] 在 1024×1024（应用图标）下边缘无锯齿

**图标尺寸需求清单**（一份 SVG 矢量复用，自动缩放）：

| 用途 | 尺寸 | 备注 |
|---|---|---|
| 启动页中央 Logo | 96×96 dp | splash 页面 |
| 应用图标 (Android) | 192×192 / 512×512 px | 需 PNG 栅格化（启动 `flutter_launcher_icons` 工具） |
| 应用图标 (iOS) | 1024×1024 px | 同上 |
| 通知栏小图标 | 48×48 px | Android 通知中心 |

**字体 fallback 链**（`TextStyle.fontFamilyFallback`）：
```
iOS:    ['PingFang SC', 'Heiti SC', 'sans-serif']
Android: ['Source Han Sans CN', 'Noto Sans CJK SC', 'sans-serif']
```

**时序控制**（`SplashController`）：
```dart
class SplashController extends StateNotifier<SplashState> {
  Future<void> init() async {
    // 1. 加载关键资源（200ms）
    await Future.wait([
      _loadMockData(),
      _readAuthState(),
    ]);
    
    // 2. 至少显示 800ms（避免一闪而过）
    await Future.delayed(Duration(milliseconds: 800));
    
    // 3. 决定跳转目标
    if (isLoggedIn) → go_router.go('/home');
    else → go_router.go('/login');
  }
}
```

**首次启动 vs 后续启动**：
- 首次启动：显示完后 0.3s 渐隐到登录页
- 后续启动：直接替换（无动画）
- 冷启动 < 200ms：Flutter 内 splash 可能不显示，只看到原生 splash → 登录/主页

**配置文件改动**：
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`：用 AutoLayout 居中放 Logo + 标题
- `android/app/src/main/res/drawable/launch_background.xml`：白色 + 居中 Logo
- `android/app/src/main/res/values/styles.xml`：launchTheme 用上面的 drawable
- `android/app/src/main/res/values-night/styles.xml`：暗色模式的启动主题（白底，不变）

**验收细节**：
- [ ] iOS 启动屏与微信官方截图肉眼无差别（颜色、间距、字号）
- [ ] Android 启动屏同 iOS
- [ ] 暗色模式下启动屏保持白底（与微信一致）
- [ ] 启动屏停留时间 800ms ~ 1500ms
- [ ] 启动到主页 / 登录页无黑屏、无白闪

### 7.9 新增功能实现要点

#### 7.9.1 账单搜索（S10 顶部）
- 搜索栏样式：圆角 8dp，灰底 `#F5F5F5`，左侧放大镜图标，placeholder "搜索账单"
- 支持三种匹配：
  - 商家名 / 商品名 模糊匹配（`contains`）
  - 金额精确匹配（输入数字，匹配 `amount` 字段）
  - 备注 / 交易类型 包含匹配
- 搜索结果实时更新（输入即过滤）
- 搜索状态下隐藏月度分组标题，结果按时间倒序平铺
- 清除按钮：右侧 `×`，点击清空 query 恢复原列表

#### 7.9.2 账单导出（S10 右上角 "..."）
- 菜单项："导出 CSV"
- 导出当前筛选结果（如果是搜索/筛选状态）或全部账单
- 文件名格式：`微信账单_2024-03-15_15-30.csv`
- 实现：用 `csv` 包的 `ListToCsvConverter` 生成 CSV 字符串，写入 `path_provider` 的 `Downloads` 目录
- 导出完成后弹 Toast："已导出到 Downloads/微信账单_xxx.csv"
- Android 11+ 用 `MediaStore`，避免存储权限问题
- 字段：交易时间、交易类型、交易对方、商品、收/支、金额、支付方式、当前状态、交易单号、备注

#### 7.9.3 账单删除（S10 长按）
- 长按单条账单 → 弹出底部菜单："删除"
- 二次确认对话框："确认删除这笔账单？此操作不可撤销"
- 确认后从仓库移除（内存 + 同步 prefs 备份）
- 删除时整组月份折叠时同步更新汇总

#### 7.9.4 图片预览（S16）
- 全屏黑色背景 `Color(0xFF000000)`
- 顶部关闭按钮（白色 X，左上）
- 顶部右侧菜单：保存到相册、收藏、撤回
- 中间：`InteractiveViewer` 包裹，支持双指缩放（min 1.0, max 4.0）
- 单击图片切换工具栏显隐
- 长按图片弹"保存到相册 / 识别图中二维码 / 搜一搜"
- 底部：图片信息（拍摄时间、文件大小，原图/标清切换）
- "保存到相册"用 `image_gallery_saver` 或 `gal` 包，Android 13+ 用 `PhotoManager` 走 MediaStore 不需权限

#### 7.9.5 聊天列表右滑操作（S04 列表项）
- 用 `Dismissible` widget + 自定义方向（仅 `endToStart`，从右往左滑）
- 滑动距离阈值 40% 时露出两个按钮："标为已读"（绿）/ "删除"（红）
- 标已读：未读数清零，关闭滑块
- 删除：从列表移除（带二次确认）
- 滑动未达阈值回弹关闭

#### 7.9.6 聊天长按菜单（S04 列表项）
- 长按弹出 ActionSheet：置顶聊天 / 免打扰 / 删除
- 置顶：该会话在列表顶部置顶（带 📌 图标），重启后保留（prefs 存置顶列表）
- 免打扰：未来消息不显示新消息红点（mock 状态下不深做，仅 UI 状态切换）
- 删除：二次确认后从列表移除

#### 7.9.7 空状态设计（核心组件）
- 通用组件 `EmptyState(icon, title, subtitle, action?)`：
  - 居中布局
  - 大图标（灰色 80×80）
  - 主标题（16sp / #888888）
  - 副标题（14sp / #B2B2B2）
  - 可选操作按钮（带主色边框 + 文字）
- 适用场景：账单列表为空、聊天列表为空、联系人搜索无结果、导入后无新账单、收藏为空等

#### 7.9.8 新手引导（S17）
- 仅首次启动显示（用 `shared_preferences` 标记 `hasShownOnboarding`）
- 3 页横向 `PageView`：
  - 第 1 页：聊天气泡大图 + "聊天，与好友畅所欲言"
  - 第 2 页：钱包图标 + "账单，清晰记录每一笔"
  - 第 3 页：朋友圈图标 + "分享，记录生活精彩瞬间"（可点"开始"按钮）
- 底部小圆点指示器
- 右上角"跳过"按钮任意页可跳到登录

#### 7.9.9 iOS 状态栏适配
- 全局 `SystemUiOverlayStyle` 配置：
  - 亮色页面（白底）：`statusBarColor: transparent, statusBarIconBrightness: dark, statusBarBrightness: light`
  - 暗色页面（深底）：`statusBarColor: transparent, statusBarIconBrightness: light, statusBarBrightness: dark`
- 启动页：白底黑字
- 聊天详情：白底黑字
- 暗色模式不支持（保持白底，与微信官方一致）

#### 7.9.10 键盘 / 表情面板适配
- 输入框点击：键盘弹起，消息列表自动滚到底部
- 表情按钮点击：键盘收起，表情面板从底部弹出（高度 280dp）
- "+" 按钮点击：键盘收起，6 宫格功能面板弹出（高度 280dp）
- 三种状态互斥：键盘 / 表情 / + / 全无
- 用 `MediaQuery.viewInsets.bottom` 监听键盘高度
- 表情面板内容：8 列 × 4 行 emoji 字符（不深做表情商店）

#### 7.9.11 下拉刷新
- 用 Flutter 自带 `RefreshIndicator`
- 账单列表：刷新时重新加载本地数据（mock 模式下不真实刷新，仅触发震动反馈）
- 聊天列表：同上
- 朋友圈：未来扩展（v1 占位）
- 触发后 0.8s 自动收起，模拟网络请求

#### 7.9.12 关于微信（S18）
- 顶部：微信 Logo + 名称 + 版本号（`package_info_plus` 读 `version`）
- 列表项：
  - 功能介绍
  - 开源声明（占位文本 + 几个常见开源库名单）
  - 隐私政策（占位文本完整页）
  - 用户协议（占位文本完整页）
  - 服务条款（占位文本完整页）
  - 投诉举报
  - 反馈与建议
- 底部：©1998-2024 Tencent Inc.

#### 7.9.13 退出登录 / 切换账号（S19）
- "我"页右上角"..."：菜单含"切换账号"、"退出登录"
- 设置页底部："退出登录"红色按钮
- 退出登录：清除 prefs 中的登录态，跳回登录页
- 切换账号：弹底部 ActionSheet 显示 5 个账号，点选后退出当前账号并以新账号登录
- 退出 / 切换都有确认对话框

**Mock 会话设计**（12 个会话，重点会话内容丰富）：

| 会话 | 类型 | 消息数 | 涵盖的消息类型 |
|---|---|---|---|
| 文件传输助手 | 工具 | 5 | 文本、文件 |
| 阿杰 | 单聊 | 25 | 文本、语音、图片、撤回、系统提示 |
| 项目组-后端 | 群聊 | 30 | 文本、@提醒、群公告、图片、表情包描述 |
| Linda | 单聊 | 20 | 文本、位置、转账、撤回 |
| 微信支付 | 公众号 | 8 | 系统通知、文本、链接卡片 |
| 老妈 | 单聊 | 22 | 文本、图片、语音、表情 |
| 公司行政 | 公众号 | 6 | 文本、链接 |
| 拼多多 | 服务号 | 5 | 文本、链接卡片 |
| 健身搭子 | 单聊 | 18 | 文本、图片、撤回 |
| 同事小王 | 单聊 | 15 | 文本、文件 |
| 家庭群 | 群聊 | 28 | 文本、图片、语音、红包 |
| 房东-张 | 单聊 | 10 | 文本、转账、位置 |

**消息类型覆盖**：
- **文本**（最常见）：绿色（我）/ 白色（对方）气泡
- **图片**：显示占位图（带 4:3 灰色背景 + "图片"文字）
- **语音**：🔊 图标 + 时长 + 蓝色进度条
- **视频**：▶️ 缩略图 + 时长
- **位置**：地图缩略图 + 地点名
- **转账**：特殊卡片样式（金额 + "转账"标识）
- **名片**：联系人卡片样式
- **系统提示**：居中灰色小字（"对方撤回了一条消息"、"你已添加了对方，现在可以开始聊天"）
- **时间分组**：每 5 分钟内连续消息合并，只在首条显示时间戳

**输入栏功能**（轻交互）：
- 文本输入 + 发送按钮
- 表情按钮：点击展开表情面板（用 emoji 字符即可，不深做表情商店）
- "+" 按钮：展开图片/拍摄/语音/位置/名片 6 宫格（点击占位提示）
- 发送文本：append 到当前会话的本地消息列表（不持久化，刷新页面回到 mock）
- 语音按钮：长按开始录音，松开"发送"——**这里用假的**：松开发一条 3 秒"语音 [语音]"，仅作 UI 演示

**长按消息**：弹出 ActionSheet（撤回 / 转发 / 收藏 / 复制 / 删除 / 多选），每项 toast 提示即可

---

## 8. 验收标准

### 8.1 核心功能（必须）
- [ ] 启动 → 登录页，5 个账号可点选切换
- [ ] 输入 `13800000001 / 123456` 登录成功，进入主界面
- [ ] "我" → "支付" → "钱包" → "账单" 进入账单页
- [ ] 账单列表展示初始 50 条数据，按月分组
- [ ] 顶部"本月汇总"显示总支出、总收入、净支出
- [ ] 点击任一账单进入详情页
- [ ] 筛选页可按时间/收/支/类型筛选，回到列表生效
- [ ] 统计页展示月度趋势线 + 分类饼图
- [ ] 导入功能：选 `wx_bill_sample.csv` → 预览 → 确认 → 新增到列表
- [ ] 重复导入同一文件不会产生重复账单（用 transId 去重）
- [ ] "切换账号"可登出并切换到另一个账号，重新登录进入主界面
- [ ] 关闭 App 再打开，登录态保留（prefs 持久化）

### 8.2 装饰功能（轻量）
- [ ] 4 个 Tab 全部可点击切换，不闪退
- [ ] 通讯录/发现/我 显示 mock 数据，UI 1:1 复刻
- [ ] 设置页可点开二级页（占位即可）

### 8.3 聊天详情（半核心）
- [ ] 聊天列表点击任一会话进入详情页
- [ ] 详情页展示 mock 消息（按时间分组、区分自己/对方）
- [ ] 覆盖至少 6 种消息类型（文本 / 图片 / 语音 / 系统 / 撤回 / 转账）
- [ ] 输入框可输入文字并"发送"，新消息插入到列表底部
- [ ] 长按消息弹出 ActionSheet（6 项）
- [ ] 表情 / + 面板可展开并能选其中一项
- [ ] 群聊消息能看到 "X 人" 和 @ 提示样式
- [ ] **右滑列表项**："标为已读" + "删除" 两个按钮
- [ ] **长按列表项**：置顶 / 免打扰 / 删除 菜单
- [ ] **图片预览**：点击图片进入全屏预览，双指缩放，保存到相册
- [ ] **键盘适配**：表情 / + 面板弹出时键盘自动收起

### 8.4 账单核心（v2.5 新增）
- [ ] 搜索栏可按商家 / 金额 / 备注 实时过滤
- [ ] 右上角菜单可导出当前账单为 CSV 到 Downloads 目录
- [ ] 长按账单可删除（带二次确认）
- [ ] 下拉刷新有震动反馈

### 8.5 全局体验
- [ ] 首次启动显示 3 页新手引导，可跳过
- [ ] iOS 状态栏颜色与当前页底色匹配
- [ ] 退出登录 / 切换账号 有确认对话框
- [ ] 关于微信页含版本号、开源声明、隐私政策等占位文本
- [ ] 空状态有图标 + 文案（账单/聊天/联系人等关键页）

### 8.6 视觉与性能
- [ ] 关键页面（**启动页**、登录、聊天列表、聊天详情、账单列表、账单详情、统计）对比微信截图相似度 ≥ 90%
- [ ] **启动页**：iOS 启动屏与微信官方肉眼无差别；Android 同 iOS；暗色模式保持白底
- [ ] 360×640 / 390×844 / 414×896 三种屏幕宽度不破版
- [ ] 列表滚动 ≥ 50fps
- [ ] 启动到主界面无黑屏、无白闪
- [ ] `flutter build apk --release` 产出可安装的 `.apk`（< 60MB）

### 8.7 自动化测试
- [ ] `csv_parser_test.dart`：覆盖正常 CSV / 缺列 / 空行 / BOM 四种情况
- [ ] `classifier_test.dart`：覆盖每种分类的关键词匹配
- [ ] `bill_repo_test.dart`：覆盖去重、聚合、筛选三种场景

---

## 9. 里程碑

| 阶段 | 内容 | 工时 |
|---|---|---|
| M0 立项 | `flutter create` + 依赖 + 设计 token + 路由表 + Mock 数据准备 + **原生 splash 配置（iOS LaunchScreen + Android windowBackground）** | 0.5 天 |
| M1 主框架 | Splash（Flutter 内层）+ 登录（含账号切换）+ 4 Tab 容器 | 1 天 |
| M2 装饰页 | 微信/通讯录/发现/我 + 支付/钱包静态页 | 0.5 天 |
| M2b 聊天详情 | S04b 详情页 + 12 个会话 mock 消息 + 多种消息类型 + 输入栏交互 | 1 天 |
| M3 账单核心 | 列表 + 详情 + 筛选 | 1.5 天 |
| M4 账单导入 | CSV 解析器 + 分类器 + 导入 UI | 1 天 |
| M5 账单统计 | 月度趋势 + 分类饼图 + 汇总条 | 0.5 天 |
| M6 视觉打磨 | 对照微信截图逐页调样式 | 1 天 |
| M8 全局打磨 | 状态栏适配 + 键盘适配 + 下拉刷新 + 空状态组件 + 新手引导 + 关于微信页 | 1 天 |
| M9 打包 | Android `.apk` 出包 + 真机验证 | 0.5 天 |
| **合计** | | **~9.5 天**（单人）|

> 用 `mavis-team` 并行可压到 3-4 天。
> 启动页本身工作量不大，但要做 1:1 复刻（含 Logo 自绘、字体、原生配置），放在 M0/M1 之间顺手做。

### 9.2 项目结构补充
- `assets/data/messages/<chatId>.json` —— 按会话 ID 分文件存储 mock 消息，方便扩展
- `lib/features/chat_detail/` —— 聊天详情模块（与 S04b 对应）
- `lib/features/bills/widgets/image_preview.dart` —— 图片预览组件（S16）
- `lib/features/onboarding/` —— 新手引导模块（S17）
- `lib/features/settings/about_page.dart` —— 关于微信页（S18）
- `lib/shared/message_renderer.dart` —— 消息类型 → 气泡组件的映射（switch on type）
- `lib/shared/empty_state.dart` —— 通用空状态组件
- `lib/shared/refresh_list.dart` —— 通用下拉刷新包装

### 9.3 新增依赖
```yaml
dependencies:
  # 之前已有
  ...
  # 新增
  image_gallery_saver: ^2.0.3   # Android 图片保存（Android 12 及以下）
  gal: ^2.3.0                   # Android 13+ / iOS 图片保存
  package_info_plus: ^8.0.0     # 读版本号
  file_saver: ^0.2.14           # CSV 导出到 Downloads
```

---

## 10. 风险与缓解

| 风险 | 影响 | 缓解 |
|---|---|---|
| 微信 CSV 格式版本差异 | 解析失败 | 解析器做容错；提供样例文件给用户对照 |
| 1:1 视觉细节繁多 | 打磨期长 | M6 集中对齐，建立"对照清单" |
| iOS 出包需 Mac | 无法在 Windows 完成 | 代码跨平台开发，iOS 收尾用 Mac |
| fl_chart 性能 | 账单量大时可能卡 | 限制饼图 Top 8 + "其他"合并 |
| 中文字体显示 | 字号/行高不一致 | 用 `fontFamilyFallback` 指定多个 fallback |

---

## 11. 下一步

1. **环境准备**：确认 Windows 上 Flutter / Android SDK / JDK 已装好（如未装，先装）
2. **本计划评审**：确认范围、技术栈、优先级
3. **启动 M0**：`flutter create wx_clone --platforms=android,ios` → 拉依赖
4. **M1 评审节点**：登录跑通后拉用户看一眼，确认方向再深入

执行阶段建议开 `mavis-team` 并行 6 个 Track：
- **Track A（UI/视觉）**：所有屏幕的 Flutter 实现 + 设计 token
- **Track B（数据层）**：Mock JSON + 仓库 + Riverpod Provider + CSV 解析器 + 导出
- **Track C（图表）**：fl_chart 集成 + 月度/分类统计
- **Track D（聊天内容）**：12 个会话的 mock 消息设计 + 消息渲染器 + 多种消息类型组件 + 图片预览
- **Track E（资源/打包）**：SVG 图标 + 头像占位 + Android 出包验证
- **Track F（全局体验）**：iOS 状态栏 + 键盘适配 + 下拉刷新 + 空状态组件 + 新手引导 + 关于微信 + 退出登录

---

**文档版本**：v2.5  
**最后更新**：2026-06-05
