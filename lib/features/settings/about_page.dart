// 关于微信 — 完整静态 UI
//
// 1:1 复刻微信 iOS 关于页：
//   1. 顶部：微信 Logo + 名称 + 版本号
//   2. 列表：功能介绍 / 开源声明 / 隐私政策 / 用户协议 / 服务条款
//      / 投诉 / 反馈
//   3. 底部：©1998-2024 Tencent Inc.
//
// 隐私政策等长文本用 showModalBottomSheet 弹出"内容占位"页。
// 反馈用 SnackBar 提示。
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/design_tokens.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  /// 应用版本号（与 pubspec.yaml 中的 version 保持一致）
  static const String _kAppVersion = '1.0.0';
  static const String _kBuildNumber = '1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(title: const Text('关于微信'), centerTitle: true),
      body: ListView(
        children: <Widget>[
          const SizedBox(height: WxSpace.xxl),
          const _Header(),
          const SizedBox(height: WxSpace.xl),
          _Group(
            items: <_AboutItem>[
              _AboutItem(label: '功能介绍', onTap: _showFeatureIntro),
              _AboutItem(label: '开源声明', onTap: (c) => _showText(
                    c,
                    title: '开源声明',
                    body: _kOpenSourceNotice,
                  )),
              _AboutItem(label: '隐私政策', onTap: (c) => _showText(
                    c,
                    title: '隐私政策',
                    body: _kPrivacyPolicy,
                  )),
              _AboutItem(label: '用户协议', onTap: (c) => _showText(
                    c,
                    title: '用户协议',
                    body: _kUserAgreement,
                  )),
              _AboutItem(label: '服务条款', onTap: (c) => _showText(
                    c,
                    title: '服务条款',
                    body: _kTermsOfService,
                  )),
            ],
          ),
          _Group(
            items: <_AboutItem>[
              _AboutItem(label: '投诉举报', onTap: (c) => _toast(c, '投诉举报 - TODO')),
              _AboutItem(label: '反馈与建议', onTap: (c) => _toast(c, '反馈与建议 - TODO')),
            ],
          ),
          const SizedBox(height: WxSpace.xxl),
          const _Footer(),
          const SizedBox(height: WxSpace.huge),
        ],
      ),
    );
  }

  void _showFeatureIntro(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TextSheet(
        title: '功能介绍',
        body: _kFeatureIntro,
      ),
    );
  }

  void _showText(BuildContext context,
      {required String title, required String body}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TextSheet(title: title, body: body),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 80),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

// =====================================================================
// 头部：Logo + 名称 + 版本
// =====================================================================

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SvgPicture.asset(
          'assets/icons/wechat_logo.svg',
          width: 64,
          height: 64,
        ),
        const SizedBox(height: WxSpace.md),
        const Text(
          '微信',
          style: TextStyle(
            fontSize: WxFontSize.title,
            fontWeight: WxFontWeight.medium,
            color: WxColors.textPrimary,
          ),
        ),
        const SizedBox(height: WxSpace.xs),
        Text(
          '版本 ${AboutPage._kAppVersion} (${AboutPage._kBuildNumber})',
          style: const TextStyle(
            fontSize: WxFontSize.small,
            color: WxColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// 列表分组
// =====================================================================

class _Group extends StatelessWidget {
  final List<_AboutItem> items;
  const _Group({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      margin: const EdgeInsets.only(top: WxSpace.sm),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            _Row(item: items[i]),
            if (i < items.length - 1)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                color: WxColors.divider,
                indent: WxSpace.lg,
              ),
          ],
        ],
      ),
    );
  }
}

class _AboutItem {
  final String label;
  final void Function(BuildContext) onTap;
  const _AboutItem({required this.label, required this.onTap});
}

