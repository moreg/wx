// 微信官方账单 CSV 解析器
//
// 微信支付导出的 CSV 大致结构（参考 PLAN.md §3）：
//   - UTF-8 BOM 编码
//   - 前 ~16 行为头部（"微信支付账单明细"、"---"、起止时间、导出时间等）
//   - 空行之后接数据表头：
//       交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,
//       当前状态,交易单号,商户单号,备注
//   - 数据行的"收/支"列："-"=支出、"+ "=收入、空白=中性
//   - amount 始终为正数，方向由 direction 列决定
//
// 解析策略（PLAN §3.2 / §7.3）：
//   1. 去除 UTF-8 BOM
//   2. 用 csv 库逐行解析
//   3. 跳过空行 / "---" 之类的分隔行
//   4. 找到含"交易时间"的行作为表头，索引各列
//   5. 数据行按列取值，构造 [ParsedBill]
//   6. 解析失败的行通过 [ParseResult.skipped] 收集，调用方可看
//
// 本解析器是纯函数：不依赖 Flutter、不依赖 Bill 模型，便于
// 在 [BillImportPage] 之外的脚本/测试里复用。
import 'package:csv/csv.dart';

import '../data/models/bill.dart';
import 'classifier.dart';

/// 收/支方向的原始表示。
///
/// 微信官方 CSV 的"收/支"列只用一个字符区分：
///   - `-`         → 支出
///   - `+` (可能带空格) → 收入
///   - 空白       → 中性（充值到零钱通等）
enum ParsedDirection { expense, income, neutral }

/// 解析后的账单（CSV 解析层的中间表示）。
///
/// 与 [Bill] 模型字段一一对应。transId/amount 严格按 CSV 原样
/// 解析后保留；[ParsedBill] 不做分类（分类交给 [BillClassifier]，
/// 在 [CsvToBillConverter] 里集中处理）。
class ParsedBill {
  final DateTime transTime;
  final String type;
  final String counterparty;
  final String? product;
  final ParsedDirection direction;
  final double amount;
  final String payMethod;
  final String status;
  final String transId;
  final String? merchantId;
  final String? remark;

  const ParsedBill({
    required this.transTime,
    required this.type,
    required this.counterparty,
    required this.product,
    required this.direction,
    required this.amount,
    required this.payMethod,
    required this.status,
    required this.transId,
    this.merchantId,
    this.remark,
  });
}

/// 单行解析失败时的描述（用于 UI 提示用户"跳过了 N 行"）。
class ParseError {
  final int rowIndex; // 0-based 数据行索引（不含表头）
  final String reason;
  const ParseError(this.rowIndex, this.reason);
  @override
  String toString() => 'row $rowIndex: $reason';
}

/// CSV 解析结果。
class ParseResult {
  final List<ParsedBill> bills;
  final List<ParseError> errors;

