// 消息模型
//
// 9 种消息类型：文本 / 图片 / 语音 / 视频 / 位置 / 转账 / 名片 / 系统提示 / 时间分组
//
// 时间分组（type == time）不是真正的"消息"，是分隔线（同一天/同一小时分组）。
// 为了渲染简单，本模型统一表达；时间分组通过 [isTimeHeader] 标志识别，
// UI 层用 ChatTimeHeader 渲染即可。
//
// 字段设计：
// - id：消息唯一 ID（"m_<chat>_<n>"）
// - chatId：所属会话
// - type：见 [MessageType]
// - direction：self（我发出的）/ other（对方）/ system（系统提示 / 撤回）
// - senderId / senderName：发送者 wxid + 昵称（群聊时显示昵称，单聊可省略）
// - time：消息时间（type==time 时是分组时间戳）
// - text：纯文本 / 撤回提示 / 转账留言
// - imageUrl：图片 / 视频缩略图（用现有头像占位即可，无外网）
// - imageWidth / imageHeight：图片原始比例
// - audioDuration：语音时长（秒）
// - videoDuration：视频时长（秒）
// - locationName / locationAddress：位置名 + 地址
// - transferAmount / transferTitle：转账金额（元）+ 标题（如"转账"）
// - transferStatus：转账状态（待确认 / 已收款 / 已退还）
// - cardName / cardWxid：名片 - 联系人昵称 + wxid
// - fileName / fileSize：文件 - 文件名 + 大小（KB/MB）
// - linkTitle / linkDescription / linkImageUrl：链接卡片（公众号 / 服务号 / 群链接）
// - isRevoked：是否已撤回（撤回消息的渲染态）

enum MessageType {
  text,
  image,
  voice,
  video,
  location,
  transfer,
  card,
  system, // 系统提示（你已添加对方 / 撤回了一条消息 / 群公告 等）
  time, // 时间分组分隔条（不是真消息，UI 层识别后单独渲染）
  /// 群公告
  groupNotice,
  /// 红包
  redPacket,
  /// 表情包（这里用文本占位描述，真做时是张图片）
  emoji,
  /// 文件
  file,
  /// 链接卡片
  link,
}

enum MessageDirection {
  /// 我发的
  self,
  /// 对方发的
  other,
  /// 系统 / 撤回
  system,
}

class Message {
  final String id;
  final String chatId;
  final MessageType type;
  final MessageDirection direction;
  final String? senderId;
  final String? senderName;
  final DateTime time;
  final String? text;
  final String? imageUrl;
  final double? imageWidth;
  final double? imageHeight;
  final int? audioDuration; // seconds
  final int? videoDuration;
  final String? locationName;
  final String? locationAddress;
  final double? transferAmount;
  final String? transferTitle;
  final String? transferStatus;
  final String? cardName;
  final String? cardWxid;
  final String? fileName;
  final String? fileSize;
  final String? linkTitle;
  final String? linkDescription;
  final String? linkImageUrl;
  final String? linkUrl;
  final String? redPacketTitle;
  final double? redPacketAmount;
  final String? redPacketStatus;
  final String? groupNoticeText;
  final bool isRevoked;

  const Message({
    required this.id,
    required this.chatId,
    required this.type,
    required this.direction,
    required this.time,
    this.senderId,
    this.senderName,
    this.text,
    this.imageUrl,
    this.imageWidth,
    this.imageHeight,
    this.audioDuration,
    this.videoDuration,
    this.locationName,
    this.locationAddress,
    this.transferAmount,
    this.transferTitle,
    this.transferStatus,
    this.cardName,
    this.cardWxid,
    this.fileName,
    this.fileSize,
    this.linkTitle,
    this.linkDescription,
    this.linkImageUrl,
    this.linkUrl,
    this.redPacketTitle,
    this.redPacketAmount,
    this.redPacketStatus,
    this.groupNoticeText,
    this.isRevoked = false,
  });

