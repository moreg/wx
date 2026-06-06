// 通用空状态组件
//
// 列表型页面在"无数据 / 加载失败 / 功能未启用"等场景下使用。
// 设计目标：
//   1. 视觉与微信一致 —— 居中、浅色 icon + 双行文案
//   2. 三段信息：icon（可选）+ title（主文案）+ subtitle（辅助说明）
//   3. 可选 action 按钮 —— 点击跳转/触发刷新/打开说明页
//   4. 父级可控制整块 padding / 高度，便于嵌在 SafeArea 或 Sliver 中
//
// 用法：
// ```dart
// EmptyState(
//   icon: Icons.inbox_outlined,
//   title: '暂无账单',
//   subtitle: '导入微信账单 CSV 后会自动展示',
//   actionLabel: '导入账单',
//   onAction: () => context.push('/bills/import'),
// )
// ```
import 'package:flutter/material.dart';

import '../core/theme/design_tokens.dart';

class EmptyState extends StatelessWidget {
  /// 顶部 icon。传 null 时不渲染 icon 行。
  final IconData? icon;

  /// 主文案，1 行最佳。null/空 时不渲染。
  final String? title;

  /// 辅助说明，可换行（默认居中）。
  final String? subtitle;

  /// 行动按钮文案（可选）。同时需要 [onAction] 才会渲染。
  final String? actionLabel;

  /// 行动按钮点击。null 时不渲染按钮。
  final VoidCallback? onAction;

  /// 整体与"内容区顶部"的距离。默认 0，居中布局。
  final EdgeInsetsGeometry padding;

  /// 整块最大宽度（避免长文案撑到屏幕两端）。默认不限。
  final double? maxWidth;

  /// icon 大小，默认 72（与"无网络"等场景一致）。
  final double iconSize;

  const EmptyState({
    super.key,
    this.icon,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(
      horizontal: WxSpace.xxl,
      vertical: WxSpace.huge,
    ),
    this.maxWidth,
    this.iconSize = 72,
  });

  @override
  Widget build(BuildContext context) {
    // 渲染防御：空配置时不显示空白方块
    if (icon == null && (title == null || title!.isEmpty) &&
        (subtitle == null || subtitle!.isEmpty) &&
        (actionLabel == null || onAction == null)) {
      return const SizedBox.shrink();
    }

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: iconSize,
            color: WxColors.textHint,
          ),
          const SizedBox(height: WxSpace.lg),
        ],
        if (title != null && title!.isNotEmpty)
          Text(
            title!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: WxFontSize.title,
              color: WxColors.textSecondary,
              fontWeight: WxFontWeight.medium,
            ),
          ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: WxSpace.xs),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: WxFontSize.body,
              color: WxColors.textTertiary,
              height: 1.4,
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: WxSpace.xl),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: WxColors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(WxRadius.sm),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: WxSpace.xl,
                vertical: WxSpace.md,
              ),
            ),
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: WxFontSize.body,
                color: WxColors.textOnGreen,
                fontWeight: WxFontWeight.medium,
              ),
            ),
          ),
        ],
      ],
    );

    if (maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: content,
      );
    }

    return Center(
      child: Padding(padding: padding, child: content),
    );
  }
}
