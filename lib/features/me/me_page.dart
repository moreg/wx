// 我 Tab — 完整静态 UI
//
// 1:1 复刻微信 iOS 我的页：
//   1. 顶部 AppBar 右上角 "..." 菜单（切换账号 / 退出登录）— 由 global-ux 叠加
//   2. 主体内容（头像 / 昵称 / wxid / 9 宫格服务 / 列表）— 由 static-pages 实现
//   3. 底部临时退出按钮已废弃（global-ux 把退出逻辑搬到了 AppBar 菜单）
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_state.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/models/login_account.dart';
import '../../data/repositories/auth_repo.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  static const AuthRepository _repo = AuthRepository();
  static const List<_ServiceItem> _services = <_ServiceItem>[
    _ServiceItem(icon: Icons.star_outline, label: '收藏', color: Color(0xFFFA9D3B)),
    _ServiceItem(icon: Icons.photo_library_outlined, label: '朋友圈', color: Color(0xFF07C160)),
    _ServiceItem(icon: Icons.play_circle_outline, label: '视频号', color: Color(0xFFE64340)),
    _ServiceItem(icon: Icons.account_balance_wallet_outlined, label: '卡包', color: Color(0xFF576B95)),
    _ServiceItem(icon: Icons.emoji_emotions_outlined, label: '表情', color: Color(0xFFFA9D3B)),
  ];

  Future<LoginAccount?> _loadCurrentAccount() async {
    final auth = await AuthState.create();
    return auth.currentAccount;
  }

  Future<void> _onLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WxRadius.md),
        ),
        title: const Text(
          '退出登录',
          style: TextStyle(
            fontSize: WxFontSize.title,
            fontWeight: WxFontWeight.medium,
          ),
        ),
        content: const Text(
          '确定要退出当前账号吗？',
          style: TextStyle(
            fontSize: WxFontSize.body,
            color: WxColors.textSecondary,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '取消',
              style: TextStyle(color: WxColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '退出',
              style: TextStyle(color: WxColors.expense),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    final auth = await AuthState.create();
    await auth.clear();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _onSwitchAccount() async {
    final picked = await showModalBottomSheet<LoginAccount>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AccountSwitcherSheet(accounts: _repo.allAccounts),
    );
    if (picked == null || !mounted) return;
    final auth = await AuthState.create();
    await auth.setCurrent(picked.wxid);
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _onMoreMenu() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MoreMenuSheet(
        onSwitchAccount: _onSwitchAccount,
        onLogout: _onLogout,
      ),
    );
    if (picked == null || !mounted) return;
    if (picked == 'switch') {
      await _onSwitchAccount();
    } else if (picked == 'logout') {
      await _onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(
        title: const Text('我'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            tooltip: '更多',
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: WxColors.textPrimary,
              size: WxIconSize.large,
            ),
            onPressed: _onMoreMenu,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: WxSpace.sm),
        children: <Widget>[
          _ProfileHeader(loader: _loadCurrentAccount),
          const SizedBox(height: WxSpace.sm),
          _StatusRow(),
          const SizedBox(height: WxSpace.sm),
          _PayEntry(),
          const SizedBox(height: WxSpace.sm),
          _ServiceGrid(services: _services),
          const SizedBox(height: WxSpace.sm),
          _ListItem(
            icon: Icons.favorite_border,
            iconColor: WxColors.expense,
            label: '赞与收藏',
          ),
          const SizedBox(height: WxSpace.sm),
          _ListItem(
            icon: Icons.videocam_outlined,
            iconColor: WxColors.linkBlue,
            label: '视频通话',
          ),
          _ListItem(
            icon: Icons.chat_bubble_outline,
            iconColor: WxColors.green,
            label: '表情',
          ),
          const SizedBox(height: WxSpace.sm),
          _ListItem(
            icon: Icons.settings_outlined,
            iconColor: WxColors.textSecondary,
            label: '设置',
            onTap: () => context.push('/settings'),
            showArrow: true,
          ),
          const SizedBox(height: WxSpace.huge),
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
      color: WxColors.card,
      padding: const EdgeInsets.symmetric(
        horizontal: WxSpace.lg,
        vertical: WxSpace.lg,
      ),
      child: FutureBuilder<LoginAccount?>(
        future: loader(),
        builder: (context, snap) {
          final account = snap.data;
          return Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(WxRadius.sm),
                child: account == null
                    ? const _AvatarFallback(size: 64, letter: '微')
                    : Image.asset(
                        account.avatar,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _AvatarFallback(
                          size: 64,
                          letter: account.nickname.isEmpty
                              ? '?'
                              : account.nickname.characters.first,
                        ),
                      ),
              ),
              const SizedBox(width: WxSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      account?.nickname ?? '微信用户',
                      style: const TextStyle(
                        fontSize: WxFontSize.headline,
                        fontWeight: WxFontWeight.medium,
                        color: WxColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.alternate_email,
                          size: 14,
                          color: WxColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '微信号: ${account?.wxid ?? '-'}',
                          style: const TextStyle(
                            fontSize: WxFontSize.small,
                            color: WxColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: <Widget>[
                        Icon(
                          Icons.favorite_outline,
                          size: 14,
                          color: WxColors.expense,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '+ 状态',
                          style: TextStyle(
                            fontSize: WxFontSize.small,
                            color: WxColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.qr_code,
                color: WxColors.textPrimary,
                size: 22,
              ),
              const SizedBox(width: WxSpace.md),
              const Icon(
                Icons.chevron_right,
                color: WxColors.textHint,
                size: 18,
              ),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// 状态行（朋友圈/视频号/直播/小店 四宫格）
// =====================================================================

class _StatusRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      padding: const EdgeInsets.symmetric(vertical: WxSpace.md),
      child: Row(
        children: const <Widget>[
          _StatusItem(icon: Icons.wb_sunny_outlined, label: '状态'),
          _StatusDivider(),
          _StatusItem(icon: Icons.collections_bookmark_outlined, label: '视频号'),
          _StatusDivider(),
          _StatusItem(icon: Icons.local_offer_outlined, label: '直播'),
          _StatusDivider(),
          _StatusItem(icon: Icons.shopping_cart_outlined, label: '小店'),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatusItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: WxColors.textSecondary, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: WxFontSize.small,
              color: WxColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDivider extends StatelessWidget {
  const _StatusDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 24,
      color: WxColors.divider,
    );
  }
}

// =====================================================================
// 支付入口
// =====================================================================

class _PayEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      child: InkWell(
        onTap: () => context.push('/pay'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WxSpace.lg,
            vertical: WxSpace.md,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: WxColors.green,
                  borderRadius: BorderRadius.circular(WxRadius.sm),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: WxSpace.md),
              const Expanded(
                child: Text(
                  '支付',
                  style: TextStyle(
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
// 服务 9 宫格（保留 5 个：收藏 / 朋友圈 / 视频号 / 卡包 / 表情）
// =====================================================================

class _ServiceItem {
  final IconData icon;
  final String label;
  final Color color;
  const _ServiceItem({required this.icon, required this.label, required this.color});
}

class _ServiceGrid extends StatelessWidget {
  final List<_ServiceItem> services;
  const _ServiceGrid({required this.services});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      padding: const EdgeInsets.symmetric(
        horizontal: WxSpace.lg,
        vertical: WxSpace.md,
      ),
      child: Row(
        children: <Widget>[
          for (final s in services)
            Expanded(
              child: InkWell(
                onTap: () => _showToast(context, s.label),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(WxRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: Icon(s.icon, color: s.color, size: 20),
                    ),
                    const SizedBox(height: WxSpace.xs),
                    Text(
                      s.label,
                      style: const TextStyle(
                        fontSize: WxFontSize.small,
                        color: WxColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================================
// 通用列表项
// =====================================================================

class _ListItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;
  final bool showArrow;
  const _ListItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WxSpace.lg,
              vertical: WxSpace.sm,
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: WxSpace.md),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: WxFontSize.bodyLarge,
                      color: WxColors.textPrimary,
                    ),
                  ),
                ),
                if (showArrow)
                  const Icon(
                    Icons.chevron_right,
                    color: WxColors.textHint,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// 头像占位
// =====================================================================

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
        borderRadius: BorderRadius.circular(WxRadius.sm),
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

// =====================================================================
// AppBar 右上角 "..." 弹出的菜单（切换账号 / 退出登录）
// =====================================================================

class _MoreMenuSheet extends StatelessWidget {
  final VoidCallback onSwitchAccount;
  final VoidCallback onLogout;
  const _MoreMenuSheet({
    required this.onSwitchAccount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(WxSpace.sm),
        decoration: BoxDecoration(
          color: WxColors.bg,
          borderRadius: BorderRadius.circular(WxRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: WxSpace.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(WxRadius.md),
              ),
              child: Column(
                children: <Widget>[
                  _MenuTile(
                    icon: Icons.swap_horiz_rounded,
                    label: '切换账号',
                    color: WxColors.textPrimary,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSwitchAccount();
                    },
                  ),
                  const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: WxColors.divider,
                    indent: WxSpace.giant,
                  ),
                  _MenuTile(
                    icon: Icons.logout_rounded,
                    label: '退出登录',
                    color: WxColors.expense,
                    onTap: () {
                      Navigator.of(context).pop();
                      onLogout();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: WxSpace.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: WxSpace.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WxRadius.md),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  '取消',
                  style: TextStyle(
                    fontSize: WxFontSize.bodyLarge,
                    color: WxColors.textPrimary,
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

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: WxSpace.lg,
          vertical: WxSpace.md,
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: color),
            const SizedBox(width: WxSpace.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: WxFontSize.bodyLarge,
                  color: color,
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
// 切换账号 ActionSheet
// =====================================================================

class _AccountSwitcherSheet extends StatelessWidget {
  final List<LoginAccount> accounts;
  const _AccountSwitcherSheet({required this.accounts});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(WxSpace.sm),
        decoration: BoxDecoration(
          color: WxColors.bg,
          borderRadius: BorderRadius.circular(WxRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: WxSpace.lg),
              child: Text(
                '切换账号',
                style: TextStyle(
                  fontSize: WxFontSize.body,
                  color: WxColors.textSecondary,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: WxSpace.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(WxRadius.md),
              ),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < accounts.length; i++) ...<Widget>[
                    InkWell(
                      onTap: () => Navigator.of(context).pop(accounts[i]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: WxSpace.lg,
                          vertical: WxSpace.md,
                        ),
                        child: Row(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(WxRadius.md),
                              child: Image.asset(
                                accounts[i].avatar,
                                width: WxAvatarSize.sm,
                                height: WxAvatarSize.sm,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: WxAvatarSize.sm,
                                  height: WxAvatarSize.sm,
                                  color: WxColors.green.withValues(alpha: 0.2),
                                  alignment: Alignment.center,
                                  child: Text(
                                    accounts[i].nickname.isEmpty
                                        ? '?'
                                        : accounts[i].nickname.characters.first,
                                    style: const TextStyle(
                                      color: WxColors.green,
                                      fontWeight: WxFontWeight.medium,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: WxSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    accounts[i].nickname,
                                    style: const TextStyle(
                                      fontSize: WxFontSize.bodyLarge,
                                      color: WxColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    accounts[i].phone,
                                    style: const TextStyle(
                                      fontSize: WxFontSize.small,
                                      color: WxColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: WxColors.textHint,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i != accounts.length - 1)
                      const Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: WxColors.divider,
                        indent: WxSpace.giant,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: WxSpace.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: WxSpace.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WxRadius.md),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  '取消',
                  style: TextStyle(
                    fontSize: WxFontSize.bodyLarge,
                    color: WxColors.textPrimary,
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

void _showToast(BuildContext context, String label) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('$label - TODO'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 80),
        duration: const Duration(seconds: 2),
      ),
    );
}