  bool get isTimeHeader => type == MessageType.time;
  bool get isSystem => type == MessageType.system || type == MessageType.time;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      type: _messageTypeFromString(json['type'] as String),
      direction: _directionFromString(json['direction'] as String),
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      time: DateTime.parse(json['time'] as String),
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      imageWidth: (json['imageWidth'] as num?)?.toDouble(),
      imageHeight: (json['imageHeight'] as num?)?.toDouble(),
      audioDuration: (json['audioDuration'] as num?)?.toInt(),
      videoDuration: (json['videoDuration'] as num?)?.toInt(),
      locationName: json['locationName'] as String?,
      locationAddress: json['locationAddress'] as String?,
      transferAmount: (json['transferAmount'] as num?)?.toDouble(),
      transferTitle: json['transferTitle'] as String?,
      transferStatus: json['transferStatus'] as String?,
      cardName: json['cardName'] as String?,
      cardWxid: json['cardWxid'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as String?,
      linkTitle: json['linkTitle'] as String?,
      linkDescription: json['linkDescription'] as String?,
      linkImageUrl: json['linkImageUrl'] as String?,
      linkUrl: json['linkUrl'] as String?,
      redPacketTitle: json['redPacketTitle'] as String?,
      redPacketAmount: (json['redPacketAmount'] as num?)?.toDouble(),
      redPacketStatus: json['redPacketStatus'] as String?,
      groupNoticeText: json['groupNoticeText'] as String?,
      isRevoked: json['isRevoked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chatId': chatId,
    'type': _messageTypeToString(type),
    'direction': _directionToString(direction),
    'senderId': senderId,
    'senderName': senderName,
    'time': time.toIso8601String(),
    'text': text,
    'imageUrl': imageUrl,
    'imageWidth': imageWidth,
    'imageHeight': imageHeight,
    'audioDuration': audioDuration,
    'videoDuration': videoDuration,
    'locationName': locationName,
    'locationAddress': locationAddress,
    'transferAmount': transferAmount,
    'transferTitle': transferTitle,
    'transferStatus': transferStatus,
    'cardName': cardName,
    'cardWxid': cardWxid,
    'fileName': fileName,
    'fileSize': fileSize,
    'linkTitle': linkTitle,
    'linkDescription': linkDescription,
    'linkImageUrl': linkImageUrl,
    'linkUrl': linkUrl,
    'redPacketTitle': redPacketTitle,
    'redPacketAmount': redPacketAmount,
    'redPacketStatus': redPacketStatus,
    'groupNoticeText': groupNoticeText,
    'isRevoked': isRevoked,
  };
}

MessageType _messageTypeFromString(String s) {
  switch (s) {
    case 'text':
      return MessageType.text;
    case 'image':
      return MessageType.image;
    case 'voice':
      return MessageType.voice;
    case 'video':
      return MessageType.video;
    case 'location':
      return MessageType.location;
    case 'transfer':
      return MessageType.transfer;
    case 'card':
      return MessageType.card;
    case 'system':
      return MessageType.system;
    case 'time':
      return MessageType.time;
    case 'groupNotice':
      return MessageType.groupNotice;
    case 'redPacket':
      return MessageType.redPacket;
    case 'emoji':
      return MessageType.emoji;
    case 'file':
      return MessageType.file;
    case 'link':
      return MessageType.link;
    default:
      throw ArgumentError('Unknown MessageType: $s');
  }
}

String _messageTypeToString(MessageType t) {
  switch (t) {
    case MessageType.text:
      return 'text';
    case MessageType.image:
      return 'image';
    case MessageType.voice:
      return 'voice';
    case MessageType.video:
      return 'video';
    case MessageType.location:
      return 'location';
    case MessageType.transfer:
      return 'transfer';
    case MessageType.card:
      return 'card';
    case MessageType.system:
      return 'system';
    case MessageType.time:
      return 'time';
    case MessageType.groupNotice:
      return 'groupNotice';
    case MessageType.redPacket:
      return 'redPacket';
    case MessageType.emoji:
      return 'emoji';
    case MessageType.file:
      return 'file';
    case MessageType.link:
      return 'link';
  }
}

MessageDirection _directionFromString(String s) {
  switch (s) {
    case 'self':
      return MessageDirection.self;
    case 'other':
      return MessageDirection.other;
    case 'system':
      return MessageDirection.system;
    default:
      throw ArgumentError('Unknown MessageDirection: $s');
  }
}

String _directionToString(MessageDirection d) {
  switch (d) {
    case MessageDirection.self:
      return 'self';
    case MessageDirection.other:
      return 'other';
    case MessageDirection.system:
      return 'system';
  }
}
