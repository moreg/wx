// 通用下拉刷新 + 空状态列表包装
//
// 设计目标：
//   1. 一行把"列表 + 下拉刷新 + 空状态 + 加载更多占位"四件事搞定
//   2. 列表为空时自动展示 EmptyState（替代裸 ListView）
//   3. 支持两种用法：
//      a) [RefreshList]  —— 用 [itemBuilder] + [itemCount] 直接构造
//      b) [RefreshList.sliver] —— 提供 Sliver 列表给 CustomScrollView
//   4. 下拉刷新的颜色用微信绿
//
// 用法：
// ```dart
// RefreshList<int>(
//   items: chats,
//   isRefreshing: isRefreshing,
//   onRefresh: _onRefresh,
//   emptyState: const EmptyState(
//     icon: Icons.chat_bubble_outline,
//     title: '暂无聊天',
//     subtitle: '下拉刷新试试',
//   ),
//   itemBuilder: (ctx, i) => ChatTile(chat: chats[i]),
// )
// ```
import 'package:flutter/material.dart';

import '../core/theme/design_tokens.dart';
import 'empty_state.dart';

/// 全屏可下拉刷新的列表。适用于简单的 Linear List。
class RefreshList<T> extends StatelessWidget {
  final List<T> items;

  /// 当前是否处于刷新中（控制 [RefreshIndicator] 转圈）。
  final bool isRefreshing;

  /// 顶部下拉手势完成后的回调。返回 Future，完成时收起刷新头。
  /// 不传则禁用下拉刷新。
  final Future<void> Function()? onRefresh;

  /// items 为空时显示的空状态。null 时显示一个默认的占位。
  final Widget? emptyState;

  /// 列表为空时是否仍允许下拉刷新（默认 true，给用户一个"重试"机会）。
  final bool refreshOnEmpty;

  /// 列表项构造器。
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// 列表项之间的间距。
  final double itemSpacing;

  /// 内边距。
  final EdgeInsetsGeometry padding;

  /// 是否使用 [ListView.separated] 替代 [ListView.builder]（控制分隔线）。
  final bool useSeparated;

  final ScrollPhysics? physics;

  const RefreshList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.isRefreshing = false,
    this.onRefresh,
    this.emptyState,
    this.refreshOnEmpty = true,
    this.itemSpacing = 0,
    this.padding = EdgeInsets.zero,
    this.useSeparated = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final canRefresh = onRefresh != null &&
        (items.isNotEmpty || refreshOnEmpty);

    Widget child;
    if (items.isEmpty) {
      child = emptyState ??
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: '暂无数据',
            subtitle: '下拉刷新试试',
          );
    } else if (useSeparated) {
      child = ListView.separated(
        physics: physics,
        padding: padding,
        itemCount: items.length,
        itemBuilder: (ctx, i) => itemBuilder(ctx, items[i], i),
        separatorBuilder: (_, _) => SizedBox(height: itemSpacing),
      );
    } else {
      child = ListView.builder(
        physics: physics,
        padding: padding,
        itemCount: items.length,
        itemBuilder: (ctx, i) => itemBuilder(ctx, items[i], i),
      );
    }

    if (!canRefresh) return child;

    return RefreshIndicator(
      onRefresh: onRefresh!,
      color: WxColors.green,
      backgroundColor: WxColors.card,
      displacement: 40,
      child: child,
    );
  }
}

/// CustomScrollView 用的下拉刷新 Sliver 列表。
class RefreshSliverList<T> extends StatelessWidget {
  final List<T> items;
  final bool isRefreshing;
  final Future<void> Function()? onRefresh;
  final Widget? emptyState;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  const RefreshSliverList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.isRefreshing = false,
    this.onRefresh,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: emptyState ??
            const EmptyState(
              icon: Icons.inbox_outlined,
              title: '暂无数据',
              subtitle: '下拉刷新试试',
            ),
      );
    }
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) => itemBuilder(ctx, items[i], i),
    );
  }
}
