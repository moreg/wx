// 账单分类器
//
// 把交易按 type / counterparty / product 自动归到 8 个一级分类：
//   餐饮美食 / 交通出行 / 购物消费 / 生活服务 / 娱乐休闲 /
//   转账红包 / 退款退货 / 其他
//
// 实现是关键词规则（PLAN §3.3）：每个分类一组关键词，先匹配
// 交易类型（最粗粒度），再匹配交易对方，最后匹配商品。
// 都没命中 → "其他"。
//
// 规则集合放在 [BillClassifier._rules]（private），需要扩展时
// 改这里即可；调用方不感知。
//
// 入口：[BillClassifier.classify] —— 纯函数，无状态、可复用。
class BillClassifier {
  const BillClassifier();

  /// 主入口：把一笔交易归到一级分类。
  ///
  /// 三个参数都允许为空字符串（解析失败的字段）。空字段会被
  /// 跳过但不会让分类器返回 null。
  String classify(String type, String counterparty, String product) {
    final fields = <String>[
      type,
      counterparty,
      product,
    ].where((s) => s.trim().isNotEmpty).map((s) => s.trim()).toList();

    for (final rule in _rules) {
      if (rule.matches(fields)) return rule.category;
    }
    return '其他';
  }

  /// 所有一级分类（用于 UI 选项 / 饼图配色稳定）。
  static const List<String> categories = <String>[
    '餐饮美食',
    '交通出行',
    '购物消费',
    '生活服务',
    '娱乐休闲',
    '转账红包',
    '退款退货',
    '其他',
  ];

  // ----- 规则表 -------------------------------------------------------------
  // 顺序敏感：先匹配更细粒度的分类（如"退款退货"放在"购物消费"之前，
  // 因为"已退款"的商户消费同时命中两者；"转账红包"放在"生活服务"
  // 之前，因为微信红包 type 可能落在"商户消费"模糊匹配上）。
  static final List<_Rule> _rules = <_Rule>[
    // 1. 退款退货（最优先 —— 微信退款的状态是"已退款"）
    const _Rule(
      category: '退款退货',
      keywords: <String>[
        '退款', '退货', '已退款', '已退货', '充值退款', '商户退款',
      ],
    ),

    // 2. 转账红包
    const _Rule(
      category: '转账红包',
      keywords: <String>[
        '转账', '微信红包', '红包', '群红包', 'AA 收款', 'AA收款',
      ],
    ),

    // 3. 交通出行
    const _Rule(
      category: '交通出行',
      keywords: <String>[
        // 关键词（同时匹配 type / counterparty / product）
        '滴滴', '嘀嗒', '曹操', 'T3 出行', 'T3出行', '花小猪',
        '高德打车', '出租车', '网约车', '快车', '专车', '顺风车',
        '地铁', '公交', '巴士', '一卡通', '深圳通', '羊城通',
        '加油', '中石化', '中石油', '壳牌', 'BP', '道达尔',
        '停车', '停车费', '高速', 'ETC', '高铁', '12306', '铁路',
        '航空', '机票', '航班', '机场',
        '共享单车', '美团单车', '哈啰', '青桔',
      ],
    ),

    // 4. 餐饮美食
    const _Rule(
      category: '餐饮美食',
      keywords: <String>[
        '星巴克', '麦当劳', '肯德基', 'KFC', '汉堡王', '必胜客',
        '海底捞', '呷哺', '西贝', '外婆家', '绿茶', '南京大牌档',
        '瑞幸', 'luckin', '喜茶', '奈雪', 'CoCo', '一点点', '蜜雪冰城',
        '美团外卖', '饿了么', '口碑', '大众点评', '外卖',
        '咖啡', '奶茶', '烘焙', '面包', '蛋糕', '甜品',
        '餐厅', '餐馆', '食堂', '快餐', '面馆', '饺子', '小吃',
        '火锅', '烧烤', '麻辣烫', '冒菜', '烤鱼', '寿司', '拉面',
      ],
    ),

    // 5. 购物消费
    const _Rule(
      category: '购物消费',
      keywords: <String>[
        '淘宝', '天猫', '京东', '拼多多', '苏宁', '国美', '唯品会',
        '得物', '小红书', '网易严选', '小米有品', '小米商城',
        '华为商城', 'Apple Store', 'App Store', 'iCloud',
        '屈臣氏', '丝芙兰', 'Sephora', '雅诗兰黛', '兰蔻',
        '优衣库', 'UNIQLO', 'ZARA', 'H&M', 'MUJI', '无印良品',
        'Nike', 'Adidas', '亚瑟士', '新百伦',
        '沃尔玛', '山姆', 'Costco', '家乐福', '永辉', '盒马',
        '7-Eleven', '7-11', '罗森', '全家', '便利店',
        '商场', '百货', '超市',
      ],
    ),

    // 6. 生活服务
    const _Rule(
      category: '生活服务',
      keywords: <String>[
        '话费', '流量', '宽带', '电信', '联通', '移动',
        '水费', '电费', '燃气', '物业', '房租', '租金',
        '社保', '医保', '公积金',
        '医院', '诊所', '药店', '老百姓大药房', '益丰大药房',
        '美团到店', '美团团购', '美团酒店', '美团民宿',
        '携程', '飞猪', '去哪儿', '同程', '艺龙', 'Booking',
        '酒店', '民宿', '客栈', '公寓',
        '洗车', '保养', '修车', '4S 店', '4S店',
        '理发', '美容', '美甲', '美睫', 'SPA',
        '健身', '瑜伽', '游泳馆',
        '学习', '培训', '网课', '课程', '学费', '教材',
      ],
    ),

    // 7. 娱乐休闲
    const _Rule(
      category: '娱乐休闲',
      keywords: <String>[
        '腾讯视频', '爱奇艺', '优酷', 'B 站', 'B站', 'bilibili',
        '网易云', 'QQ 音乐', 'QQ音乐', '虾米', 'Spotify',
        '游戏', 'Steam', 'PlayStation', 'Xbox', 'Nintendo',
        '王者', '和平精英', '原神', '英雄联盟', 'LOL',
        '网吧', '网咖',
        'KTV', '唱吧', '桌游', '密室', '剧本杀',
        '电影', '影院', '万达影城', '横店影视',
        '演唱会', '话剧', '音乐节', '展览',
      ],
    ),
  ];
}

/// 单条分类规则：包含若干关键词（任一命中即匹配）。
class _Rule {
  final String category;
  final List<String> keywords;

  const _Rule({required this.category, required this.keywords});

  /// 三个字段里任一含任一关键词即视为命中。
  bool matches(List<String> fields) {
    for (final f in fields) {
      for (final kw in keywords) {
        if (f.contains(kw)) return true;
      }
    }
    return false;
  }
}
