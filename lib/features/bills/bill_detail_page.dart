// 账单详情页 (S12)
//
// 从 BillListPage 跳入，展示单笔账单的完整字段。
// 全部字段对齐 PLAN §5.1 / §3.1：交易时间、类型、对方、商品、收/支、
// 金额、支付方式、状态、交易单号、商户单号、备注、分类。
//
// 数据来源：通过 [billRepoProvider] 找到对应 ID 的 Bill。
// 找不到时显示空状态，避免 ID 错配时崩溃。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../data/models/bill.dart';
import '../../data/repositories/bill_repo.dart';

class BillDetailPage extends ConsumerWidget {
  final String billId;
  const BillDetailPage({super.key, required this.billId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billRepoProvider);
    final bill = bills.firstWhere(
      (b) => b.id == billId || b.transId == billId,
      orElse: () => _MissingBill.instance,
    );

    if (bill is _MissingBill) {
      return Scaffold(
        appBar: AppBar(title: const Text('账单详情')),
        body: const Center(
          child: Text('未找到该账单（可能已被删除）',
              style: TextStyle(
                color: WxColors.textSecondary,
                fontSize: WxFontSize.body,
              )),
        ),
      );
    }

    final isIncome = bill.direction == BillDirection.income;
    final isNeutral = bill.direction == BillDirection.neutral;
    final amountColor = isIncome
        ? WxColors.income
        : (isNeutral ? WxColors.textPrimary : WxColors.expense);
    final amountPrefix = isIncome ? '+' : (isNeutral ? '' : '-');

    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(
        title: const Text('账单详情'),
        actions: [
          IconButton(
            tooltip: '复制交易单号',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: bill.transId));
              if (!context.mounted) return;
              _toast(context, '已复制交易单号');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(WxSpace.lg),
        children: [
          // 顶部大金额卡
          Container(
            padding: const EdgeInsets.symmetric(vertical: WxSpace.xxl),
            decoration: BoxDecoration(
              color: WxColors.card,
              borderRadius: BorderRadius.circular(WxRadius.lg),
            ),
            child: Column(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: amountColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(WxRadius.round),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _iconForCategory(bill.category),
                    color: amountColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: WxSpace.md),
                Text(
                  bill.counterparty.isEmpty ? bill.type : bill.counterparty,
                  style: const TextStyle(
                    fontSize: WxFontSize.titleLarge,
                    color: WxColors.textPrimary,
                    fontWeight: WxFontWeight.medium,
                  ),
                ),
                const SizedBox(height: WxSpace.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$amountPrefix¥${bill.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: WxFontSize.huge + 4,
                      color: amountColor,
                      fontWeight: WxFontWeight.semibold,
                    ),
                  ),
                ),
                const SizedBox(height: WxSpace.xs),
                Text(
                  bill.direction.label,
                  style: const TextStyle(
                    fontSize: WxFontSize.small,
                    color: WxColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: WxSpace.lg),

          // 字段列表
          _DetailCard(children: [
            _DetailRow(label: '交易时间', value: _formatFullTime(bill.transTime)),
            _DetailRow(label: '交易类型', value: bill.type),
            _DetailRow(label: '交易对方', value: bill.counterparty),
            if (bill.product != null && bill.product!.isNotEmpty)
              _DetailRow(label: '商品', value: bill.product!),
            _DetailRow(label: '收/支', value: bill.direction.label),
            _DetailRow(label: '金额', value: '¥${bill.amount.toStringAsFixed(2)}'),
            _DetailRow(label: '支付方式', value: bill.payMethod),
            _DetailRow(label: '当前状态', value: bill.status),
            _DetailRow(label: '交易分类', value: bill.category),
            _DetailRow(
              label: '交易单号',
              value: bill.transId,
              copyValue: bill.transId,
            ),
            if (bill.merchantId != null && bill.merchantId!.isNotEmpty)
              _DetailRow(
                label: '商户单号',
                value: bill.merchantId!,
                copyValue: bill.merchantId,
              ),
            if (bill.remark != null && bill.remark!.isNotEmpty)
              _DetailRow(label: '备注', value: bill.remark!),
          ]),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 80),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  static String _formatFullTime(DateTime t) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(t);
  }

  static IconData _iconForCategory(String category) {
    switch (category) {
      case '餐饮美食':
        return Icons.restaurant_rounded;
      case '交通出行':
        return Icons.directions_car_filled_rounded;
      case '购物消费':
        return Icons.shopping_bag_rounded;
      case '生活服务':
        return Icons.home_rounded;
      case '娱乐休闲':
        return Icons.movie_rounded;
      case '转账红包':
        return Icons.card_giftcard_rounded;
      case '退款退货':
        return Icons.undo_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

/// 用作 firstWhere 的 orElse 占位。
class _MissingBill extends Bill {
  _MissingBill._()
    : super(
        id: '',
        transTime: DateTime.fromMillisecondsSinceEpoch(0),
        type: '',
        counterparty: '',
        direction: BillDirection.neutral,
        amount: 0,
        payMethod: '',
        status: '',
        transId: '',
        category: '其他',
      );
  static final _MissingBill instance = _MissingBill._();
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(const Divider(
          height: 0.5, thickness: 0.5,
          color: WxColors.divider,
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: WxColors.card,
        borderRadius: BorderRadius.circular(WxRadius.lg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String? copyValue;
  const _DetailRow({
    required this.label,
    required this.value,
    this.copyValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WxSpace.lg, vertical: WxSpace.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: WxFontSize.body,
                color: WxColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: WxFontSize.body,
                color: WxColors.textPrimary,
              ),
            ),
          ),
          if (copyValue != null)
            IconButton(
              tooltip: '复制',
              icon: const Icon(Icons.copy_rounded,
                  size: 18, color: WxColors.textHint),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: copyValue!));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('已复制 $label'),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                      duration: const Duration(seconds: 2),
                    ),
                  );
              },
            ),
        ],
      ),
    );
  }
}
