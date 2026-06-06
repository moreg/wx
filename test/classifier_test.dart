// 分类器单元测试
//
// 覆盖：8 个一级分类各一个典型 case + 边界（空字段、未知类型）。
import 'package:flutter_test/flutter_test.dart';

import 'package:wx_clone/shared/classifier.dart';

void main() {
  group('BillClassifier', () {
    const c = BillClassifier();

    test('餐饮美食 — 星巴克 / 麦当劳 / 海底捞', () {
      expect(c.classify('商户消费', '星巴克', '拿铁'), '餐饮美食');
      expect(c.classify('商户消费', '麦当劳', '汉堡'), '餐饮美食');
      expect(c.classify('商户消费', '海底捞火锅', '晚餐'), '餐饮美食');
      expect(c.classify('商户消费', '瑞幸咖啡', ''), '餐饮美食');
    });

    test('交通出行 — 滴滴 / 地铁 / 加油', () {
      expect(c.classify('滴滴出行', '滴滴快车', ''), '交通出行');
      expect(c.classify('地铁', '深圳通', ''), '交通出行');
      expect(c.classify('商户消费', '中石化加油站', '加油'), '交通出行');
      expect(c.classify('商户消费', '美团单车', ''), '交通出行');
    });

    test('购物消费 — 淘宝 / 京东 / 优衣库', () {
      expect(c.classify('商户消费', '淘宝', '蓝牙耳机'), '购物消费');
      expect(c.classify('商户消费', '京东商城', '键盘'), '购物消费');
      expect(c.classify('商户消费', '优衣库', '夏季T恤'), '购物消费');
      expect(c.classify('商户消费', '盒马鲜生', '水果'), '购物消费');
    });

    test('生活服务 — 话费 / 酒店 / 健身', () {
      expect(c.classify('生活服务', '中国移动', '话费充值'), '生活服务');
      expect(c.classify('商户消费', '携程', '酒店预订'), '生活服务');
      expect(c.classify('商户消费', '超级猩猩', '健身课'), '生活服务');
    });

    test('娱乐休闲 — 腾讯视频 / Steam / 演唱会', () {
      expect(c.classify('娱乐休闲', '腾讯视频', '会员月卡'), '娱乐休闲');
      expect(c.classify('商户消费', 'Steam', '游戏充值'), '娱乐休闲');
      expect(c.classify('商户消费', 'B站', '大会员'), '娱乐休闲');
    });

    test('转账红包 — 转账 / 微信红包', () {
      expect(c.classify('转账', '朋友小张', ''), '转账红包');
      expect(c.classify('微信红包', '家庭群', '生日快乐'), '转账红包');
    });

    test('退款退货 — 优先于购物消费', () {
      // 微信"已退款"的状态会同时匹配 退款 / 购物消费；
      // 规则表把 退款退货 放在前面，所以应该归到 退款退货。
      expect(c.classify('商户消费', '优衣库', 'T恤退款'), '退款退货');
      expect(c.classify('退款', '京东', '耳机退货'), '退款退货');
    });

    test('其他 — 未知交易类型', () {
      expect(c.classify('未知类型', '神秘商家', '神秘商品'), '其他');
    });

    test('空字段不崩', () {
      expect(c.classify('', '', ''), '其他');
      expect(c.classify('商户消费', '', ''), '其他');
    });

    test('categories list 至少 8 项', () {
      expect(BillClassifier.categories.length, greaterThanOrEqualTo(8));
      expect(BillClassifier.categories, contains('餐饮美食'));
      expect(BillClassifier.categories, contains('交通出行'));
      expect(BillClassifier.categories, contains('购物消费'));
      expect(BillClassifier.categories, contains('生活服务'));
      expect(BillClassifier.categories, contains('娱乐休闲'));
      expect(BillClassifier.categories, contains('转账红包'));
      expect(BillClassifier.categories, contains('退款退货'));
      expect(BillClassifier.categories, contains('其他'));
    });
  });
}
