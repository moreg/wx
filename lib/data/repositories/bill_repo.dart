// 账单仓库
//
// 单一数据源：内存中的 `List<Bill>`，初始从 `lib/data/mock/bills_seed.json`
// 加载。所有 UI 页面（列表/详情/筛选/导入/统计）都通过 Riverpod
// 的 `billRepoProvider` 读取同一份数据。
//
// Riverpod 选型说明：
//   - 用 `Notifier<List<Bill>>`（flutter_riverpod 2.x 新 API），
//     比 `StateNotifier` 更轻、API 更直接。
//   - 暴露的是同步 getter 和 List 的不可变副本，UI 用 ref.watch
//     自动 rebuild；写操作（add/delete）通过 `ref.read` 拿到
//     notifier 再调用。
//
// 重要方法：
//   - [BillRepository.getBills]        按时间倒序，过滤可选
//   - [BillRepository.getSummary]      月度/分类聚合
//   - [BillRepository.searchBills]     商家/金额/备注模糊匹配
//   - [BillRepository.addBill] / [deleteBill]   增删（transId 去重）
//   - [BillRepository.exportToCsv]     复刻微信官方 CSV 头
//
// 文件加载策略：
//   - lib/ 下的 JSON 在 Flutter 中无法直接 IO 读取（要 rootBundle），
//     所以这里把 JSON 复制成一份 dart 常量 (`billsSeed`)。
//     - 源文件 [lib/data/mock/bills_seed.json] 仍保留为人类可读
//       规范（方便 editor 校验 / 手动修改）。
//     - 后续如想换 rootBundle 加载，可把 `_kBillsSeedJson` 替换为
//       `rootBundle.loadString('assets/data/bills_seed.json')`。
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mock/bills_seed.dart';
import '../models/bill.dart';

/// Riverpod Provider：单例的 BillRepository。
final billRepoProvider = NotifierProvider<BillRepository, List<Bill>>(
  BillRepository.new,
);

/// Riverpod Provider：当前过滤条件。
///
/// 由 BillListPage / BillFilterPage 写入，BillRepository 读取后
/// 应用到 [getBills] / [getSummary]。
final billFilterProvider = StateProvider<BillFilter>((ref) => const BillFilter());

/// Riverpod Provider：当前搜索词（独立于筛选条件）。
final billSearchQueryProvider = StateProvider<String>((ref) => '');

class BillRepository extends Notifier<List<Bill>> {
  @override
  List<Bill> build() {
    // 初始化：把 mock seed 加载到内存。transId 重复时保留先出现的
    // （即保证 list 顺序 = json 顺序）。
    final seen = <String>{};
    final out = <Bill>[];
    for (final b in billsSeed) {
      if (b.transId.isEmpty) continue;
      if (seen.add(b.transId)) out.add(b);
    }
    // 按时间倒序
    out.sort((a, b) => b.transTime.compareTo(a.transTime));
    return List.unmodifiable(out);
  }

  // ---------------------------------------------------------------------
  // 读取
  // ---------------------------------------------------------------------

  /// 返回当前过滤条件下的所有账单，按时间倒序。
  ///
  /// [filter] 为 null 时返回全部；如果传入则按 [BillFilter] 字段
  /// 逐项匹配（null 字段不过滤）。
  List<Bill> getBills({BillFilter? filter}) {
    final f = filter;
    if (f == null || f.isEmpty) {
      return List.unmodifiable(state);
    }
    return state.where((b) => _matchFilter(b, f)).toList(growable: false);
  }

  /// 搜索：模糊匹配 商家/商品/备注/类型 + 金额（数字）。
  ///
  /// 匹配规则：
  ///   - 非数字片段：任一字段 [contains]（大小写不敏感）即命中
  ///   - 数字片段：amount 完全匹配（toStringAsFixed(2) 包含或 ==
  ///     整数时整数部分也命中）
  List<Bill> searchBills(String query) {
    final q = query.trim();
    if (q.isEmpty) return getBills();
    final lower = q.toLowerCase();
    final numPart = double.tryParse(q);

    return state.where((b) {
      // 数字匹配
      if (numPart != null) {
        // 允许输入 "38" 匹配 38.00，也允许 "38.5" 匹配 38.50
        if ((b.amount - numPart).abs() < 0.005) return true;
      }
      // 字符串包含匹配
      if (b.counterparty.toLowerCase().contains(lower)) return true;
      if ((b.product ?? '').toLowerCase().contains(lower)) return true;
      if ((b.remark ?? '').toLowerCase().contains(lower)) return true;
      if (b.type.toLowerCase().contains(lower)) return true;
      if (b.category.toLowerCase().contains(lower)) return true;
      return false;
    }).toList(growable: false);
  }

