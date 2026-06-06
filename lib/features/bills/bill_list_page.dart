// 账单列表页 (S10)
//
// 顶部：搜索栏（圆角 + 实时过滤） + 本月汇总条
// 主体：按月分组的账单列表（SliverList + 不可滚动的月份标题）
// 列表项：
//   - 点击 → BillDetailPage
//   - 长按 → 底部菜单（删除 / 导出这一条）
// 右上角：
//   - 筛选按钮 → BillFilterPage
//   - "..." 菜单：导出全部 CSV / 统计
//
// 数据：
//   - 全部从 [BillRepository] (Riverpod) 读取
//   - 搜索词 → [billSearchQueryProvider]
//   - 筛选条件 → [billFilterProvider]
//   - 列表数据按月分组从 [BillRepository.getMonthGroups] 拿
//
// 设计要点（PLAN §7.9.1 - §7.9.3 + §8.4）：
//   - 搜索状态下隐藏月份分组标题，结果按时间倒序平铺
//   - 搜索匹配：商家 / 商品 / 备注 / 类型 / 金额
//   - 删除带二次确认
//   - 导出 CSV 写入 app 外部存储目录 (path_provider)
//   - 下拉刷新只触发震动反馈（mock 模式）
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/design_tokens.dart';
import '../../data/models/bill.dart';
import '../../data/repositories/bill_repo.dart';
import 'bill_detail_page.dart';

class BillListPage extends ConsumerStatefulWidget {
  const BillListPage({super.key});

  @override
  ConsumerState<BillListPage> createState() => _BillListPageState();
}

