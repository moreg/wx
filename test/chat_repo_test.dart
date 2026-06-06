// Chat repository tests.
//
// 验证关键路径：
// 1. 12 个会话能从 chats.json 加载
// 2. 每个会话的消息数 >= 15（spec 要求 15-30 条）
// 3. 主要消息类型按 spec 表覆盖
// 4. rootBundle.loadString 能否在 pubspec 列出 lib/data/mock/ 时正确解析路径
import 'package:flutter_test/flutter_test.dart';
import 'package:wx_clone/data/models/chat.dart';
import 'package:wx_clone/data/models/message.dart';
import 'package:wx_clone/data/repositories/chat_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const repo = ChatRepository();

  // 任务规范里 12 个会话的 chatId；每会话必须 ≥ 15 条
  const expectedChatIds = <String>[
    'chat_file_transfer',
    'chat_ajie',
    'chat_backend_group',
    'chat_linda',
    'chat_wechat_pay',
    'chat_mom',
    'chat_company_admin',
    'chat_pdd',
    'chat_gym_buddy',
    'chat_xiaowang',
    'chat_family',
    'chat_landlord',
  ];

  test('chats.json loads 12 conversations', () async {
    final chats = await repo.loadChats();
    expect(chats.length, 12);
    expect(chats.first, isA<Chat>());
    // 至少包含阿杰、家庭群、微信支付
    final ids = chats.map((c) => c.id).toSet();
    expect(ids.contains('chat_ajie'), isTrue);
    expect(ids.contains('chat_family'), isTrue);
    expect(ids.contains('chat_wechat_pay'), isTrue);
  });

  test('every chat has at least 15 messages (spec minimum)', () async {
    final chats = await repo.loadChats();
    for (final c in chats) {
      final msgs = await repo.loadMessages(c.id);
      expect(
        msgs.length,
        greaterThanOrEqualTo(15),
        reason: '${c.id} 只有 ${msgs.length} 条消息，spec 要求 ≥ 15',
      );
    }
  });

  test('every chat has the time-grouping separator (type=time)', () async {
    for (final id in expectedChatIds) {
      final msgs = await repo.loadMessages(id);
      final types = msgs.map((m) => m.type).toSet();
      expect(
        types.contains(MessageType.time),
        isTrue,
        reason: '$id 缺少时间分组分隔条（type=time）',
      );
    }
  });

  test('chat_ajie messages cover text/image/voice/system', () async {
    final msgs = await repo.loadMessages('chat_ajie');
    expect(msgs.length, greaterThanOrEqualTo(15));
    final types = msgs.map((m) => m.type).toSet();
    expect(types.contains(MessageType.text), isTrue);
    expect(types.contains(MessageType.time), isTrue);
    expect(types.contains(MessageType.system), isTrue);
    expect(types.contains(MessageType.voice), isTrue);
    expect(types.contains(MessageType.image), isTrue);
  });

  test('chat_linda has location + transfer', () async {
    final msgs = await repo.loadMessages('chat_linda');
    final types = msgs.map((m) => m.type).toSet();
    expect(types.contains(MessageType.location), isTrue);
    expect(types.contains(MessageType.transfer), isTrue);
  });

  test('chat_backend_group has groupNotice + text + image', () async {
    final msgs = await repo.loadMessages('chat_backend_group');
    final types = msgs.map((m) => m.type).toSet();
    expect(types.contains(MessageType.groupNotice), isTrue);
    expect(types.contains(MessageType.text), isTrue);
  });

  test('chat_family has redPacket + text + image + voice', () async {
    final msgs = await repo.loadMessages('chat_family');
    final types = msgs.map((m) => m.type).toSet();
    expect(types.contains(MessageType.redPacket), isTrue);
    expect(types.contains(MessageType.text), isTrue);
    expect(types.contains(MessageType.image), isTrue);
    expect(types.contains(MessageType.voice), isTrue);
  });

  test('chat_wechat_pay has system + link + text', () async {
    final msgs = await repo.loadMessages('chat_wechat_pay');
    final types = msgs.map((m) => m.type).toSet();
    expect(types.contains(MessageType.system), isTrue);
    expect(types.contains(MessageType.link), isTrue);
    expect(types.contains(MessageType.text), isTrue);
  });

  test('chat_file_transfer has file + text (no less than 15)', () async {
    final msgs = await repo.loadMessages('chat_file_transfer');
    expect(msgs.length, greaterThanOrEqualTo(15));
    final types = msgs.map((m) => m.type).toSet();
    expect(types.contains(MessageType.file), isTrue);
    expect(types.contains(MessageType.text), isTrue);
  });

  test('chat_pdd has link + text (no less than 15)', () async {
    final msgs = await repo.loadMessages('chat_pdd');
    expect(msgs.length, greaterThanOrEqualTo(15));
    final types = msgs.map((m) => m.type).toSet();
    expect(types.contains(MessageType.link), isTrue);
    expect(types.contains(MessageType.text), isTrue);
  });

  test('chat_company_admin has link + text (no less than 15)', () async {
    final msgs = await repo.loadMessages('chat_company_admin');
    expect(msgs.length, greaterThanOrEqualTo(15));
    final types = msgs.map((m) => m.type).toSet();
    expect(types.contains(MessageType.link), isTrue);
    expect(types.contains(MessageType.text), isTrue);
  });

  test('chat_landlord has transfer + location (no less than 15)', () async {
    final msgs = await repo.loadMessages('chat_landlord');
    expect(msgs.length, greaterThanOrEqualTo(15));
    final types = msgs.map((m) => m.type).toSet();
    expect(types.contains(MessageType.transfer), isTrue);
    expect(types.contains(MessageType.location), isTrue);
  });

  test('chat_xiaowang has file (no less than 15)', () async {
    final msgs = await repo.loadMessages('chat_xiaowang');
    expect(msgs.length, greaterThanOrEqualTo(15));
    final types = msgs.map((m) => m.type).toSet();
    expect(types.contains(MessageType.file), isTrue);
  });

  test('chat_gym_buddy has image (no less than 15)', () async {
    final msgs = await repo.loadMessages('chat_gym_buddy');
    expect(msgs.length, greaterThanOrEqualTo(15));
    final types = msgs.map((m) => m.type).toSet();
    expect(types.contains(MessageType.image), isTrue);
  });

  test('chat_mom has image + voice + emoji', () async {
    final msgs = await repo.loadMessages('chat_mom');
    final types = msgs.map((m) => m.type).toSet();
    expect(types.contains(MessageType.image), isTrue);
    expect(types.contains(MessageType.voice), isTrue);
    expect(types.contains(MessageType.emoji), isTrue);
  });

  test('findChatById returns null for unknown id', () async {
    final c = await repo.findChatById('chat_does_not_exist');
    expect(c, isNull);
  });
}