  /// 计算汇总。
  ///
  /// [dateRange] 可选：(start, end) 半开区间；不传则统计全量。
  /// 返回 [BillSummary]：总收支、笔数、按 category 聚合、月度趋势。
  BillSummary getSummary({DateTime? start, DateTime? end}) {
    final bills = state.where((b) {
      if (start != null && b.transTime.isBefore(start)) return false;
      if (end != null && !b.transTime.isBefore(end)) return false;
      return true;
    }).toList();

    double income = 0, expense = 0;
    final byCategory = <String, double>{};
    final byMonth = <String, _MonthAcc>{};

    for (final b in bills) {
      if (b.direction == BillDirection.income) {
        income += b.amount;
      } else if (b.direction == BillDirection.expense) {
        expense += b.amount;
        byCategory.update(b.category, (v) => v + b.amount, ifAbsent: () => b.amount);
      }
      final m = _monthKey(b.transTime);
      final acc = byMonth.putIfAbsent(m, _MonthAcc.new);
      if (b.direction == BillDirection.income) acc.income += b.amount;
      if (b.direction == BillDirection.expense) acc.expense += b.amount;
    }

    final months = byMonth.entries
        .map((e) => MonthlyStat(month: e.key, income: e.value.income, expense: e.value.expense))
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));

    return BillSummary(
      totalIncome: income,
      totalExpense: expense,
      billCount: bills.length,
      byCategory: Map.unmodifiable(byCategory),
      monthly: List.unmodifiable(months),
    );
  }

  /// 按月份分组账单，每组按日期降序。
  ///
  /// 用于 BillListPage 的 Sliver 列表渲染。返回 List<(monthLabel, bills)>。
  List<MonthGroup> getMonthGroups(BillFilter? filter) {
    final bills = getBills(filter: filter);
    final groups = <String, List<Bill>>{};
    final order = <String>[];
    for (final b in bills) {
      final key = _monthKey(b.transTime);
      if (!groups.containsKey(key)) {
        groups[key] = <Bill>[];
        order.add(key);
      }
      groups[key]!.add(b);
    }
    return order.map((k) {
      final list = groups[k]!;
      // 同一月份内按日期降序
      list.sort((a, b) => b.transTime.compareTo(a.transTime));
      return MonthGroup(month: k, bills: list);
    }).toList(growable: false);
  }

  /// 按 ID 取单条账单，找不到返回 null。
  Bill? findById(String id) {
    for (final b in state) {
      if (b.id == id || b.transId == id) return b;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // 写
  // ---------------------------------------------------------------------

  /// 新增账单。如果 transId 已存在则忽略（返回 false），不重复插入。
  bool addBill(Bill b) {
    if (state.any((x) => x.transId == b.transId)) return false;
    final next = [b, ...state]
      ..sort((a, b) => b.transTime.compareTo(a.transTime));
    state = List.unmodifiable(next);
    return true;
  }

  /// 删除单条账单。返回是否真的删除了（false = 找不到）。
  bool deleteBill(String id) {
    final next = state.where((b) => b.id != id && b.transId != id).toList();
    if (next.length == state.length) return false;
    state = List.unmodifiable(next);
    return true;
  }

  // ---------------------------------------------------------------------
  // 导出
  // ---------------------------------------------------------------------

  /// 把账单列表导出为微信官方格式的 CSV 字符串。
  ///
  /// 输出 schema（PLAN §3.1）：
  ///   交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
  /// 2024-03-15 14:32:11,商户消费,星巴克,咖啡,-,38.00,零钱,支付成功,100001,202403150001,
  String exportToCsv(List<Bill> bills) {
    final rows = <List<String>>[
      <String>[
        '交易时间',
        '交易类型',
        '交易对方',
        '商品',
        '收/支',
        '金额(元)',
        '支付方式',
        '当前状态',
        '交易单号',
        '商户单号',
        '备注',
      ],
      for (final b in bills) <String>[
        _formatCsvTime(b.transTime),
        b.type,
        b.counterparty,
        b.product ?? '',
        b.direction == BillDirection.income ? '+' : (b.direction == BillDirection.expense ? '-' : ''),
        b.amount.toStringAsFixed(2),
        b.payMethod,
        b.status,
        b.transId,
        b.merchantId ?? '',
        b.remark ?? '',
      ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  // ---------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------

  bool _matchFilter(Bill b, BillFilter f) {
    final s = f.startDate;
    final e = f.endDate;
    if (s != null && b.transTime.isBefore(s)) return false;
    if (e != null && b.transTime.isAfter(_endOfDay(e))) return false;
    if (f.direction != null && b.direction != f.direction) return false;
    if (f.type != null && f.type!.isNotEmpty && b.type != f.type) return false;
    if (f.minAmount != null && b.amount < f.minAmount!) return false;
    if (f.maxAmount != null && b.amount > f.maxAmount!) return false;
    return true;
  }

  static String _monthKey(DateTime t) {
    final m = t.month.toString().padLeft(2, '0');
    return '${t.year}-$m';
  }

  /// `endDate` 默认按当天的最后一刻处理，避免截止当天 0 点就被截掉。
  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static String _formatCsvTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}

class _MonthAcc {
  double income = 0;
  double expense = 0;
}

/// 给 UI 用的「月份 + 该月账单列表」组。
class MonthGroup {
  final String month; // "2024-03"
  final List<Bill> bills;
  const MonthGroup({required this.month, required this.bills});

  double get income =>
      bills.where((b) => b.direction == BillDirection.income).fold(0.0, (a, b) => a + b.amount);
  double get expense =>
      bills.where((b) => b.direction == BillDirection.expense).fold(0.0, (a, b) => a + b.amount);
}

/// 给 UI 显示用的月份标题，例如 "2024年3月" / "本月"。
String formatMonthTitle(String monthKey, {DateTime? now}) {
  final parts = monthKey.split('-');
  if (parts.length != 2) return monthKey;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (y == null || m == null) return monthKey;
  final n = now ?? DateTime.now();
  if (y == n.year && m == n.month) return '本月';
  return '$y年$m月';
}

/// 备注：如果将来要从 assets/data 加载，调用方用这个静态方法。
/// 当前实现直接返回 dart 常量（与 bills_seed.json 内容一致）。
Future<List<Bill>> loadBillsFromAssets() async {
  try {
    final raw = await rootBundle.loadString('assets/data/bills_seed.json');
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Bill.fromJson).toList(growable: false);
  } catch (_) {
    // assets 加载失败时退回 dart 常量
    return billsSeed;
  }
}