class _BillListPageState extends ConsumerState<BillListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searchActive = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    ref.read(billSearchQueryProvider.notifier).state = v;
  }

  void _clearSearch() {
    _searchCtrl.clear();
    ref.read(billSearchQueryProvider.notifier).state = '';
    setState(() => _searchActive = false);
    FocusScope.of(context).unfocus();
  }

  void _onTapSearch() {
    setState(() => _searchActive = true);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final bills = ref.watch(billRepoProvider);
    final filter = ref.watch(billFilterProvider);
    final query = ref.watch(billSearchQueryProvider);
    final repo = ref.read(billRepoProvider.notifier);

    // 搜索模式：实时过滤 + 平铺（不分组）；否则按月分组
    final List<_ListEntry> entries = _buildEntries(bills, filter, query);

    // 顶部"本月"汇总：始终用本月范围（不随筛选/搜索变化）
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(seconds: 1));
    final monthlySummary = repo.getSummary(start: monthStart, end: monthEnd);

    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(
        title: const Text('账单'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: '筛选',
            onPressed: () async {
              await context.push('/bills/filter');
            },
          ),
          PopupMenuButton<_MenuAction>(
            tooltip: '更多',
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (a) => _onMenuAction(a, entries),
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: _MenuAction.exportAll,
                child: Row(children: [
                  Icon(Icons.file_download_outlined, size: 18),
                  SizedBox(width: WxSpace.sm),
                  Text('导出全部为 CSV'),
                ]),
              ),
              PopupMenuItem(
                value: _MenuAction.stats,
                child: Row(children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 18),
                  SizedBox(width: WxSpace.sm),
                  Text('查看统计'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          _SearchBar(
            controller: _searchCtrl,
            active: _searchActive,
            onChanged: _onSearchChanged,
            onTap: _onTapSearch,
            onClear: _clearSearch,
          ),

          // 顶部汇总条（仅在非搜索时显示）
          if (query.trim().isEmpty) _SummaryBar(summary: monthlySummary),

          // 筛选条件 chip 行（仅在非默认筛选时显示）
          if (!_filterIsDefault(filter))
            _FilterChips(
              filter: filter,
              onClear: () =>
                  ref.read(billFilterProvider.notifier).state = const BillFilter(),
            ),

          // 主体列表
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: WxColors.green,
              child: entries.isEmpty
                  ? _buildEmpty()
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        for (final e in entries) ...[
                          if (e is _MonthHeaderEntry)
                            SliverPersistentHeader(
                              pinned: false,
                              delegate: _MonthHeaderDelegate(
                                title: e.title,
                                expense: e.expense,
                                income: e.income,
                              ),
                            ),
                          if (e is _BillEntry)
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) {
                                  if (i > 0) {
                                    return const _BillDivider();
                                  }
                                  return _BillTile(
                                    bill: e.bills[i],
                                    onTap: () => _onTapBill(e.bills[i]),
                                    onLongPress: () =>
                                        _onLongPressBill(e.bills[i]),
                                  );
                                },
                                childCount: e.bills.length,
                              ),
                            ),
                        ],
                        const SliverPadding(
                          padding: EdgeInsets.only(bottom: WxSpace.huge),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------

  List<_ListEntry> _buildEntries(
      List<Bill> bills, BillFilter filter, String query) {
    final repo = ref.read(billRepoProvider.notifier);
    if (query.trim().isNotEmpty) {
      // 搜索模式：平铺（按时间倒序已经在仓库里排好）
      final results = repo.searchBills(query);
      return [_BillEntry(bills: results)];
    }
    // 正常模式：按月分组
    final groups = repo.getMonthGroups(filter);
    return <_ListEntry>[
      for (final g in groups) ...[
        _MonthHeaderEntry(
          title: formatMonthTitle(g.month, now: DateTime.now()),
          expense: g.expense,
          income: g.income,
        ),
        _BillEntry(bills: g.bills),
      ],
    ];
  }

  bool _filterIsDefault(BillFilter f) => f.isEmpty;

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        _EmptyState(
          icon: Icons.receipt_long_outlined,
          title: '暂无账单',
          subtitle: '试试清除筛选条件，或导入微信账单',
        ),
      ],
    );
  }

  void _onTapBill(Bill b) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => BillDetailPage(billId: b.id),
      ),
    );
  }

  Future<void> _onLongPressBill(Bill b) async {
    HapticFeedback.mediumImpact();
    final action = await showModalBottomSheet<_BillAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BillActionSheet(bill: b),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _BillAction.delete:
        await _confirmDelete(b);
        break;
      case _BillAction.exportOne:
        await _exportCsv([b], sourceLabel: '这条账单');
        break;
    }
  }

  Future<void> _confirmDelete(Bill b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除这笔账单？'),
        content: Text(
            '${b.counterparty}  ¥${b.amount.toStringAsFixed(2)}\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: WxColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final success = ref.read(billRepoProvider.notifier).deleteBill(b.id);
    if (!mounted) return;
    _toast(success ? '已删除' : '删除失败：未找到该账单');
  }

  Future<void> _onMenuAction(_MenuAction action, List<_ListEntry> entries) async {
    switch (action) {
      case _MenuAction.exportAll:
        final all = ref.read(billRepoProvider);
        await _exportCsv(all, sourceLabel: '全部账单');
        break;
      case _MenuAction.stats:
        await context.push('/bills/stats');
        break;
    }
  }

  Future<void> _exportCsv(List<Bill> bills, {required String sourceLabel}) async {
    if (bills.isEmpty) {
      _toast('没有可导出的账单');
      return;
    }
    try {
      final csv = ref.read(billRepoProvider.notifier).exportToCsv(bills);
      // 加 UTF-8 BOM，Excel 中文不乱码
      final bytes = Uint8List.fromList(<int>[
        0xEF, 0xBB, 0xBF,
        ...utf8.encode(csv),
      ]);
      final now = DateTime.now();
      final fname = '微信账单_'
          '${now.year}-${_two(now.month)}-${_two(now.day)}'
          '_${_two(now.hour)}-${_two(now.minute)}.csv';
      // 写入 app 外部存储目录：/Android/data/<pkg>/files/Exports/
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        throw '无法获取外部存储目录';
      }
      final exportDir = Directory('${dir.path}/Exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final file = File('${exportDir.path}/$fname');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      _toast('已导出$sourceLabel（${bills.length} 条）\n${file.path}');
    } catch (e) {
      if (!mounted) return;
      _toast('导出失败：$e');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 80),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}

// =====================================================================
// 搜索栏
// =====================================================================

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool active;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.active,
    required this.onChanged,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WxSpace.lg, WxSpace.sm, WxSpace.lg, WxSpace.sm,
      ),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: WxColors.bgLight,
          borderRadius: BorderRadius.circular(WxRadius.lg),
        ),
        padding: const EdgeInsets.symmetric(horizontal: WxSpace.md),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: WxColors.textHint, size: 18),
            const SizedBox(width: WxSpace.sm),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onTap: onTap,
                style: const TextStyle(
                  fontSize: WxFontSize.body,
                  color: WxColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: '搜索账单（商家 / 金额 / 备注）',
                  hintStyle: TextStyle(
                    color: WxColors.textHint,
                    fontSize: WxFontSize.body,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (active || controller.text.isNotEmpty)
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: WxSpace.xs),
                  child: Icon(Icons.cancel_rounded,
                      color: WxColors.textHint, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 顶部汇总条
// =====================================================================

class _SummaryBar extends StatelessWidget {
  final BillSummary summary;
  const _SummaryBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        WxSpace.lg, 0, WxSpace.lg, WxSpace.sm,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: WxSpace.md, horizontal: WxSpace.lg,
      ),
      decoration: BoxDecoration(
        color: WxColors.card,
        borderRadius: BorderRadius.circular(WxRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              label: '本月支出',
              value: summary.totalExpense,
              color: WxColors.expense,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryCell(
              label: '本月收入',
              value: summary.totalIncome,
              color: WxColors.income,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryCell(
              label: '净支出',
              value: (summary.totalExpense - summary.totalIncome).abs(),
              color: WxColors.textPrimary,
              prefix: (summary.totalExpense - summary.totalIncome) >= 0
                  ? '-'
                  : '+',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String? prefix;
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: WxFontSize.small,
            color: WxColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${prefix ?? ''}¥${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: WxFontSize.titleLarge,
              color: color,
              fontWeight: WxFontWeight.semibold,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 28,
      color: WxColors.divider,
    );
  }
}

// =====================================================================
// 筛选条件 chip 行
// =====================================================================

class _FilterChips extends ConsumerWidget {
  final BillFilter filter;
  final VoidCallback onClear;
  const _FilterChips({required this.filter, required this.onClear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chips = <Widget>[];

    if (filter.direction != null) {
      chips.add(_chip(filter.direction!.label));
    }
    if (filter.type != null && filter.type!.isNotEmpty) {
      chips.add(_chip(filter.type!));
    }
    if (filter.startDate != null || filter.endDate != null) {
      final s = filter.startDate;
      final e = filter.endDate;
      final sStr = s == null ? '不限' : DateFormat('MM/dd').format(s);
      final eStr = e == null ? '不限' : DateFormat('MM/dd').format(e);
      chips.add(_chip('$sStr ~ $eStr'));
    }
    if (filter.minAmount != null || filter.maxAmount != null) {
      final lo = filter.minAmount?.toStringAsFixed(0) ?? '0';
      final hi = filter.maxAmount?.toStringAsFixed(0) ?? '∞';
      chips.add(_chip('¥$lo ~ ¥$hi'));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        WxSpace.lg, 0, WxSpace.lg, WxSpace.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in chips) ...[c, const SizedBox(width: WxSpace.sm)],
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: WxSpace.sm),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('清除筛选',
                style: TextStyle(
                  fontSize: WxFontSize.small,
                  color: WxColors.linkBlue,
                )),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: WxSpace.sm, vertical: 3),
      decoration: BoxDecoration(
        color: WxColors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(WxRadius.sm),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: WxFontSize.small,
          color: WxColors.green,
        ),
      ),
    );
  }
}

// =====================================================================
// 月份标题 + 列表项
// =====================================================================

class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final double expense;
  final double income;
  static const double _height = 36;
  const _MonthHeaderDelegate({
    required this.title,
    required this.expense,
    required this.income,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: _height,
      color: WxColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: WxSpace.lg),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: WxFontSize.body,
              color: WxColors.textSecondary,
              fontWeight: WxFontWeight.medium,
            ),
          ),
          const Spacer(),
          if (expense > 0)
            Text(
              '支出 ¥${expense.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: WxFontSize.small,
                color: WxColors.expense,
              ),
            ),
          if (income > 0 && expense > 0)
            const SizedBox(width: WxSpace.sm),
          if (income > 0)
            Text(
              '收入 ¥${income.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: WxFontSize.small,
                color: WxColors.income,
              ),
            ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => _height;
  @override
  double get minExtent => _height;
  @override
  bool shouldRebuild(_MonthHeaderDelegate old) {
    return old.title != title ||
        old.expense != expense ||
        old.income != income;
  }
}

