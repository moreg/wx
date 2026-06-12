// "我" 页面 — 1:1 复刻微信 iOS 移动端
//
// 视觉规范（与图片严格一致）：
//   - 头部白底：左 64dp 方形头像（4px 圆角），右昵称 + 微信号行 + 状态/更多按钮
//   - 列表：浅灰 #EDEDED 背景上的白色卡片，条高 56dp，左 28dp 图标 / 16dp 间距 / 文字
//   - 分割：同组内 0.5dp 浅灰细分隔线（缩进 64dp），跨组 8dp 灰色色块
//   - 右侧：文字 + 红色小圆点 + 12dp 灰箭头
//
// 颜色 / 间距 token 见 [WxColors] / [WxSpace] / [WxRadius] / [WxFontSize]。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_state.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/models/login_account.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  late Future<LoginAccount?> _accountFuture;

  @override
  void initState() {
    super.initState();
    _accountFuture = _loadCurrentAccount();
  }

  Future<LoginAccount?> _loadCurrentAccount() async {
    final auth = await AuthState.create();
    return auth.currentAccount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      // iOS 风格：透明状态栏，亮色图标（在白底上为黑）
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: ListView(
          padding: const EdgeInsets.only(bottom: WxSpace.huge),
          children: <Widget>[
            _ProfileHeader(accountFuture: _accountFuture),

            // 头部与"服务"之间的灰色色块
            const _GroupGap(),

            // —— 1. 服务（微信官方服务图标：气泡+对勾）——
            _ListItem(
              icon: 'assets/icons/fuwu.svg',
              iconColor: WxColors.green,
              label: '服务',
              onTap: () => context.push('/pay'),
            ),

            const _GroupGap(),

            // —— 2. 收藏 ——
            const _ListItem(
              icon: 'assets/icons/favorites.svg',
              iconColor: null, // 多色内嵌
              label: '收藏',
            ),
            const _ListDivider(),
            // —— 3. 朋友圈（真版：蓝色相片图标，山+太阳）——
            const _ListItem(
              icon: 'assets/icons/picture_regular.svg',
              iconColor: WxColors.linkBlue,
              label: '朋友圈',
            ),
            const _ListDivider(),
            // —— 4. 作品（真版：蓝色三层错位叠卡片，带副文本 + 红点）——
            const _ListItem(
              icon: 'assets/icons/me-works.svg',
              iconColor: null, // 多色 SVG，不染色
              label: '作品',
              showRedDot: true,
              trailingText: '添加第1个作品',
            ),
            const _ListDivider(),
            // —— 5. 表情 ——
            const _ListItem(
              icon: 'assets/icons/sticker-outlined.svg',
              iconColor: WxColors.warning,
              label: '表情',
            ),

            const _GroupGap(),

            // —— 6. 设置 ——
            _ListItem(
              icon: 'assets/icons/setting-outlined.svg',
              iconColor: WxColors.linkBlue,
              label: '设置',
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 组之间的灰色色块（8dp）
// =====================================================================

class _GroupGap extends StatelessWidget {
  const _GroupGap();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: WxSpace.sm, // 8dp
      color: WxColors.bg,
    );
  }
}

// =====================================================================
// 头部：头像 + 昵称 + 微信号 + 二维码 + 状态 / 更多
// =====================================================================

class _ProfileHeader extends StatelessWidget {
  final Future<LoginAccount?> accountFuture;
  const _ProfileHeader({required this.accountFuture});

  @override
  Widget build(BuildContext context) {
    // 顶部留白 = 状态栏安全区 + 16dp 内容间距，
    // 在刘海/挖孔/标准机型下都不会贴到状态栏
    final topPadding = MediaQuery.of(context).padding.top + 16;
    return Container(
      color: WxColors.card,
      padding: EdgeInsets.fromLTRB(20, topPadding, 16, 28),
      child: FutureBuilder<LoginAccount?>(
        future: accountFuture,
        builder: (context, snap) {
          final account = snap.data;
          final nickname = account?.nickname ?? '微信用户';
          final wxid = account?.wxid ?? '-';
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 头像：方形 + 4px 圆角
                  ClipRRect(
                    borderRadius: BorderRadius.circular(WxRadius.md),
                    child: account == null
                        ? const _AvatarFallback(size: 64, letter: '微')
                        : Image.asset(
                            account.avatar,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _AvatarFallback(
                              size: 64,
                              letter: nickname.isEmpty
                                  ? '?'
                                  : nickname.characters.first,
                            ),
                          ),
                  ),
                  const SizedBox(width: 20),
                  // 右侧信息列
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // 昵称：20sp 黑色中等粗
                          Text(
                            nickname,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: WxFontWeight.medium,
                              color: WxColors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // 微信号 + 箭头
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '微信号：$wxid',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: WxColors.textSecondary,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SvgPicture.asset(
                                'assets/icons/weui-arrow.svg',
                                width: 12,
                                theme: const SvgTheme(currentColor: WxColors.textHint),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // "+ 状态" 圆角按钮 + 刷新按钮
                          Row(
                            children: <Widget>[
                              _StatusButton(),
                              const SizedBox(width: 12),
                              _EmptyCircleButton(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // 二维码图标：独立定位在头部右上角
              Positioned(
                top: 4,
                right: 0,
                child: SvgPicture.asset(
                  'assets/icons/qrcode-outlined.svg',
                  width: 20,
                  height: 20,
                  theme: const SvgTheme(currentColor: WxColors.textSecondary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// "+ 状态" 圆角描边按钮
class _StatusButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: WxColors.divider, width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.add,
            size: 13,
            color: WxColors.textSecondary,
          ),
          SizedBox(width: 2),
          Text(
            '状态',
            style: TextStyle(
              fontSize: 13,
              color: WxColors.textSecondary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// 刷新按钮（真版：带旋转箭头的圆形按钮）
class _EmptyCircleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: WxColors.divider, width: 0.5),
      ),
      child: const Icon(
        Icons.refresh,
        size: 18,
        color: WxColors.textSecondary,
      ),
    );
  }
}

// =====================================================================
// 通用列表项（白底 / 56dp 高 / 28dp 图标 / 16dp 间距）
// =====================================================================

class _ListItem extends StatelessWidget {
  final String icon;
  final Color? iconColor;
  final String label;
  final String? trailingText; // 右侧副文本（灰色）
  final bool showRedDot;     // 副文本右侧的小红点
  final VoidCallback? onTap;

  const _ListItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailingText,
    this.showRedDot = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: icon.toLowerCase().endsWith('.png')
                      ? Image.asset(
                          icon,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        )
                      : SvgPicture.asset(
                          icon,
                          width: 24,
                          height: 24,
                          theme: iconColor != null
                              ? SvgTheme(currentColor: iconColor!)
                              : null,
                          fit: BoxFit.contain,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      color: WxColors.textPrimary,
                    ),
                  ),
                ),
                if (trailingText != null) ...<Widget>[
                  Text(
                    trailingText!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: WxColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (showRedDot) ...<Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: WxColors.unread,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                SvgPicture.asset(
                  'assets/icons/weui-arrow.svg',
                  width: 12,
                  theme: const SvgTheme(currentColor: WxColors.textHint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 同组内细分隔线（缩进 64dp）
class _ListDivider extends StatelessWidget {
  const _ListDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      padding: const EdgeInsets.only(left: 64),
      child: Container(
        height: 0.5,
        color: WxColors.divider,
      ),
    );
  }
}

// 头像占位（图片加载失败时显示）
class _AvatarFallback extends StatelessWidget {
  final double size;
  final String letter;
  const _AvatarFallback({required this.size, required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: WxColors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(WxRadius.md),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: WxColors.green,
          fontSize: size / 2.5,
          fontWeight: WxFontWeight.medium,
        ),
      ),
    );
  }
}
