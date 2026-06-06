// 联系人模型
//
// 通讯录页用的最小模型。pinyin / sortKey 用于字母索引排序。
// 静态装饰场景下不做加载/分页/搜索，直接 in-memory 列表即可。
class Contact {
  /// 唯一 ID（mock 数据用 'c001' 这种格式）
  final String id;

  /// 显示昵称（中文 / 英文 / 数字混合）
  final String name;

  /// 拼音 / 英文小写，用于排序
  final String pinyin;

  /// 索引字母（A-Z 或 #）
  final String sortKey;

  /// 头像资源路径
  final String avatar;

  /// 签名
  final String signature;

  /// 地区
  final String region;

  const Contact({
    required this.id,
    required this.name,
    required this.pinyin,
    required this.sortKey,
    required this.avatar,
    required this.signature,
    required this.region,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      pinyin: json['pinyin'] as String,
      sortKey: json['sortKey'] as String,
      avatar: json['avatar'] as String,
      signature: (json['signature'] as String?) ?? '',
      region: (json['region'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pinyin': pinyin,
    'sortKey': sortKey,
    'avatar': avatar,
    'signature': signature,
    'region': region,
  };

  @override
  String toString() => 'Contact($id, $name, $sortKey)';
}
