// 聊天详情（S04b）
//
// 顶部栏：返回 + 昵称 + 在线状态
// 消息列表：按时间分组，气泡区分自己（绿）vs 对方（白）
// 时间戳：中午 12 点分界
// 长按消息：ActionSheet 6 项（撤回/转发/收藏/复制/删除/多选）
// 底部输入栏：文本框 + 表情按钮 + "+" 按钮 + 发送
// 表情面板：8 列 × 4 行 emoji 字符
// "+" 面板：6 宫格（图片/拍摄/语音/位置/名片/文件）
// 发送文本：append 到本地状态（不持久化）
// 点击图片进入全屏预览（用 ImagePreviewPage）
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import '../../data/models/chat.dart';
import '../../data/models/message.dart';
import '../../data/repositories/chat_repo.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_bubble.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  const ChatDetailPage({super.key, required this.chatId});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  static const ChatRepository _repo = ChatRepository();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Chat? _chat;
  List<Message> _messages = const [];
  bool _loading = true;
  int _localSeq = 0;
  // 用一个键让 ChatInputBar 在 detail 切换时重建（避免 panel 状态残留）
  final Key _inputBarKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _load();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // 键盘弹起时滚到底部
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _load() async {
    final chat = await _repo.findChatById(widget.chatId);
    final messages = await _repo.loadMessages(widget.chatId);
    if (!mounted) return;
    setState(() {
      _chat = chat;
      _messages = messages;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  void _onSend(String text) {
    _localSeq++;
    final msg = Message(
      id: 'local_${widget.chatId}_${DateTime.now().millisecondsSinceEpoch}_$_localSeq',
      chatId: widget.chatId,
      type: MessageType.text,
      direction: MessageDirection.self,
      time: DateTime.now(),
      text: text,
    );
    setState(() {
      _messages = [..._messages, msg];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
              children: [
                Expanded(child: _buildMessageList()),
                ChatInputBar(
                  key: _inputBarKey,
                  controller: _textController,
                  focusNode: _focusNode,
                  onSend: _onSend,
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: WxColors.bgLight,
      elevation: 0.5,
      leading: IconButton(
        icon: SvgPicture.asset(
          'assets/icons/weui-back.svg',
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            WxColors.textPrimary,
            BlendMode.srcIn,
          ),
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _chat?.name ?? '聊天',
            style: const TextStyle(
              fontSize: WxFontSize.title,
              fontWeight: WxFontWeight.medium,
              color: WxColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (_chat != null)
            Text(
              _statusLineFor(_chat!),
              style: const TextStyle(
                fontSize: WxFontSize.caption,
                color: WxColors.textSecondary,
                fontWeight: WxFontWeight.regular,
              ),
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline, size: 22),
          onPressed: () => _toast('发起聊天 (Mock)'),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () => _showChatOptions(),
        ),
      ],
    );
  }

  String _statusLineFor(Chat c) {
    switch (c.type) {
      case ChatType.group:
        return c.description ?? '群聊';
      case ChatType.official:
      case ChatType.service:
        return c.description ?? '公众号';
      case ChatType.tool:
        return c.description ?? '工具';
      case ChatType.single:
        return '在线';
    }
  }

  Widget _buildMessageList() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: WxSpace.sm),
        itemCount: _messages.length,
        itemBuilder: (ctx, i) {
          final m = _messages[i];
          final showName = _shouldShowSenderName(i);
          return MessageBubble(
            message: m,
            chat: _chat,
            showSenderName: showName,
          );
        },
      ),
    );
  }

  /// 群聊里两条消息间隔 < 1 分钟时不重复显示发送者昵称
  bool _shouldShowSenderName(int i) {
    if (_chat?.type != ChatType.group) return false;
    if (i == 0) return true;
    final prev = _messages[i - 1];
    final cur = _messages[i];
    if (prev.direction != cur.direction) return true;
    if (cur.time.difference(prev.time).inMinutes >= 1) return true;
    return false;
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: WxColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(WxRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.search, color: WxColors.textPrimary),
                title: const Text('查找聊天记录'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _toast('查找聊天记录 (Mock)');
                },
              ),
              const Divider(height: 0.5),
              ListTile(
                leading: const Icon(Icons.people_outline,
                    color: WxColors.textPrimary),
                title: const Text('聊天成员'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _toast('聊天成员 (Mock)');
                },
              ),
              const Divider(height: 0.5),
              ListTile(
                leading: const Icon(Icons.notifications_off_outlined,
                    color: WxColors.textPrimary),
                title: const Text('消息免打扰'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _toast('消息免打扰 (Mock)');
                },
              ),
              const Divider(height: 0.5),
              ListTile(
                leading: const Icon(Icons.report_outlined,
                    color: WxColors.expense),
                title: const Text(
                  '投诉',
                  style: TextStyle(color: WxColors.expense),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _toast('投诉 (Mock)');
                },
              ),
              const SizedBox(height: WxSpace.sm),
            ],
          ),
        );
      },
    );
  }

  void _toast(String msg) {
    HapticFeedback.selectionClick();
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 120,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WxSpace.lg,
              vertical: WxSpace.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(WxRadius.sm),
            ),
            child: Text(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontSize: WxFontSize.body,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1500), entry.remove);
  }
}
