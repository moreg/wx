// 发现 Tab — 完整静态 UI
//
// 1:1 复刻微信 iOS 发现页：传统分组列表布局。
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/design_tokens.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(
        title: const Text('发现'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/weui-search.svg',
              width: 24,
              height: 24,
              theme: const SvgTheme(currentColor: Colors.black),
            ),
            onPressed: () => _showToast(context, '搜索'),
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/add2-outlined.svg',
              width: 24,
              height: 24,
              theme: const SvgTheme(currentColor: Colors.black),
            ),
            onPressed: () => _showToast(context, '添加'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const SizedBox(height: WxSpace.sm),
          // 组 1：朋友圈
          _DiscoverGroup(
            children: <Widget>[
              _DiscoverRow(
                iconPath: 'assets/icons/moment.svg',
                label: '朋友圈',
                useOriginalColor: true,
                onTap: () => _showToast(context, '朋友圈'),
              ),
            ],
          ),
          const SizedBox(height: WxSpace.sm),
          // 组 2：视频号
          _DiscoverGroup(
            children: <Widget>[
              _DiscoverRow(
                iconPath: 'assets/icons/channels-outlined.svg',
                label: '视频号',
                color: const Color(0xFFFA9D3B),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: const Text(
                        '今日金价，今天是2026年\n6月12号的下午18:00',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 13,
                          color: WxColors.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: WxColors.unread,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showToast(context, '视频号'),
              ),
            ],
          ),
          const SizedBox(height: WxSpace.sm),
          // 组 3：扫一扫、听一听
          _DiscoverGroup(
            children: <Widget>[
              _DiscoverRow(
                iconPath: 'assets/icons/scan-outlined.svg',
                label: '扫一扫',
                color: const Color(0xFF10AEFF),
                showDivider: true,
                onTap: () => _showToast(context, '扫一扫'),
              ),
              _DiscoverRow(
                iconPath: 'assets/icons/voice-outlined.svg',
                label: '听一听',
                color: const Color(0xFFFA5151),
                onTap: () => _showToast(context, '听一听'),
              ),
            ],
          ),
          const SizedBox(height: WxSpace.sm),
          // 组 4：看一看、搜一搜
          _DiscoverGroup(
            children: <Widget>[
              _DiscoverRow(
                iconPath: 'assets/icons/look-outlined.svg',
                label: '看一看',
                color: const Color(0xFFFA9D3B),
                showDivider: true,
                onTap: () => _showToast(context, '看一看'),
              ),
              _DiscoverRow(
                iconPath: 'assets/icons/search-outlined.svg',
                label: '搜一搜',
                color: const Color(0xFFE64340),
                onTap: () => _showToast(context, '搜一搜'),
              ),
            ],
          ),
          const SizedBox(height: WxSpace.sm),
          // 组 5：附近的人
          _DiscoverGroup(
            children: <Widget>[
              _DiscoverRow(
                iconPath: 'assets/icons/nearby-outlined.svg',
                label: '附近的人',
                color: const Color(0xFF576B95),
                onTap: () => _showToast(context, '附近的人'),
              ),
            ],
          ),
          const SizedBox(height: WxSpace.sm),
          // 组 6：小程序
          _DiscoverGroup(
            children: <Widget>[
              _DiscoverRow(
                iconPath: 'assets/icons/mini-program-2-outlined.svg',
                label: '小程序',
                color: const Color(0xFF7B57FF),
                onTap: () => _showToast(context, '小程序'),
              ),
            ],
          ),
          const SizedBox(height: WxSpace.xl),
        ],
      ),
    );
  }
}

class _DiscoverGroup extends StatelessWidget {
  final List<Widget> children;
  const _DiscoverGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WxColors.card,
        border: Border(
          top: BorderSide(color: WxColors.divider, width: 0.5),
          bottom: BorderSide(color: WxColors.divider, width: 0.5),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _DiscoverRow extends StatelessWidget {
  final String iconPath;
  final String label;
  final Color color;
  final bool useOriginalColor;
  final Widget? trailing;
  final bool showDivider;
  final VoidCallback onTap;

  const _DiscoverRow({
    required this.iconPath,
    required this.label,
    this.color = const Color(0xFF888888),
    this.useOriginalColor = false,
    this.trailing,
    this.showDivider = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            constraints: const BoxConstraints(minHeight: 56.0),
            padding: const EdgeInsets.symmetric(horizontal: WxSpace.lg),
            child: Row(
              children: <Widget>[
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  theme: useOriginalColor
                      ? null
                      : SvgTheme(currentColor: color),
                ),
                const SizedBox(width: WxSpace.md),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: WxFontSize.title,
                    color: WxColors.textPrimary,
                    fontWeight: WxFontWeight.regular,
                  ),
                ),
                const Spacer(),
                if (trailing != null) ...<Widget>[
                  trailing!,
                  const SizedBox(width: WxSpace.sm),
                ],
                const Icon(
                  Icons.chevron_right,
                  color: WxColors.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
          if (showDivider)
            const Padding(
              padding: EdgeInsets.only(left: 52.0),
              child: Divider(
                height: 0.5,
                thickness: 0.5,
                color: WxColors.divider,
              ),
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
