// 账单数据模型
//
// 定义 Bill 实体、BillDirection 枚举以及仓库返回的聚合结构
// (BillSummary / MonthlyStat)。同时定义 BillFilter —— 列表/搜索/
// 筛选页共用的过滤条件。所有字段尽量保持 immutable，并提供
// fromJson/toJson 以便 [BillRepository] 加载 mock JSON 和导出。
//
// 字段定义严格对齐 PLAN §5.1。`amount` 始终为正数，方向由
// `direction` 决定 —— 这与微信官方 CSV 的"-"号惯例保持一致，
// 避免 UI 端重复处理符号。
enum BillDirection {
  /// 支出
  expense,

  /// 收入
  income,

  /// 中性（充值到零钱通等不计收支）
  neutral;

  /// 从 CSV 的 "收/支" 列字符串解析（"收入" / "支出" / "其他"）。
  static BillDirection parse(String raw) {
    final t = raw.trim();
    if (t.contains('收') || t.toLowerCase() == 'income') {
      return BillDirection.income;
    }
    if (t.contains('支') || t.toLowerCase() == 'expense') {
      return BillDirection.expense;
    }
    return BillDirection.neutral;
  }

  String get label {
    switch (this) {
      case BillDirection.expense:
        return '支出';
      case BillDirection.income:
        return '收入';
      case BillDirection.neutral:
        return '其他';
    }
  }
}

class Bill {
  /// 唯一 ID（默认就是 transId，去重键）。
  final String id;

  /// 交易时间。
  final DateTime transTime;

  /// 交易类型原始字符串（如 "商户消费"、"转账"、"微信红包"）。
  final String type;

  /// 交易对方。
  final String counterparty;

  /// 商品（可空）。
  final String? product;

  /// 收/支方向。
  final BillDirection direction;

  /// 金额（始终为正数，方向由 [direction] 决定）。
  final double amount;

  /// 支付方式（如 "零钱"、"招商银行(1234)"）。
  final String payMethod;

  /// 当前状态（如 "支付成功"、"已退款"）。
  final String status;

  /// 交易单号（去重 key）。
  final String transId;

  /// 商户单号（可空）。
  final String? merchantId;

  /// 备注（可空）。
  final String? remark;

  /// 自动归类（一级分类：餐饮美食 / 交通出行 / ...）。
  final String category;

  const Bill({
    required this.id,
    required this.transTime,
    required this.type,
    required this.counterparty,
    required this.direction,
    required this.amount,
    required this.payMethod,
    required this.status,
    required this.transId,
    required this.category,
    this.product,
    this.merchantId,
    this.remark,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String? ?? (json['transId'] as String? ?? ''),
      transTime: DateTime.parse(json['transTime'] as String),
      type: json['type'] as String? ?? '其他',
      counterparty: json['counterparty'] as String? ?? '',
      product: json['product'] as String?,
      direction: BillDirection.parse(json['direction'] as String? ?? ''),
      amount: (json['amount'] as num).toDouble(),
      payMethod: json['payMethod'] as String? ?? '零钱',
      status: json['status'] as String? ?? '支付成功',
      transId: json['transId'] as String? ?? '',
      merchantId: json['merchantId'] as String?,
      remark: json['remark'] as String?,
      category: json['category'] as String? ?? '其他',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'transTime': transTime.toIso8601String(),
    'type': type,
    'counterparty': counterparty,
    'product': product,
    'direction': direction.label,
    'amount': amount,
    'payMethod': payMethod,
    'status': status,
    'transId': transId,
    'merchantId': merchantId,
    'remark': remark,
    'category': category,
  };

  /// 带 +/- 符号的金额字符串（用于 UI 直接显示）。
  String get signedAmount {
    final sign = direction == BillDirection.income ? '+' : '-';
    return '$sign¥${amount.toStringAsFixed(2)}';
  }

  Bill copyWith({DateTime? transTime, BillDirection? direction, double? amount, String? status, String? remark, String? category}) {
    return Bill(
      id: id,
      transTime: transTime ?? this.transTime,
      type: type,
      counterparty: counterparty,
      product: product,
      direction: direction ?? this.direction,
      amount: amount ?? this.amount,
      payMethod: payMethod,
      status: status ?? this.status,
      transId: transId,
      merchantId: merchantId,
      remark: remark ?? this.remark,
      category: category ?? this.category,
    );
  }
}

/// 月度统计项（统计页/汇总条用）。
class MonthlyStat {
  final String month; // "2024-03"
  final double income;
  final double expense;
  const MonthlyStat({
    required this.month,
    required this.income,
    required this.expense,
  });
}

/// 账单汇总（用于列表页顶部汇总条和统计页）。
class BillSummary {
  final double totalIncome;
  final double totalExpense;
  final int billCount;
  final Map<String, double> byCategory; // category -> 金额（仅支出）
  final List<MonthlyStat> monthly;

  const BillSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.billCount,
    required this.byCategory,
    required this.monthly,
  });

  double get netExpense => totalExpense - totalIncome;

  static const empty = BillSummary(
    totalIncome: 0,
    totalExpense: 0,
    billCount: 0,
    byCategory: {},
    monthly: [],
  );
}

/// 列表/搜索/筛选的过滤条件。
///
/// 所有字段都 optional：null 表示该项不过滤。组合使用：
///   getBills(filter: BillFilter(...))
class BillFilter {
  /// 起始时间（含）。
  final DateTime? startDate;

  /// 结束时间（含）。
  final DateTime? endDate;

  /// 收/支过滤（null = 不过滤）。
  final BillDirection? direction;

  /// 交易类型过滤（如 "商户消费" / "转账"）。
  final String? type;

  /// 最小金额（含）。
  final double? minAmount;

  /// 最大金额（含）。
  final double? maxAmount;

  const BillFilter({
    this.startDate,
    this.endDate,
    this.direction,
    this.type,
    this.minAmount,
    this.maxAmount,
  });

  bool get isEmpty =>
      startDate == null &&
      endDate == null &&
      direction == null &&
      type == null &&
      minAmount == null &&
      maxAmount == null;

  BillFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    BillDirection? direction,
    String? type,
    double? minAmount,
    double? maxAmount,
    bool clearType = false,
    bool clearDirection = false,
    bool clearStart = false,
    bool clearEnd = false,
  }) {
    return BillFilter(
      startDate: clearStart ? null : (startDate ?? this.startDate),
      endDate: clearEnd ? null : (endDate ?? this.endDate),
      direction: clearDirection ? null : (direction ?? this.direction),
      type: clearType ? null : (type ?? this.type),
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }
}