  const ParseResult({required this.bills, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
  int get parsedCount => bills.length;
  int get errorCount => errors.length;
}

/// 微信官方 CSV 解析器入口。
class WechatBillCsvParser {
  const WechatBillCsvParser();
  /// 微信官方表头"交易时间"——找到含它的行就开始解析。
  static const String headerTime = '交易时间';
  static const String headerType = '交易类型';
  static const String headerCounterparty = '交易对方';
  static const String headerProduct = '商品';
  static const String headerDirection = '收/支';
  static const String headerAmount = '金额(元)';
  static const String headerPayMethod = '支付方式';
  static const String headerStatus = '当前状态';
  static const String headerTransId = '交易单号';
  static const String headerMerchantId = '商户单号';
  static const String headerRemark = '备注';

  /// 解析微信账单 CSV 文本。
  ///
  /// [raw] 必须是已经按 UTF-8 解码后的字符串（带 BOM 也 OK，会自动剥）。
  /// 返回的 [ParseResult.bills] 中 amount 始终 ≥ 0；方向由
  /// [ParsedBill.direction] 决定。
  ParseResult parse(String raw) {
    // 1. 去 BOM
    var text = raw;
    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      text = text.substring(1);
    }

    // 2. 用 csv 解析（allowInvalid: true 兼容微信偶尔的脏数据）
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(text);

    if (rows.isEmpty) {
      return const ParseResult(bills: [], errors: []);
    }

    // 3. 找表头行
    int? headerRow;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final first = row.first.toString().trim();
      if (first == headerTime || first.contains(headerTime)) {
        headerRow = i;
        break;
      }
    }
    if (headerRow == null) {
      return const ParseResult(
        bills: [],
        errors: [ParseError(0, '未找到表头行（含"交易时间"）')],
      );
    }

    // 4. 索引各列
    final header = rows[headerRow].map((e) => e.toString().trim()).toList();
    int idxOf(String name) {
      for (var i = 0; i < header.length; i++) {
        if (header[i] == name || header[i].contains(name)) return i;
      }
      return -1;
    }

    final iTime = idxOf(headerTime);
    final iType = idxOf(headerType);
    final iCounterparty = idxOf(headerCounterparty);
    final iProduct = idxOf(headerProduct);
    final iDirection = idxOf(headerDirection);
    final iAmount = idxOf(headerAmount);
    final iPayMethod = idxOf(headerPayMethod);
    final iStatus = idxOf(headerStatus);
    final iTransId = idxOf(headerTransId);
    final iMerchantId = idxOf(headerMerchantId);
    final iRemark = idxOf(headerRemark);

    if (iTime < 0 || iAmount < 0 || iTransId < 0) {
      return ParseResult(
        bills: [],
        errors: [
          ParseError(
            headerRow,
            '表头缺少必要列：${[
              if (iTime < 0) headerTime,
              if (iAmount < 0) headerAmount,
              if (iTransId < 0) headerTransId,
            ].join(', ')}',
          ),
        ],
      );
    }

    // 5. 解析数据行
    final bills = <ParsedBill>[];
    final errors = <ParseError>[];
    for (var i = headerRow + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      // 跳过全空行 / 分隔行
      if (row.every((c) => c.toString().trim().isEmpty)) continue;
      // 防御：有些版本会在末尾追加统计行（如"总交易笔数"），首列非数字时间戳
      // 的直接忽略
      final firstCell = row[0].toString().trim();
      if (!_looksLikeDate(firstCell)) continue;

      try {
        final bill = _parseRow(
          row,
          iTime: iTime,
          iType: iType,
          iCounterparty: iCounterparty,
          iProduct: iProduct,
          iDirection: iDirection,
          iAmount: iAmount,
          iPayMethod: iPayMethod,
          iStatus: iStatus,
          iTransId: iTransId,
          iMerchantId: iMerchantId,
          iRemark: iRemark,
        );
        if (bill != null) bills.add(bill);
      } catch (e) {
        errors.add(ParseError(i - headerRow - 1, e.toString()));
      }
    }
    return ParseResult(bills: bills, errors: errors);
  }

  /// 解析单行数据。任一字段解析失败抛异常，由外层收集。
  ParsedBill? _parseRow(
    List<dynamic> row, {
    required int iTime,
    required int iType,
    required int iCounterparty,
    required int iProduct,
    required int iDirection,
    required int iAmount,
    required int iPayMethod,
    required int iStatus,
    required int iTransId,
    required int iMerchantId,
    required int iRemark,
  }) {
    final timeStr = _cell(row, iTime);
    final transTime = _parseTime(timeStr);
    if (transTime == null) return null;

    final transId = _cell(row, iTransId);
    if (transId.isEmpty) return null; // 没有 transId 视为无效

    final amountStr = _cell(row, iAmount);
    final amount = _parseAmount(amountStr);
    if (amount == null) {
      throw FormatException('金额无法解析: "$amountStr"');
    }

    return ParsedBill(
      transTime: transTime,
      type: iType >= 0 ? _cell(row, iType) : '其他',
      counterparty: iCounterparty >= 0 ? _cell(row, iCounterparty) : '',
      product: iProduct >= 0 ? _optCell(row, iProduct) : null,
      direction: _parseDirection(iDirection >= 0 ? _cell(row, iDirection) : ''),
      amount: amount.abs(), // 始终存正数
      payMethod: iPayMethod >= 0 ? _cell(row, iPayMethod) : '零钱',
      status: iStatus >= 0 ? _cell(row, iStatus) : '支付成功',
      transId: transId,
      merchantId: iMerchantId >= 0 ? _optCell(row, iMerchantId) : null,
      remark: iRemark >= 0 ? _optCell(row, iRemark) : null,
    );
  }

  // ----- helpers -----------------------------------------------------------

  String _cell(List<dynamic> row, int i) {
    if (i < 0 || i >= row.length) return '';
    return row[i].toString().trim();
  }

  String? _optCell(List<dynamic> row, int i) {
    final s = _cell(row, i);
    return s.isEmpty ? null : s;
  }

  /// 解析微信的时间格式：yyyy-MM-dd HH:mm:ss
  DateTime? _parseTime(String s) {
    if (s.isEmpty) return null;
    final t = s.trim();
    // 微信偶尔会给"2024-03-15 14:32:11"或 ISO；统一尝试
    final iso = DateTime.tryParse(t);
    if (iso != null) return iso;
    // 容错：替换空格为 T 再试
    final alt = t.contains(' ') && !t.contains('T')
        ? t.replaceFirst(' ', 'T')
        : t;
    return DateTime.tryParse(alt);
  }

  /// 解析金额：兼容 "38.00"、"¥38.00"、"38,000.00" 等。
  /// 返回 null 表示失败；返回正数（绝对值）。
  double? _parseAmount(String s) {
    if (s.isEmpty) return null;
    var t = s.trim();
    if (t.startsWith('¥') || t.startsWith('￥')) t = t.substring(1);
    // 去掉千分位逗号
    t = t.replaceAll(',', '');
    return double.tryParse(t);
  }

  /// 把微信"收/支"列原始字符解析成 [ParsedDirection]。
  ///   "-"        → expense
  ///   "+" / "+ " → income
  ///   空白/其他  → neutral
  ParsedDirection _parseDirection(String raw) {
    final t = raw.trim();
    if (t == '-') return ParsedDirection.expense;
    if (t == '+' || t == '+ ' || t.startsWith('+')) {
      return ParsedDirection.income;
    }
    return ParsedDirection.neutral;
  }

  /// 粗判：是不是 yyyy-MM-dd 开头（数据行首列特征）。
  bool _looksLikeDate(String s) {
    if (s.length < 10) return false;
    final seg = s.substring(0, 4);
    final n = int.tryParse(seg);
    if (n == null) return false;
    if (n < 1990 || n > 2100) return false;
    return s[4] == '-' || s[4] == '/' || s[4] == '.';
  }
}

