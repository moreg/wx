// 服务页（Pay / Services）
//
// 1:1 复刻微信"服务"页：顶部绿色卡片（收付款 + 钱包）+ 4 个分组宫格
// （金融理财 / 生活服务 / 交通出行 / 购物消费）。
//
// 图标全用 SVG（currentColor 染色），不用 Material Icons。
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';

class PayPage extends StatelessWidget {
  const PayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: WxColors.textPrimary),
          onPressed: () => context.pop(),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: const <Widget>[
          _TopGreenCard(),
          SizedBox(height: 12),
          _ServiceGroup(
            title: '金融理财',
            items: [
              _PayItem(iconPath: 'assets/icons/credit-card.svg', label: '信用卡还款', color: WxColors.green),
              // 理财通：真版品牌 PNG
              _PayItem(iconPath: 'assets/icons/licaigon-logo.png', label: '理财通'),
              _PayItem(iconPath: 'assets/icons/insurance.svg', label: '保险服务', color: WxColors.payOrange),
            ],
          ),
          SizedBox(height: 12),
          _ServiceGroup(
            title: '生活服务',
            items: [
              _PayItem(iconPath: 'assets/icons/phone-recharge.svg', label: '手机充值'),
              _PayItem(iconPath: 'assets/icons/living-pay.svg', label: '生活缴费', color: WxColors.green),
              // Q币充值：真版 QQ 企鹅
              _PayItem(iconPath: 'assets/icons/qcoin.svg', label: 'Q币充值', color: WxColors.payBlue),
              _PayItem(iconPath: 'assets/icons/city.svg', label: '城市服务', color: WxColors.green),
              _PayItem(iconPath: 'assets/icons/charity.png', label: '腾讯公益'),
              _PayItem(iconPath: 'assets/icons/health.svg', label: '医疗健康', color: WxColors.payOrange),
            ],
          ),
          SizedBox(height: 12),
          _ServiceGroup(
            title: '交通出行',
            items: [
              _PayItem(iconPath: 'assets/icons/bus.svg', label: '出行服务'),
              _PayItem(iconPath: 'assets/icons/flight.svg', label: '火车票机票'),
              // 滴滴：真版品牌 PNG
              _PayItem(iconPath: 'assets/icons/didi.svg', label: '滴滴出行'),
              _PayItem(iconPath: 'assets/icons/hotel.svg', label: '酒店民宿'),
            ],
          ),
          SizedBox(height: 12),
          _ServiceGroup(
            title: '购物消费',
            items: [
              _PayItem(iconPath: 'assets/icons/jd-logo.svg', label: '京东购物'),
              // 美团：真版品牌 SVG
              _PayItem(iconPath: 'assets/icons/meituan-logo.svg', label: '美团外卖'),
              _PayItem(iconPath: 'assets/icons/brand-discover.svg', label: '品牌发现'),
              _PayItem(iconPath: 'assets/icons/movie.svg', label: '电影演出玩乐'),
            ],
          ),
          SizedBox(height: WxSpace.huge),
        ],
      ),
    );
  }
}

class _PayItem {
  final String iconPath;
  final String label;
  final Color? color;  // PNG（真版品牌）时不染色，传 null
  const _PayItem({
    required this.iconPath,
    required this.label,
    this.color,
  });
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
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('收付款 TODO'))),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // 收付款：真版品牌 PNG（设计用于绿色背景的白色图标）
                      Image.asset(
                        'assets/icons/receive-pay.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '收付款',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => context.push('/wallet'),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SvgPicture.asset(
                        'assets/icons/wallet-outlined.svg',
                        width: 32,
                        height: 32,
                        theme: const SvgTheme(currentColor: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '钱包',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '¥0.00',
                        style: TextStyle(
                          fontFamily: 'WeChatNum',
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                color: Color(0xFF333333),
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
      children: [
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

  /// 渲染图标：SVG 用 SvgPicture + 染色，PNG 用 Image + 原色
  Widget _buildIcon(_PayItem it) {
    final path = it.iconPath;
    final isSvg = path.toLowerCase().endsWith('.svg');
    if (isSvg) {
      return SvgPicture.asset(
        path,
        width: 28,
        height: 28,
        theme: it.color != null
            ? SvgTheme(currentColor: it.color!)
            : null,
      );
    } else {
      final double size = it.label == '腾讯公益' ? 38 : 28;
      return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
    }
  }

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
            _buildIcon(it),
            const SizedBox(height: 8),
            Text(
              it.label,
              style: const TextStyle(
                fontSize: 12,
                color: WxColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
