// 钱包页 — 完整静态 UI
//
// 1:1 复刻微信 iOS 钱包页：余额大数字 + 零钱通 + 银行卡 +
// 突出"账单"入口按钮（点击 → /bills，是核心账单页的入口）。
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(
        title: const Text('钱包'),
        centerTitle: true,
        actions: const <Widget>[
          Padding(
            padding: EdgeInsets.only(right: WxSpace.md),
            child: Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: ListView(
        children: const <Widget>[
          _BalanceHeader(),
          SizedBox(height: WxSpace.sm),
          _QuickActions(),
          SizedBox(height: WxSpace.sm),
          _BankCard(),
          SizedBox(height: WxSpace.sm),
          _BillEntry(),
          SizedBox(height: WxSpace.sm),
          _MiscList(),
          SizedBox(height: WxSpace.huge),
        ],
      ),
    );
  }
}

// =====================================================================
// 余额 header（绿色背景 + 大数字）
// =====================================================================

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      padding: const EdgeInsets.symmetric(
        horizontal: WxSpace.lg,
        vertical: WxSpace.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '总资产 (元)',
            style: TextStyle(
              fontSize: WxFontSize.body,
              color: WxColors.textSecondary,
            ),
          ),
          const SizedBox(height: WxSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '¥',
                  style: TextStyle(
                    fontSize: WxFontSize.titleLarge,
                    color: WxColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 4),
              Text(
                '8,888.88',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: WxFontWeight.medium,
                  color: WxColors.textPrimary,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: WxSpace.md),
          Row(
            children: <Widget>[
              _MiniStat(label: '零钱', value: '1,234.56'),
              const SizedBox(width: WxSpace.xl),
              _MiniStat(label: '零钱通', value: '5,654.32'),
              const SizedBox(width: WxSpace.xl),
              _MiniStat(label: '银行卡', value: '2,000.00'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: WxFontSize.small,
            color: WxColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: WxFontSize.body,
            color: WxColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// 快捷操作（充值 / 提现 / 转入 / 转出）
// =====================================================================

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const List<_Action> _actions = <_Action>[
    _Action(icon: Icons.add_circle_outline, label: '充值', color: WxColors.green),
    _Action(icon: Icons.arrow_upward, label: '提现', color: WxColors.linkBlue),
    _Action(icon: Icons.south_west, label: '转入', color: WxColors.warning),
    _Action(icon: Icons.north_east, label: '转出', color: WxColors.expense),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      padding: const EdgeInsets.symmetric(vertical: WxSpace.lg),
      child: Row(
        children: <Widget>[
          for (final a in _actions)
            Expanded(
              child: InkWell(
                onTap: () => _showToast(context, a.label),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(WxRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: Icon(a.icon, color: a.color, size: 20),
                    ),
                    const SizedBox(height: WxSpace.xs),
                    Text(
                      a.label,
                      style: const TextStyle(
                        fontSize: WxFontSize.small,
                        color: WxColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  const _Action({required this.icon, required this.label, required this.color});
}

// =====================================================================
// 银行卡（仅展示一张）
// =====================================================================

class _BankCard extends StatelessWidget {
  const _BankCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      child: InkWell(
        onTap: () => _showToast(context, '银行卡管理'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WxSpace.lg,
            vertical: WxSpace.md,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE64340).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(WxRadius.sm),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.credit_card,
                  color: Color(0xFFE64340),
                  size: 20,
                ),
              ),
              const SizedBox(width: WxSpace.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '招商银行 (1234)',
                      style: TextStyle(
                        fontSize: WxFontSize.bodyLarge,
                        color: WxColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '储蓄卡 · 余额 ¥ 2,000.00',
                      style: TextStyle(
                        fontSize: WxFontSize.small,
                        color: WxColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: WxColors.textHint,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// "账单" 入口（核心）
// =====================================================================

class _BillEntry extends StatelessWidget {
  const _BillEntry();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      child: InkWell(
        onTap: () => context.push('/bills'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WxSpace.lg,
            vertical: WxSpace.md,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: WxColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(WxRadius.sm),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.receipt_long,
                  color: WxColors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: WxSpace.md),
              const Expanded(
                child: Text(
                  '账单',
                  style: TextStyle(
                    fontSize: WxFontSize.bodyLarge,
                    color: WxColors.textPrimary,
                  ),
                ),
              ),
              const Text(
                '查看交易明细',
                style: TextStyle(
                  fontSize: WxFontSize.small,
                  color: WxColors.textSecondary,
                ),
              ),
              const SizedBox(width: WxSpace.xs),
              const Icon(
                Icons.chevron_right,
                color: WxColors.textHint,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// 其他列表（支付分 / 身份证 / 亲属卡）
// =====================================================================

class _MiscList extends StatelessWidget {
  const _MiscList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const <Widget>[
        _SimpleItem(icon: Icons.payments_outlined, label: '支付分'),
        Divider(height: 0.5, thickness: 0.5, color: WxColors.divider, indent: 56),
        _SimpleItem(icon: Icons.badge_outlined, label: '身份证'),
        Divider(height: 0.5, thickness: 0.5, color: WxColors.divider, indent: 56),
        _SimpleItem(icon: Icons.card_giftcard, label: '亲属卡'),
      ],
    );
  }
}

class _SimpleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SimpleItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      child: InkWell(
        onTap: () => _showToast(context, label),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WxSpace.lg,
              vertical: WxSpace.sm,
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: WxColors.textSecondary, size: 22),
                const SizedBox(width: WxSpace.md),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: WxFontSize.bodyLarge,
                      color: WxColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: WxColors.textHint,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
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
