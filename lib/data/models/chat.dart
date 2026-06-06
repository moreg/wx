// 聊天会话模型
//
// 1 个 Chat 对应微信"微信" Tab 里的一行（不是单条消息）。
// 涵盖 4 种会话类型：单聊、群聊、公众号、服务号、工具号。
// 头像/昵称/最后一条消息/未读数/置顶/免打扰 —— 列表渲染所需的全部字段。
//
// 消息内容本身不放在这里，按 chatId 拆到
// `lib/data/mock/messages/<chatId>.json`，由 ChatRepository 懒加载。

enum ChatType {
  /// 单聊
  single,
  /// 群聊
  group,
  /// 公众号 / 订阅号
  official,
  /// 服务号
  service,
  /// 系统工具号（文件传输助手、腾讯新闻等）
  tool,
}

class Chat {
  final String id;
  final String name;
  final String avatar; // 资源路径；占位用 avatar_<n>.png
  final ChatType type;

  /// 最近一条消息的纯文本预览（用于列表里"XX: ..."那一行的右侧文案）
  final String lastMessagePreview;
  final DateTime lastMessageTime;

  /// 0 表示无未读
  final int unreadCount;

  /// 置顶 / 免打扰 —— 列表里展示用的状态位
  final bool pinned;
  final bool muted;

  /// 是否在主框架聊天 Tab 的"标星"分组显示（公众号 / 服务号通常为 true）
  final bool starred;

  /// 单聊 / 群聊可能需要的扩展字段（昵称、群成员、公告摘要等）
  /// 仅 type==group 时为群公告；其他类型可能为一句话描述
  final String? description;

  /// 单聊/工具号置灰
  final bool greyed;

  const Chat({
    required this.id,
    required this.name,
    required this.avatar,
    required this.type,
    required this.lastMessagePreview,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.pinned,
    required this.muted,
    this.starred = false,
    this.description,
    this.greyed = false,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      type: _chatTypeFromString(json['type'] as String),
      lastMessagePreview: json['lastMessagePreview'] as String,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      pinned: json['pinned'] as bool? ?? false,
      muted: json['muted'] as bool? ?? false,
      starred: json['starred'] as bool? ?? false,
      description: json['description'] as String?,
      greyed: json['greyed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'type': _chatTypeToString(type),
    'lastMessagePreview': lastMessagePreview,
    'lastMessageTime': lastMessageTime.toIso8601String(),
    'unreadCount': unreadCount,
    'pinned': pinned,
    'muted': muted,
    'starred': starred,
    'description': description,
    'greyed': greyed,
  };
}

ChatType _chatTypeFromString(String s) {
  switch (s) {
    case 'single':
      return ChatType.single;
    case 'group':
      return ChatType.group;
    case 'official':
      return ChatType.official;
    case 'service':
      return ChatType.service;
    case 'tool':
      return ChatType.tool;
    default:
      throw ArgumentError('Unknown ChatType: $s');
  }
}

String _chatTypeToString(ChatType t) {
  switch (t) {
    case ChatType.single:
      return 'single';
    case ChatType.group:
      return 'group';
    case ChatType.official:
      return 'official';
    case ChatType.service:
      return 'service';
    case ChatType.tool:
      return 'tool';
  }
}