class _Row extends StatelessWidget {
  final _AboutItem item;
  const _Row({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => item.onTap(context),
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: WxSpace.lg),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: WxFontSize.bodyLarge,
                    color: WxColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: WxColors.textHint,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// 底部版权
// =====================================================================

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const <Widget>[
        Text(
          '©1998-2026 Tencent Inc.',
          style: TextStyle(
            fontSize: WxFontSize.small,
            color: WxColors.textTertiary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '本应用为 Flutter 学习项目，非微信官方',
          style: TextStyle(
            fontSize: WxFontSize.caption,
            color: WxColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// 长文本底部弹层
// =====================================================================

class _TextSheet extends StatelessWidget {
  final String title;
  final String body;
  const _TextSheet({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return SafeArea(
      top: false,
      child: Container(
        height: mq.size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(WxRadius.lg)),
        ),
        child: Column(
          children: <Widget>[
            // 顶部把手 + 标题 + 关闭
            Container(
              padding: const EdgeInsets.symmetric(horizontal: WxSpace.lg),
              height: 48,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: WxFontSize.title,
                        fontWeight: WxFontWeight.medium,
                        color: WxColors.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: WxColors.textHint),
                  ),
                ],
              ),
            ),
            const Divider(height: 0.5, thickness: 0.5, color: WxColors.divider),
            // 文本
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(WxSpace.lg),
                child: Text(
                  body,
                  style: const TextStyle(
                    fontSize: WxFontSize.body,
                    color: WxColors.textPrimary,
                    height: 1.6,
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

// =====================================================================
// 占位文本
// =====================================================================

const String _kFeatureIntro = '''
微信（WeChat）是一款跨平台的即时通讯应用，由腾讯公司于 2011 年推出。

主要功能：
• 文字、语音、视频聊天
• 群聊、群公告
• 朋友圈（图片 / 视频分享）
• 视频号（短视频）
• 微信支付、转账、红包
• 公众号、小程序
• 文件传输、位置共享

本应用为 Flutter 教学项目，仅 1:1 复刻 UI 视觉，不提供真实通讯能力。
''';

const String _kOpenSourceNotice = '''
本应用使用了以下开源软件（按字母顺序排序）：

• cached_network_image 3.4.x — MIT License
• collection 1.18.x — BSD-3-Clause License
• csv 6.0.x — BSD-2-Clause License
• file_picker 8.1.x — MIT License
• fl_chart 0.69.x — MIT License
• flutter_lints 6.0.x — BSD-3-Clause License
• flutter_riverpod 2.5.x — MIT License
• flutter_svg 2.0.x — MIT License
• gal 2.3.x — MIT License
• go_router 14.6.x — BSD-3-Clause License
• intl 0.19.x — BSD-3-Clause License
• package_info_plus 8.0.x — BSD-3-Clause License
• path_provider 2.1.x — BSD-3-Clause License
• shared_preferences 2.3.x — MIT License
• timeago 3.7.x — MIT License

完整许可文本请参见各依赖的 LICENSE 文件。
''';

const String _kPrivacyPolicy = '''
【隐私政策 — 占位文本】

一、我们如何收集和使用您的信息
1. 账号信息：手机号、昵称、头像、微信 ID
2. 通讯录信息：在您授权后用于匹配好友
3. 位置信息：用于"附近"、"位置共享"等功能
4. 设备信息：设备型号、操作系统版本、设备识别码

二、我们如何共享、转让和公开披露您的信息
除以下情形外，我们不会与任何第三方共享您的个人信息：
1. 获得您的明确同意
2. 与我们的关联方共享
3. 与授权合作伙伴共享
4. 基于法律或政府要求

三、您的权利
1. 访问您的个人信息
2. 更正或删除您的个人信息
3. 撤回授权
4. 注销账号

四、未成年人保护
我们非常重视对未成年人个人信息的保护。如您是未成年人，建议您的父母或监护人阅读本政策。

五、本政策的修订
我们可能根据业务调整、法律法规变化等因素修订本政策。

（本段为占位文本，实际使用请替换为正式法务文件）
''';

const String _kUserAgreement = '''
【用户协议 — 占位文本】

一、服务说明
本应用为基于 Flutter 框架开发的学习/演示项目，提供 1:1 复刻微信移动端 UI 的体验。所有数据均为本地 mock 数据，不涉及真实微信账号或服务。

二、账号注册与使用
1. 演示账号：本项目预置 5 个写死账号供体验（手机号 13800000001 ~ 13800000005，密码统一 123456）
2. 数据隔离：所有数据存储于设备本地，不会上传至任何服务器
3. 数据清除：清除应用数据或重新安装会丢失所有本地数据

三、用户行为规范
您理解并同意，您不得利用本应用从事下列行为：
1. 违反国家法律法规的行为
2. 危害计算机信息网络安全的行为
3. 侵犯他人合法权益的行为
4. 其他违反公序良俗的行为

四、知识产权
本应用所含的 UI 设计、图标、文字等内容仅用于学习研究，请勿用于商业用途。微信商标及品牌归腾讯公司所有。

五、免责声明
本应用按"现状"提供，不保证无故障运行。开发者不对因使用本应用而产生的任何损失承担责任。

（本段为占位文本，实际使用请替换为正式法务文件）
''';

const String _kTermsOfService = '''
【服务条款 — 占位文本】

第一条 接受条款
访问或使用本应用即表示您同意本服务条款的所有内容。

第二条 服务变更
我们保留随时修改或中止本应用部分或全部服务的权利，恕不另行通知。

第三条 用户责任
1. 您应对使用本应用过程中的一切行为负责
2. 您应妥善保管账号信息，因账号泄露造成的损失由您自行承担
3. 您不得以任何方式干扰本应用的正常运行

第四条 免责声明
1. 本应用仅作为学习演示用途，不保证服务的准确性、可靠性、及时性
2. 因不可抗力（包括但不限于自然灾害、网络中断等）导致的服务中断，我们不承担责任
3. 因您使用第三方资源（如头像占位图）而产生的任何问题，由您自行承担

第五条 法律适用
本条款的解释、效力及争议解决均适用中华人民共和国法律。

（本段为占位文本，实际使用请替换为正式法务文件）
''';
