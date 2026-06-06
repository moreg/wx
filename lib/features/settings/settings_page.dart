// 设置 — 完整静态 UI
//
// 1:1 复刻微信 iOS 设置页：分组列表，每行图标 + 文字 + 右侧箭头；
// 底部红色"退出登录"按钮。
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_state.dart';
import '../../core/theme/design_tokens.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const List<List<_SettingsItem>> _groups =
      <List<_SettingsItem>>[
    <_SettingsItem>[
      _SettingsItem(
        icon: Icons.lock_outline,
        iconColor: WxColors.textSecondary,
        label: '账号与安全',
      ),
      _SettingsItem(
        icon: Icons.notifications_none,
        iconColor: WxColors.expense,
        label: '消息通知',
      ),
      _SettingsItem(
        icon: Icons.privacy_tip_outlined,
        iconColor: WxColors.green,
        label: '隐私',
      ),
    ],
    <_SettingsItem>[
      _SettingsItem(
        icon: Icons.person_outline,
        iconColor: WxColors.linkBlue,
        label: '通用',
      ),
      _SettingsItem(
        icon: Icons.chat_bubble_outline,
        iconColor: WxColors.green,
        label: '聊天',
      ),
      _SettingsItem(
        icon: Icons.devices,
        iconColor: WxColors.warning,
        label: '设备',
      ),
    ],
    <_SettingsItem>[
      _SettingsItem(
        icon: Icons.help_outline,
        iconColor: WxColors.textSecondary,
        label: '帮助与反馈',
      ),
      _SettingsItem(
        icon: Icons.info_outline,
        iconColor: WxColors.linkBlue,
        label: '关于微信',
        route: '/about',
      ),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: ListView(
        children: <Widget>[
          for (int i = 0; i < _groups.length; i++) ...<Widget>[
            const SizedBox(height: WxSpace.sm),
            _SettingsGroup(items: _groups[i]),
          ],
          const SizedBox(height: WxSpace.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: WxSpace.lg),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: WxColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WxRadius.sm),
                  ),
                ),
                onPressed: () => _confirmLogout(context),
                child: const Text(
                  '退出登录',
                  style: TextStyle(color: WxColors.expense),
                ),
              ),
            ),
          ),
          const SizedBox(height: WxSpace.huge),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('退出', style: TextStyle(color: WxColors.expense)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final auth = await AuthState.create();
    await auth.clear();
    if (!context.mounted) return;
    context.go('/login');
  }
}

class _SettingsItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? route;
  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.route,
  });
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            _SettingsRow(item: items[i]),
            if (i < items.length - 1)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                color: WxColors.divider,
                indent: 56,
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final _SettingsItem item;
  const _SettingsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (item.route != null) {
          context.push(item.route!);
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${item.label} - TODO'),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 80),
              duration: const Duration(seconds: 2),
            ),
          );
      },
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WxSpace.lg,
            vertical: WxSpace.sm,
          ),
          child: Row(
            children: <Widget>[
              Icon(item.icon, color: item.iconColor, size: 22),
              const SizedBox(width: WxSpace.md),
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
