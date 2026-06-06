// 聊天仓库
//
// 负责：
// - 从 assets 加载 12 个会话的元数据（lib/data/mock/chats.json）
// - 按 chatId 懒加载各会话的消息（lib/data/mock/messages/<chatId>.json）
// - 维护一个简单的内存缓存，避免重复 IO
//
// 设计原则：仓库无状态，列表页和详情页各自持有 FutureBuilder / FutureProvider
// 调用即可，刷新靠重新调用方法。所有写操作（标已读 / 删除 / 撤回）都返回新 List，
// UI 层自行更新状态。
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/chat.dart';
import '../models/message.dart';

class ChatRepository {
  const ChatRepository();

  // 缓存：避免重复 IO
  static final Map<String, List<Message>> _messagesCache = {};
  static List<Chat>? _chatsCache;
  static Future<List<Chat>>? _chatsFuture;

  /// 12 个会话的元数据。
  Future<List<Chat>> loadChats({bool forceReload = false}) async {
    if (!forceReload && _chatsCache != null) return _chatsCache!;
    if (!forceReload && _chatsFuture != null) return _chatsFuture!;

    final fut = _doLoadChats();
    _chatsFuture = fut;
    try {
      final list = await fut;
      _chatsCache = list;
      return list;
    } finally {
      _chatsFuture = null;
    }
  }

  Future<List<Chat>> _doLoadChats() async {
    final raw = await rootBundle.loadString(_chatsAssetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final list = (decoded['chats'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Chat.fromJson)
        .toList(growable: false);
    return list;
  }

  /// 按 chatId 加载消息。
  Future<List<Message>> loadMessages(String chatId, {bool forceReload = false}) async {
    if (!forceReload) {
      final cached = _messagesCache[chatId];
      if (cached != null) return cached;
    }
    final path = _messagesAssetPath(chatId);
    final raw = await rootBundle.loadString(path);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final list = (decoded['messages'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Message.fromJson)
        .toList(growable: true);
    // 按时间升序排列（详情页的 ListView.builder 直接用）
    list.sort((a, b) => a.time.compareTo(b.time));
    _messagesCache[chatId] = list;
    return list;
  }

  /// 通过 chatId 找会话元数据。
  Future<Chat?> findChatById(String chatId) async {
    final all = await loadChats();
    for (final c in all) {
      if (c.id == chatId) return c;
    }
    return null;
  }

  /// 清空所有缓存（用于单元测试 / 强制刷新）
  void clearCache() {
    _chatsCache = null;
    _chatsFuture = null;
    _messagesCache.clear();
  }

  // ---- 路径常量 ----
  static const String _chatsAssetPath = 'lib/data/mock/chats.json';

  static String _messagesAssetPath(String chatId) =>
      'lib/data/mock/messages/$chatId.json';
}