/// 把 [ParsedBill] + 仓库已存在的 transIds 转换为 [Bill] 的工具。
///
/// 单独抽出来方便：导入页在 preview 时调一次（不写入仓库），
/// "确认导入"时再调一次写入；分类器注入后再做最终 category。
class CsvToBillConverter {
  final BillClassifier _classifier;
  const CsvToBillConverter(this._classifier);

  /// 把 [parsed] 转换为 [Bill]；category 由分类器决定。
  /// [existingTransIds] 用于去重；存在则返回 null（调用方跳过）。
  Bill? convert(
    ParsedBill parsed, {
    required Set<String> existingTransIds,
  }) {
    if (existingTransIds.contains(parsed.transId)) return null;
    final category = _classifier.classify(
      parsed.type,
      parsed.counterparty,
      parsed.product ?? '',
    );
    return Bill(
      id: parsed.transId, // 用 transId 做 ID（保持去重键一致）
      transTime: parsed.transTime,
      type: parsed.type,
      counterparty: parsed.counterparty,
      product: parsed.product,
      direction: _toDirection(parsed.direction),
      amount: parsed.amount,
      payMethod: parsed.payMethod,
      status: parsed.status,
      transId: parsed.transId,
      merchantId: parsed.merchantId,
      remark: parsed.remark,
      category: category,
    );
  }

  BillDirection _toDirection(ParsedDirection d) {
    switch (d) {
      case ParsedDirection.expense:
        return BillDirection.expense;
      case ParsedDirection.income:
        return BillDirection.income;
      case ParsedDirection.neutral:
        return BillDirection.neutral;
    }
  }
}
