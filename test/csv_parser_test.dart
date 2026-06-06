// CSV 解析器单元测试
//
// 覆盖：正常 CSV / 缺列 / 空行 / BOM 四种典型场景。
// 加上"模拟微信官方格式"的真实数据测试（用字符串拼，不读 asset）。
import 'package:flutter_test/flutter_test.dart';

import 'package:wx_clone/shared/csv_parser.dart';

void main() {
  group('WechatBillCsvParser', () {
    final parser = const WechatBillCsvParser();

    test('parses a normal CSV with header and 3 rows', () {
      const raw = '''
微信支付账单明细
---
起始时间:[2024-06-01 00:00:00]
截止时间:[2024-06-30 23:59:59]
---
导出时间:[2024-07-01 10:30:00]
---

交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
2024-06-30 19:32:11,商户消费,星巴克,拿铁,-,38.00,零钱,支付成功,T001,M001,
2024-06-30 12:15:22,商户消费,海底捞,家庭聚餐,-,268.00,招商银行(5678),支付成功,T002,M002,周末
2024-06-29 09:08:00,商户消费,瑞幸,美式,-,19.90,零钱,支付成功,T003,M003,
''';
      final result = parser.parse(raw);
      expect(result.parsedCount, 3);
      expect(result.hasErrors, isFalse);

      final b0 = result.bills[0];
      expect(b0.type, '商户消费');
      expect(b0.counterparty, '星巴克');
      expect(b0.product, '拿铁');
      expect(b0.direction, ParsedDirection.expense);
      expect(b0.amount, 38.00);
      expect(b0.payMethod, '零钱');
      expect(b0.transId, 'T001');
    });

    test('strips UTF-8 BOM', () {
      const raw = '\uFEFF交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注\n'
          '2024-06-30 19:32:11,商户消费,星巴克,咖啡,-,38.00,零钱,支付成功,T001,M001,\n';
      final result = parser.parse(raw);
      expect(result.parsedCount, 1);
      expect(result.bills.first.counterparty, '星巴克');
    });

    test('parses + direction as income', () {
      const raw = '''
交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
2024-06-30 19:32:11,退款,优衣库,T恤退款,+ ,199.00,招商银行(5678),已退款,T001,M001,尺码不对
''';
      final result = parser.parse(raw);
      expect(result.parsedCount, 1);
      expect(result.bills.first.direction, ParsedDirection.income);
      expect(result.bills.first.amount, 199.00);
    });

    test('treats blank direction as neutral', () {
      const raw = '''
交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
2024-06-30 19:32:11,充值,零钱通,充值,,100.00,招商银行(1234),充值成功,T001,M001,
''';
      final result = parser.parse(raw);
      expect(result.parsedCount, 1);
      expect(result.bills.first.direction, ParsedDirection.neutral);
    });

    test('skips empty / separator rows', () {
      const raw = '''
交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注

2024-06-30 19:32:11,商户消费,星巴克,咖啡,-,38.00,零钱,支付成功,T001,M001,

2024-06-30 19:32:11,商户消费,瑞幸,咖啡,-,22.00,零钱,支付成功,T002,M002,
''';
      final result = parser.parse(raw);
      expect(result.parsedCount, 2);
    });

    test('skips non-date rows (e.g. footer "总交易笔数")', () {
      const raw = '''
交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
2024-06-30 19:32:11,商户消费,星巴克,咖啡,-,38.00,零钱,支付成功,T001,M001,
总交易笔数:1,总支出金额:38.00,,
''';
      final result = parser.parse(raw);
      expect(result.parsedCount, 1);
    });

    test('returns error when header row is missing', () {
      const raw = 'some,random,csv,with,no,header\n1,2,3,4,5,6,7,8,9,10,11\n';
      final result = parser.parse(raw);
      expect(result.parsedCount, 0);
      expect(result.hasErrors, isTrue);
      expect(result.errors.first.reason, contains('表头'));
    });

    test('returns 0 bills and no error for empty input', () {
      final result = parser.parse('');
      expect(result.parsedCount, 0);
      expect(result.hasErrors, isFalse);
    });

    test('amount is always positive regardless of sign in CSV', () {
      // 微信偶尔导出时会在金额前带负号；解析器仍返回正值
      const raw = '''
交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
2024-06-30 19:32:11,商户消费,星巴克,咖啡,-,-38.00,零钱,支付成功,T001,M001,
''';
      final result = parser.parse(raw);
      expect(result.parsedCount, 1);
      expect(result.bills.first.amount, 38.00);
      expect(result.bills.first.direction, ParsedDirection.expense);
    });

    test('parses currency-prefixed amount (¥38.00)', () {
      const raw = '''
交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
2024-06-30 19:32:11,商户消费,星巴克,咖啡,-,¥38.00,零钱,支付成功,T001,M001,
''';
      final result = parser.parse(raw);
      expect(result.parsedCount, 1);
      expect(result.bills.first.amount, 38.00);
    });
  });
}
