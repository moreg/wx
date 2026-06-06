import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';

class PayPage extends StatelessWidget {
  const PayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(
        title: const Text('服务', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
        centerTitle: true,
        backgroundColor: WxColors.bg,
        elevation: 0,
        actions: const <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        children: const <Widget>[
          _TopGreenCard(),
          SizedBox(height: 12),
          _ServiceGroup(
            title: '金融理财',
            items: [
              _PayItem(icon: Icons.credit_card, label: '信用卡还款', color: WxColors.green),
              _PayItem(icon: Icons.savings_outlined, label: '理财通', color: WxColors.payBlue),
              _PayItem(icon: Icons.health_and_safety_outlined, label: '保险服务', color: WxColors.payOrange),
            ],
          ),
          SizedBox(height: 12),
          _ServiceGroup(
            title: '生活服务',
            items: [
              _PayItem(icon: Icons.phone_android, label: '手机充值', color: WxColors.payBlue),
              _PayItem(icon: Icons.water_drop_outlined, label: '生活缴费', color: WxColors.green),
              _PayItem(icon: Icons.monetization_on_outlined, label: 'Q币充值', color: WxColors.payBlue),
              _PayItem(icon: Icons.location_city_outlined, label: '城市服务', color: WxColors.green),
              _PayItem(icon: Icons.volunteer_activism_outlined, label: '腾讯公益', color: WxColors.payRed),
              _PayItem(icon: Icons.medical_services_outlined, label: '医疗健康', color: WxColors.payOrange),
            ],
          ),
          SizedBox(height: 12),
          _ServiceGroup(
            title: '交通出行',
            items: [
              _PayItem(icon: Icons.directions_bus_outlined, label: '出行服务', color: WxColors.payBlue),
              _PayItem(icon: Icons.flight_takeoff, label: '火车票机票', color: WxColors.green),
              _PayItem(icon: Icons.local_taxi_outlined, label: '滴滴出行', color: WxColors.payOrange),
              _PayItem(icon: Icons.hotel_outlined, label: '酒店民宿', color: WxColors.green),
            ],
          ),
          SizedBox(height: 12),
          _ServiceGroup(
            title: '购物消费',
            items: [
              _PayItem(icon: Icons.shopping_bag_outlined, label: '京东购物', color: WxColors.payRed),
              _PayItem(icon: Icons.fastfood_outlined, label: '美团外卖', color: WxColors.payOrange),
              _PayItem(icon: Icons.movie_outlined, label: '电影演出', color: WxColors.payRed),
            ],
          ),
          SizedBox(height: WxSpace.huge),
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
// 顶部绿色卡片（收付款 / 钱包）
// =====================================================================

class _TopGreenCard extends StatelessWidget {
  const _TopGreenCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WxColors.payGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('收付款 TODO'))),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.qr_code_scanner, color: Colors.white, size: 36),
                      SizedBox(height: 12),
                      Text(
                        '收付款',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 0.5,
              margin: const EdgeInsets.symmetric(vertical: 24),
              color: Colors.white.withOpacity(0.3),
            ),
            Expanded(
              child: InkWell(
                onTap: () => context.push('/wallet'),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 36),
                      SizedBox(height: 12),
                      Text(
                        '钱包',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '¥0.74',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 带标题的宫格服务组
// =====================================================================

class _ServiceGroup extends StatelessWidget {
  final String title;
  final List<_PayItem> items;
  const _ServiceGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: WxColors.textSecondary,
              ),
            ),
          ),
          _PayGrid(items: items, columns: 4),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// =====================================================================
// 宫格组件
// =====================================================================

class _PayGrid extends StatelessWidget {
  final List<_PayItem> items;
  final int columns;
  const _PayGrid({required this.items, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int row = 0; row < (items.length / columns).ceil(); row++)
          Row(
            children: <Widget>[
              for (int col = 0; col < columns; col++) ...<Widget>[
                Expanded(
                  child: _PayCell(
                    item: row * columns + col < items.length
                        ? items[row * columns + col]
                        : null,
                  ),
                ),
              ],
            ],
          ),
      ],
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${it.label} - TODO'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(it.icon, color: it.color, size: 28),
            const SizedBox(height: 12),
            Text(
              it.label,
              style: const TextStyle(
                fontSize: 13,
                color: WxColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
