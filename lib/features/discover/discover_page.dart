// 发现 Tab — 完整静态 UI
//
// 1:1 复刻微信 iOS 发现页：3 列宫格，包含朋友圈 / 视频号 / 直播 /
// 扫一扫 / 摇一摇 / 看一看 / 搜一搜 / 附近 / 购物 共 9 项。
//
// 宫格背景：白色卡片圆角块；图标用 32dp 主题色，文字 12sp 二级色。
// 项之间用 0.5px 分割线分组，项内部用 0.5px 分割线分格。
import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  static const List<_DiscoverItem> _items = <_DiscoverItem>[
    _DiscoverItem(
      icon: Icons.camera_alt_outlined,
      label: '朋友圈',
      color: Color(0xFF07C160),
      badge: 'New',
    ),
    _DiscoverItem(
      icon: Icons.play_circle_outline,
      label: '视频号',
      color: Color(0xFFFA9D3B),
    ),
    _DiscoverItem(
      icon: Icons.live_tv_outlined,
      label: '直播',
      color: Color(0xFFE64340),
    ),
    _DiscoverItem(
      icon: Icons.qr_code_scanner,
      label: '扫一扫',
      color: Color(0xFF576B95),
    ),
    _DiscoverItem(
      icon: Icons.vibration,
      label: '摇一摇',
      color: Color(0xFFFA9D3B),
    ),
    _DiscoverItem(
      icon: Icons.travel_explore_outlined,
      label: '看一看',
      color: Color(0xFF576B95),
    ),
    _DiscoverItem(
      icon: Icons.search,
      label: '搜一搜',
      color: Color(0xFFE64340),
    ),
    _DiscoverItem(
      icon: Icons.location_on_outlined,
      label: '附近',
      color: Color(0xFF07C160),
    ),
    _DiscoverItem(
      icon: Icons.shopping_bag_outlined,
      label: '购物',
      color: Color(0xFFFA9D3B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(title: const Text('发现'), centerTitle: true),
      body: ListView(
        children: <Widget>[
          const SizedBox(height: WxSpace.sm),
          _DiscoverGrid(items: _items),
          const SizedBox(height: WxSpace.sm),
          // 朋友圈入口（朋友圈是一级类目，有时间线 + 封面图块）
          _MomentsEntry(),
        ],
      ),
    );
  }
}

class _DiscoverItem {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  const _DiscoverItem({
    required this.icon,
    required this.label,
    required this.color,
    this.badge,
  });
}

/// 3 列宫格：9 个 item 排成 3 行，每行 3 个。
class _DiscoverGrid extends StatelessWidget {
  final List<_DiscoverItem> items;
  const _DiscoverGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      padding: const EdgeInsets.symmetric(vertical: WxSpace.sm),
      child: Column(
        children: <Widget>[
          for (int row = 0; row < items.length / 3; row++)
            IntrinsicHeight(
              child: Row(
                children: <Widget>[
                  for (int col = 0; col < 3; col++) ...<Widget>[
                    Expanded(
                      child: _DiscoverCell(item: items[row * 3 + col]),
                    ),
                    if (col < 2)
                      const VerticalDivider(
                        width: 0.5,
                        thickness: 0.5,
                        color: WxColors.divider,
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DiscoverCell extends StatelessWidget {
  final _DiscoverItem item;
  const _DiscoverCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showToast(context, item.label),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: WxSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(WxRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                if (item.badge != null)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: WxColors.unread,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: WxFontWeight.medium,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: WxSpace.xs),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: WxFontSize.small,
                color: WxColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 朋友圈入口卡片：头像 + 昵称 + 一句提示文字
class _MomentsEntry extends StatelessWidget {
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF07C160).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(WxRadius.sm),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Color(0xFF07C160),
              size: 22,
            ),
          ),
          const SizedBox(width: WxSpace.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '朋友圈',
                  style: TextStyle(
                    fontSize: WxFontSize.bodyLarge,
                    color: WxColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '三张昨天拍的照片等你翻牌',
                  style: TextStyle(
                    fontSize: WxFontSize.small,
                    color: WxColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: WxColors.textHint,
            size: 18,
          ),
        ],
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
