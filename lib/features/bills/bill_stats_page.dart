// 账单统计页 (S13)
//
// 显示 4 种时间范围内（近 3 月 / 近 6 月 / 近 1 年 / 全部）的：
//   1. 顶部汇总条：本月总支出 / 总收入 / 净支出
//   2. 月度趋势折线图（双线：收入绿 / 支出红，X 轴为月份）
//   3. 分类饼图（按 category 聚合支出，Top 8 + "其他"）
//
// 数据源：BillRepository.getSummary({start, end})，未硬编码。
// 状态管理：flutter_riverpod 2.x。bills 列表变化（导入/删除）时
// 自动 rebuild。
//
// 参考 PLAN §7.5。
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../data/models/bill.dart';
import '../../data/repositories/bill_repo.dart';

class BillStatsPage extends ConsumerStatefulWidget {
  const BillStatsPage({super.key});

  @override
  ConsumerState<BillStatsPage> createState() => _BillStatsPageState();
}

class _BillStatsPageState extends ConsumerState<BillStatsPage> {
  // 默认近 3 月 —— 微信账单真实用户的常见选择。
  _TimeRange _range = _TimeRange.threeMonths;

  @override
  Widget build(BuildContext context) {
    // watch bills 列表：导入/删除时触发本 widget rebuild
    ref.watch(billRepoProvider);
    final repo = ref.read(billRepoProvider.notifier);

    final (start, end) = _range.resolve(now: DateTime.now());
    final summary = repo.getSummary(start: start, end: end);

    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(
        title: const Text('账单统计'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          WxSpace.lg,
          WxSpace.md,
          WxSpace.lg,
          WxSpace.xxl,
        ),
        children: [
          _TimeRangeFilterBar(
            current: _range,
            onChanged: (r) => setState(() => _range = r),
          ),
          const SizedBox(height: WxSpace.lg),
          _SummaryCard(
            range: _range,
            summary: summary,
          ),
          const SizedBox(height: WxSpace.lg),
          _TrendChartCard(summary: summary),
          const SizedBox(height: WxSpace.lg),
          _CategoryPieCard(summary: summary),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 时间范围
// -----------------------------------------------------------------------------

enum _TimeRange {
  threeMonths('近 3 月'),
  sixMonths('近 6 月'),
  oneYear('近 1 年'),
  all('全部');

  const _TimeRange(this.label);
  final String label;

  /// 根据所选范围计算 (start, end)。"all" 时 start = null。
  (DateTime?, DateTime?) resolve({required DateTime now}) {
    switch (this) {
      case _TimeRange.threeMonths:
        return (_addMonths(now, -3), now);
      case _TimeRange.sixMonths:
        return (_addMonths(now, -6), now);
      case _TimeRange.oneYear:
        return (_addMonths(now, -12), now);
      case _TimeRange.all:
        return (null, null);
    }
  }

  static DateTime _addMonths(DateTime t, int delta) {
    final y = t.year * 12 + (t.month - 1) + delta;
    final newMonth = (y % 12) + 1;
    final newYear = y ~/ 12;
    return DateTime(newYear, newMonth, t.day, t.hour, t.minute, t.second);
  }
}

// -----------------------------------------------------------------------------
// 时间筛选条
// -----------------------------------------------------------------------------

class _TimeRangeFilterBar extends StatelessWidget {
  const _TimeRangeFilterBar({required this.current, required this.onChanged});
  final _TimeRange current;
  final ValueChanged<_TimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final r in _TimeRange.values)
            Padding(
              padding: const EdgeInsets.only(right: WxSpace.sm),
              child: _RangeChip(
                label: r.label,
                selected: r == current,
                onTap: () => onChanged(r),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? WxColors.green : WxColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WxRadius.round),
        side: BorderSide(
          color: selected ? WxColors.green : WxColors.divider,
          width: 0.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(WxRadius.round),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WxSpace.lg,
            vertical: WxSpace.sm,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: WxFontSize.body,
              color: selected ? WxColors.textOnGreen : WxColors.textPrimary,
              fontWeight:
                  selected ? WxFontWeight.medium : WxFontWeight.regular,
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 顶部汇总条
// -----------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.range, required this.summary});
  final _TimeRange range;
  final BillSummary summary;

  @override
  Widget build(BuildContext context) {
    final net = summary.totalExpense - summary.totalIncome;
    return Container(
      decoration: BoxDecoration(
        color: WxColors.card,
        borderRadius: BorderRadius.circular(WxRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: WxElevation.md,
            offset: Offset(0, WxElevation.sm),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        vertical: WxSpace.lg,
        horizontal: WxSpace.md,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: WxSpace.sm),
            child: Row(
              children: [
                Text(
                  '${range.label}总览',
                  style: const TextStyle(
                    fontSize: WxFontSize.body,
                    color: WxColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '共 ${summary.billCount} 笔',
                  style: const TextStyle(
                    fontSize: WxFontSize.small,
                    color: WxColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WxSpace.md),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: '总支出',
                  value: summary.totalExpense,
                  valueColor: WxColors.expense,
                ),
              ),
              Container(
                width: 0.5,
                height: 40,
                color: WxColors.divider,
              ),
              Expanded(
                child: _SummaryItem(
                  label: '总收入',
                  value: summary.totalIncome,
                  valueColor: WxColors.income,
                ),
              ),
              Container(
                width: 0.5,
                height: 40,
                color: WxColors.divider,
              ),
              Expanded(
                child: _SummaryItem(
                  label: '净支出',
                  value: net,
                  valueColor: WxColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final String label;
  final double value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: WxFontSize.small,
            color: WxColors.textSecondary,
          ),
        ),
        const SizedBox(height: WxSpace.xs),
        Text(
          '¥${_formatMoney(value)}',
          style: TextStyle(
            fontSize: WxFontSize.title,
            fontWeight: WxFontWeight.semibold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  static String _formatMoney(double v) {
    if (v.abs() >= 10000) {
      return NumberFormat('#,##0.00').format(v);
    }
    return NumberFormat('#,##0.00').format(v);
  }
}

// -----------------------------------------------------------------------------
// 月度趋势折线图
// -----------------------------------------------------------------------------

class _TrendChartCard extends StatelessWidget {
  const _TrendChartCard({required this.summary});
  final BillSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WxColors.card,
        borderRadius: BorderRadius.circular(WxRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: WxElevation.md,
            offset: Offset(0, WxElevation.sm),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        WxSpace.lg,
        WxSpace.lg,
        WxSpace.lg,
        WxSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '月度趋势',
            style: TextStyle(
              fontSize: WxFontSize.title,
              fontWeight: WxFontWeight.medium,
              color: WxColors.textPrimary,
            ),
          ),
          const SizedBox(height: WxSpace.xs),
          Row(
            children: [
              _LegendDot(color: WxColors.income, label: '收入'),
              const SizedBox(width: WxSpace.lg),
              _LegendDot(color: WxColors.expense, label: '支出'),
            ],
          ),
          const SizedBox(height: WxSpace.lg),
          SizedBox(
            height: 220,
            child: summary.monthly.isEmpty
                ? const _EmptyChartHint(text: '当前范围内暂无数据')
                : LineChart(_buildLineChartData(summary.monthly)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(List<MonthlyStat> monthly) {
    // 收入（绿）+ 支出（红）双线
    final incomeSpots = <FlSpot>[
      for (int i = 0; i < monthly.length; i++)
        FlSpot(i.toDouble(), monthly[i].income),
    ];
    final expenseSpots = <FlSpot>[
      for (int i = 0; i < monthly.length; i++)
        FlSpot(i.toDouble(), monthly[i].expense),
    ];

    // Y 轴上限：取两线最大值的 1.2 倍，留点余量
    double maxV = 0;
    for (final m in monthly) {
      if (m.income > maxV) maxV = m.income;
      if (m.expense > maxV) maxV = m.expense;
    }
    if (maxV == 0) maxV = 100;
    final maxY = maxV * 1.2;
    final minX = 0.0;
    final maxX = (monthly.length - 1).toDouble().clamp(0.0, double.infinity);

    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (_) => const FlLine(
          color: WxColors.dividerLight,
          strokeWidth: 0.5,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= monthly.length) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(
                  _monthShortLabel(monthly[i].month),
                  style: const TextStyle(
                    fontSize: WxFontSize.small,
                    color: WxColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: maxY / 4,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(
                  _yAxisLabel(value),
                  style: const TextStyle(
                    fontSize: WxFontSize.small,
                    color: WxColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => WxColors.textPrimary.withValues(alpha: 0.85),
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final m = monthly[spot.x.toInt()];
              final isIncome = spot.barIndex == 0;
              return LineTooltipItem(
                '${m.month}\n${isIncome ? "收入" : "支出"} ¥${_money(spot.y)}',
                const TextStyle(
                  color: WxColors.textOnGreen,
                  fontSize: WxFontSize.small,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: incomeSpots,
          isCurved: true,
          color: WxColors.income,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
              radius: 3,
              color: WxColors.income,
              strokeWidth: 1.5,
              strokeColor: WxColors.card,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: WxColors.income.withValues(alpha: 0.08),
          ),
        ),
        LineChartBarData(
          spots: expenseSpots,
          isCurved: true,
          color: WxColors.expense,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
              radius: 3,
              color: WxColors.expense,
              strokeWidth: 1.5,
              strokeColor: WxColors.card,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: WxColors.expense.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  static String _monthShortLabel(String yyyymm) {
    // yyyymm = "2024-03"
    final m = yyyymm.split('-');
    if (m.length != 2) return yyyymm;
    final mm = int.tryParse(m[1]);
    if (mm == null) return yyyymm;
    return '$mm月';
  }

  static String _yAxisLabel(double v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}万';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  static String _money(double v) => NumberFormat('#,##0.00').format(v);
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: WxSpace.xs),
        Text(
          label,
          style: const TextStyle(
            fontSize: WxFontSize.small,
            color: WxColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _EmptyChartHint extends StatelessWidget {
  const _EmptyChartHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: WxFontSize.body,
          color: WxColors.textTertiary,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 分类饼图
// -----------------------------------------------------------------------------

class _CategoryPieCard extends StatelessWidget {
  const _CategoryPieCard({required this.summary});
  final BillSummary summary;

  /// 分类调色板（与 50 条 mock 的 category 取值一致）。
  /// 若出现"其他"（>=9 个分类 / Top 8 之外），会复用末尾的灰色。
  static const _palette = <String, Color>{
    '餐饮美食': Color(0xFFFF8A65),
    '交通出行': Color(0xFF42A5F5),
    '购物消费': Color(0xFFEC407A),
    '生活服务': Color(0xFF26A69A),
    '娱乐休闲': Color(0xFFAB47BC),
    '转账红包': Color(0xFFFFCA28),
    '退款退货': Color(0xFF66BB6A),
    '其他': Color(0xFF78909C),
  };

  static const _otherColor = Color(0xFFB0BEC5);

  @override
  Widget build(BuildContext context) {
    final total = summary.byCategory.values.fold<double>(0, (a, b) => a + b);
    final entries = summary.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top 8 + 其他
    final top = entries.take(8).toList();
    final rest = entries.skip(8).toList();
    final restSum = rest.fold<double>(0, (a, e) => a + e.value);
    final hasOther = restSum > 0;

    final slices = <_PieSlice>[
      for (final e in top) _PieSlice(name: e.key, value: e.value, color: _colorFor(e.key)),
      if (hasOther) _PieSlice(name: '其他', value: restSum, color: _otherColor),
    ];

    return Container(
      decoration: BoxDecoration(
        color: WxColors.card,
        borderRadius: BorderRadius.circular(WxRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: WxElevation.md,
            offset: Offset(0, WxElevation.sm),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        WxSpace.lg,
        WxSpace.lg,
        WxSpace.lg,
        WxSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '分类占比（支出）',
            style: TextStyle(
              fontSize: WxFontSize.title,
              fontWeight: WxFontWeight.medium,
              color: WxColors.textPrimary,
            ),
          ),
          const SizedBox(height: WxSpace.sm),
          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: WxSpace.xxl),
              child: Center(
                child: Text(
                  '当前范围内暂无支出',
                  style: TextStyle(
                    fontSize: WxFontSize.body,
                    color: WxColors.textTertiary,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.6,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: _buildSections(slices, total),
                    ),
                  ),
                ),
                const SizedBox(height: WxSpace.lg),
                _LegendGrid(slices: slices, total: total),
              ],
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<_PieSlice> slices,
    double total,
  ) {
    return [
      for (int i = 0; i < slices.length; i++)
        PieChartSectionData(
          value: slices[i].value,
          color: slices[i].color,
          title: '${(slices[i].value / total * 100).toStringAsFixed(0)}%',
          radius: 56,
          titleStyle: const TextStyle(
            fontSize: WxFontSize.small,
            color: WxColors.textOnGreen,
            fontWeight: WxFontWeight.medium,
          ),
        ),
    ];
  }

  static Color _colorFor(String category) =>
      _palette[category] ?? _otherColor;
}

class _PieSlice {
  const _PieSlice({required this.name, required this.value, required this.color});
  final String name;
  final double value;
  final Color color;
}

class _LegendGrid extends StatelessWidget {
  const _LegendGrid({required this.slices, required this.total});
  final List<_PieSlice> slices;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: WxSpace.sm,
      spacing: WxSpace.lg,
      children: [
        for (final s in slices)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: s.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: WxSpace.xs),
              Text(
                '${s.name} ',
                style: const TextStyle(
                  fontSize: WxFontSize.small,
                  color: WxColors.textPrimary,
                ),
              ),
              Text(
                '¥${NumberFormat('#,##0.00').format(s.value)}',
                style: const TextStyle(
                  fontSize: WxFontSize.small,
                  color: WxColors.textSecondary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
