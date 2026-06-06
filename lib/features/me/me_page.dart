import 'package:flutter/material.dart';
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
  Future<LoginAccount?> _loadCurrentAccount() async {
    final auth = await AuthState.create();
    return auth.currentAccount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: WxSpace.huge),
        children: <Widget>[
          _ProfileHeader(loader: _loadCurrentAccount),
          const SizedBox(height: 8),
          const _ListItem(
            icon: 'assets/icons/wechat.svg',
            iconColor: Color(0xFF07C160),
            label: '服务',
            showArrow: true,
          ),
          const SizedBox(height: 8),
          const _ListItem(
            icon: 'assets/icons/favorites.svg',
            iconColor: null, // Colorful intrinsic icon
            label: '收藏',
            showArrow: true,
          ),
          const _ListDivider(),
          const _ListItem(
            icon: 'assets/icons/album-outlined.svg',
            iconColor: Color(0xFF576B95),
            label: '朋友圈',
            showArrow: true,
          ),
          const _ListDivider(),
          _ListItem(
            icon: 'assets/icons/cards.svg',
            iconColor: const Color(0xFF576B95),
            label: '作品',
            showArrow: true,
            trailingWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('添加第1个作品', style: TextStyle(color: WxColors.textHint, fontSize: 16)),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: WxColors.expense,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const _ListDivider(),
          const _ListItem(
            icon: 'assets/icons/sticker-outlined.svg',
            iconColor: Color(0xFFFA9D3B),
            label: '表情',
            showArrow: true,
          ),
          const SizedBox(height: 8),
          _ListItem(
            icon: 'assets/icons/setting-outlined.svg',
            iconColor: const Color(0xFF576B95),
            label: '设置',
            showArrow: true,
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// 头部：头像 + 昵称 + 微信号 + 二维码
// =====================================================================

class _ProfileHeader extends StatelessWidget {
  final Future<LoginAccount?> Function() loader;
  const _ProfileHeader({required this.loader});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(
        left: 20,
        right: 16,
        top: 24,
        bottom: 36,
      ),
      child: FutureBuilder<LoginAccount?>(
        future: loader(),
        builder: (context, snap) {
          final account = snap.data;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(WxRadius.md),
                child: account == null
                    ? const _AvatarFallback(size: 72, letter: '微')
                    : Image.asset(
                        account.avatar,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _AvatarFallback(
                          size: 72,
                          letter: account.nickname.isEmpty
                              ? '?'
                              : account.nickname.characters.first,
                        ),
                      ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 4),
                    Text(
                      account?.nickname ?? '微信用户',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: WxColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '微信号：${account?.wxid ?? '-'}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: WxColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/icons/qrcode-outlined.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            WxColors.textSecondary,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SvgPicture.asset(
                          'assets/icons/weui-arrow.svg',
                          width: 12,
                          colorFilter: const ColorFilter.mode(
                            WxColors.textHint,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(color: WxColors.divider, width: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add,
                                size: 12,
                                color: WxColors.textSecondary,
                              ),
                              SizedBox(width: 2),
                              Text(
                                '状态',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: WxColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: WxColors.divider, width: 0.5),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.more_horiz,
                            size: 14,
                            color: WxColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// 通用列表项
// =====================================================================

class _ListItem extends StatelessWidget {
  final String icon;
  final Color? iconColor;
  final String label;
  final VoidCallback? onTap;
  final bool showArrow;
  final Widget? trailingWidget;

  const _ListItem({
    required this.icon,
    this.iconColor,
    required this.label,
    this.onTap,
    this.showArrow = false,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: <Widget>[
                SvgPicture.asset(
                  icon,
                  width: 24,
                  height: 24,
                  colorFilter: iconColor != null
                      ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      color: WxColors.textPrimary,
                    ),
                  ),
                ),
                if (trailingWidget != null) trailingWidget!,
                if (trailingWidget != null && showArrow) const SizedBox(width: 8),
                if (showArrow)
                  SvgPicture.asset(
                    'assets/icons/weui-arrow.svg',
                    width: 12,
                    colorFilter: const ColorFilter.mode(
                      WxColors.textHint,
                      BlendMode.srcIn,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListDivider extends StatelessWidget {
  const _ListDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 64),
      child: Container(
        height: 0.5,
        color: WxColors.divider,
      ),
    );
  }
}

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
