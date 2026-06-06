// 支付/服务 — 完整静态 UI
//
// 1:1 复刻微信 iOS 支付/服务页：4 列宫格 × 4 行 = 16 项，
// 含金融（钱包、信用卡还款）、生活（生活缴费、医疗、腾讯服务等）。
//
// 宫格之间用 0.5px 分割线分组（每行 4 列用竖线，行间用横线）。
// 顶部留一个"我的钱包"突出入口（点击 → /wallet）。
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';

class PayPage extends StatelessWidget {
  const PayPage({super.key});

  static const List<_PayItem> _topItems = <_PayItem>[
    _PayItem(icon: Icons.account_balance_wallet_outlined, label: '收付款', color: Color(0xFF07C160)),
    _PayItem(icon: Icons.account_balance_wallet, label: '钱包', color: Color(0xFF576B95)),
    _PayItem(icon: Icons.credit_card, label: '信用卡还款', color: Color(0xFFE64340)),
    _PayItem(icon: Icons.savings_outlined, label: '理财通', color: Color(0xFFFA9D3B)),
  ];

  static const List<_PayItem> _bottomItems = <_PayItem>[
    _PayItem(icon: Icons.water_drop_outlined, label: '生活缴费', color: Color(0xFF4DCDB6)),
    _PayItem(icon: Icons.local_hospital_outlined, label: '医疗健康', color: Color(0xFFE64340)),
    _PayItem(icon: Icons.movie_outlined, label: '电影演出', color: Color(0xFFFA9D3B)),
    _PayItem(icon: Icons.directions_bus_outlined, label: '出行服务', color: Color(0xFF576B95)),
    _PayItem(icon: Icons.house_outlined, label: '腾讯服务', color: Color(0xFF07C160)),
    _PayItem(icon: Icons.phone_iphone, label: '手机充值', color: Color(0xFFB37FE6)),
    _PayItem(icon: Icons.devices_other, label: '数码电器', color: Color(0xFF66CCFF)),
    _PayItem(icon: Icons.card_giftcard, label: '微信礼物', color: Color(0xFFE6739C)),
    _PayItem(icon: Icons.local_offer_outlined, label: '信用卡', color: Color(0xFFFA9D3B)),
    _PayItem(icon: Icons.school_outlined, label: '教育公益', color: Color(0xFF07C160)),
    _PayItem(icon: Icons.work_outline, label: '企业微信', color: Color(0xFF576B95)),
    _PayItem(icon: Icons.more_horiz, label: '更多服务', color: Color(0xFF888888)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(
        title: const Text('支付'),
        centerTitle: true,
        actions: const <Widget>[
          Padding(
            padding: EdgeInsets.only(right: WxSpace.md),
            child: Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          // 顶部余额卡片（点击进入 /wallet）
          const _BalanceCard(),
          const SizedBox(height: WxSpace.sm),
          // 4 列宫格
          _PayGrid(items: _topItems, columns: 4),
          const SizedBox(height: WxSpace.sm),
          // 4 列宫格（更多服务）
          _PayGrid(items: _bottomItems, columns: 4),
          const SizedBox(height: WxSpace.sm),
          // 帮助中心
          const _PayListItem(
            icon: Icons.help_outline,
            iconColor: WxColors.textSecondary,
            label: '帮助中心',
          ),
          _PayListItem(
            icon: Icons.chat_bubble_outline,
            iconColor: WxColors.green,
            label: '客户咨询',
            showArrow: true,
          ),
          const SizedBox(height: WxSpace.huge),
        ],
      ),
    );
  }
}

class _PayItem {
  final IconData icon;
  final String label;
  final Color color;
  const _PayItem({required this.icon, required this.label, required this.color});
}

// =====================================================================
// 顶部余额卡片（点击进入钱包）
// =====================================================================

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      child: InkWell(
        onTap: () => context.push('/wallet'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WxSpace.lg,
            vertical: WxSpace.lg,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: WxColors.green,
                  borderRadius: BorderRadius.circular(WxRadius.sm),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: WxSpace.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '钱包',
                      style: TextStyle(
                        fontSize: WxFontSize.bodyLarge,
                        color: WxColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '查看余额、零钱、银行卡',
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
// 4 列宫格
// =====================================================================

class _PayGrid extends StatelessWidget {
  final List<_PayItem> items;
  final int columns;
  const _PayGrid({required this.items, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      padding: const EdgeInsets.symmetric(vertical: WxSpace.md),
      child: Column(
        children: <Widget>[
          for (int row = 0; row < (items.length / columns).ceil(); row++)
            IntrinsicHeight(
              child: Row(
                children: <Widget>[
                  for (int col = 0; col < columns; col++) ...<Widget>[
                    Expanded(
                      child: _PayCell(
                        item: row * columns + col < items.length
                            ? items[row * columns + col]
                            : null,
                      ),
                    ),
                    if (col < columns - 1)
                      const VerticalDivider(
                        width: 0.5,
                        thickness: 0.5,
                        color: WxColors.divider,
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PayCell extends StatelessWidget {
  final _PayItem? item;
  const _PayCell({this.item});

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return const SizedBox(height: 80);
    }
    final it = item!;
    return InkWell(
      onTap: () {
        if (it.label == '钱包') {
          context.push('/wallet');
          return;
        }
        _showToast(context, it.label);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: WxSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: it.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(WxRadius.md),
              ),
              alignment: Alignment.center,
              child: Icon(it.icon, color: it.color, size: 22),
            ),
            const SizedBox(height: WxSpace.xs),
            Text(
              it.label,
              style: const TextStyle(
                fontSize: WxFontSize.small,
                color: WxColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 底部列表项
// =====================================================================

class _PayListItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool showArrow;
  const _PayListItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      child: SizedBox(
        height: 56,
        child: InkWell(
          onTap: () => _showToast(context, label),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WxSpace.lg,
              vertical: WxSpace.sm,
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: iconColor, size: 22),
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
                if (showArrow)
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