class _BillTile extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _BillTile({
    required this.bill,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = bill.direction == BillDirection.income;
    final isNeutral = bill.direction == BillDirection.neutral;
    final amountColor = isIncome
        ? WxColors.income
        : (isNeutral ? WxColors.textPrimary : WxColors.expense);
    final amountPrefix = isIncome ? '+' : (isNeutral ? '' : '-');

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: WxColors.card,
        padding: const EdgeInsets.symmetric(
          horizontal: WxSpace.lg,
          vertical: WxSpace.md,
        ),
        child: Row(
          children: [
            // 左侧图标方块（按 category 简单配色）
            _CategoryIcon(category: bill.category),
            const SizedBox(width: WxSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bill.counterparty.isEmpty ? bill.type : bill.counterparty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: WxFontSize.bodyLarge,
                      color: WxColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(bill),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: WxFontSize.small,
                      color: WxColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: WxSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$amountPrefix¥${bill.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: WxFontSize.bodyLarge,
                    color: amountColor,
                    fontWeight: WxFontWeight.medium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(bill.transTime),
                  style: const TextStyle(
                    fontSize: WxFontSize.small,
                    color: WxColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(Bill b) {
    final parts = <String>[];
    if (b.product != null && b.product!.isNotEmpty) parts.add(b.product!);
    parts.add(b.type);
    if (b.status != '支付成功') parts.add(b.status);
    return parts.join(' · ');
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final isToday =
        t.year == now.year && t.month == now.month && t.day == now.day;
    if (isToday) {
      return '${_two(t.hour)}:${_two(t.minute)}';
    }
    return '${_two(t.month)}-${_two(t.day)} ${_two(t.hour)}:${_two(t.minute)}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}

class _CategoryIcon extends StatelessWidget {
  final String category;
  const _CategoryIcon({required this.category});

  static const Map<String, IconData> _iconMap = {
    '餐饮美食': Icons.restaurant_rounded,
    '交通出行': Icons.directions_car_filled_rounded,
    '购物消费': Icons.shopping_bag_rounded,
    '生活服务': Icons.home_rounded,
    '娱乐休闲': Icons.movie_rounded,
    '转账红包': Icons.card_giftcard_rounded,
    '退款退货': Icons.undo_rounded,
    '其他': Icons.receipt_long_rounded,
  };

  static const Map<String, Color> _colorMap = {
    '餐饮美食': Color(0xFFFF6B6B),
    '交通出行': Color(0xFF4D96FF),
    '购物消费': Color(0xFFFFB84D),
    '生活服务': Color(0xFF6BCB77),
    '娱乐休闲': Color(0xFF9D6BFF),
    '转账红包': Color(0xFFFF80AB),
    '退款退货': Color(0xFF00B8A9),
    '其他': Color(0xFF7F8C8D),
  };

  @override
  Widget build(BuildContext context) {
    final icon = _iconMap[category] ?? Icons.receipt_long_rounded;
    final color = _colorMap[category] ?? const Color(0xFF7F8C8D);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(WxRadius.md),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _BillDivider extends StatelessWidget {
  const _BillDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      padding: const EdgeInsets.only(left: WxSpace.lg + 40 + WxSpace.md),
      child: const Divider(
        height: 0.5,
        thickness: 0.5,
        color: WxColors.divider,
      ),
    );
  }
}

// =====================================================================
// 长按菜单
// =====================================================================

class _BillActionSheet extends StatelessWidget {
  final Bill bill;
  const _BillActionSheet({required this.bill});

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
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: WxSpace.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(WxRadius.md),
              ),
              child: Column(
                children: [
                  _SheetItem(
                    icon: Icons.delete_outline_rounded,
                    label: '删除',
                    color: WxColors.expense,
                    onTap: () => Navigator.pop(context, _BillAction.delete),
                  ),
                  const Divider(
                    height: 0.5, thickness: 0.5,
                    color: WxColors.divider,
                    indent: WxSpace.giant,
                  ),
                  _SheetItem(
                    icon: Icons.file_download_outlined,
                    label: '导出这一条',
                    color: WxColors.textPrimary,
                    onTap: () =>
                        Navigator.pop(context, _BillAction.exportOne),
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
                onPressed: () => Navigator.pop(context),
                child: const Text('取消',
                    style: TextStyle(
                      fontSize: WxFontSize.bodyLarge,
                      color: WxColors.textPrimary,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SheetItem({
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
          horizontal: WxSpace.lg, vertical: WxSpace.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: WxSpace.md),
            Text(label,
                style: TextStyle(
                  fontSize: WxFontSize.bodyLarge,
                  color: color,
                )),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 空状态
// =====================================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 80, color: WxColors.textHint),
          const SizedBox(height: WxSpace.lg),
          Text(title,
              style: const TextStyle(
                fontSize: WxFontSize.title,
                color: WxColors.textSecondary,
              )),
          const SizedBox(height: WxSpace.xs),
          Text(subtitle,
              style: const TextStyle(
                fontSize: WxFontSize.body,
                color: WxColors.textTertiary,
              )),
        ],
      ),
    );
  }
}

// =====================================================================
// 内部数据结构 + 枚举
// =====================================================================

sealed class _ListEntry {
  const _ListEntry();
}

class _MonthHeaderEntry extends _ListEntry {
  final String title;
  final double expense;
  final double income;
  const _MonthHeaderEntry({
    required this.title,
    required this.expense,
    required this.income,
  });
}

class _BillEntry extends _ListEntry {
  final List<Bill> bills;
  const _BillEntry({required this.bills});
}

enum _BillAction { delete, exportOne }

enum _MenuAction { exportAll, stats }
