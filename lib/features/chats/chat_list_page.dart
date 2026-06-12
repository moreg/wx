// 微信 Tab — 聊天列表（S04）
//
// 布局：ListView，每个 Chat 一个 Dismissible（endToStart）支持右滑操作，
// 露出"标为已读"+"删除"两个按钮。长按弹 ActionSheet（置顶/免打扰/删除）。
//
// 数据源：lib/data/mock/chats.json
// 加载：FutureBuilder 异步从 rootBundle 拉（首次冷启 ~几十 ms），加载期间
// 显示空态骨架。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/design_tokens.dart';
import '../../data/models/chat.dart';
import '../../data/repositories/chat_repo.dart';
import '../../data/repositories/auth_repo.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  static const ChatRepository _repo = ChatRepository();
  // 当前登录账号（用于"我"的头像占位）
  static const AuthRepository _auth = AuthRepository();

  // 列表状态（in-memory；不做持久化）
  final List<_ChatListItem> _items = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chats = await _repo.loadChats();
    setState(() {
      _items
        ..clear()
        ..addAll(chats.map(_ChatListItem.fromChat));
      _sortItems();
      _loaded = true;
    });
  }

  void _onMarkAsRead(_ChatListItem item) {
    setState(() {
      item.unreadCount = 0;
    });
  }

  void _onDelete(_ChatListItem item) {
    setState(() {
      _items.removeWhere((e) => e.id == item.id);
    });
    _showSnack('已删除');
  }

  Future<void> _showActionSheet(_ChatListItem item) async {
    HapticFeedback.mediumImpact();
    final action = await showModalBottomSheet<String>(
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
                leading: const Icon(
                  Icons.push_pin,
                  color: WxColors.textPrimary,
                ),
                title: Text(item.pinned ? '取消置顶' : '置顶聊天'),
                onTap: () => Navigator.of(ctx).pop('pin'),
              ),
              const Divider(height: 0.5),
              ListTile(
                leading: const Icon(
                  Icons.notifications_off_outlined,
                  color: WxColors.textPrimary,
                ),
                title: Text(item.muted ? '取消免打扰' : '消息免打扰'),
                onTap: () => Navigator.of(ctx).pop('mute'),
              ),
              const Divider(height: 0.5),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: WxColors.expense,
                ),
                title: const Text(
                  '删除聊天',
                  style: TextStyle(color: WxColors.expense),
                ),
                onTap: () => Navigator.of(ctx).pop('delete'),
              ),
              const SizedBox(height: WxSpace.sm),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    if (action == 'pin') {
      setState(() {
        item.pinned = !item.pinned;
        _sortItems();
      });
    } else if (action == 'mute') {
      setState(() => item.muted = !item.muted);
    } else if (action == 'delete') {
      _confirmDelete(item);
    }
  }

  Future<void> _confirmDelete(_ChatListItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除该聊天？'),
        content: Text('将从列表中删除与「${item.name}」的聊天记录'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除', style: TextStyle(color: WxColors.expense)),
          ),
        ],
      ),
    );
    if (ok == true) _onDelete(item);
  }

  void _sortItems() {
    _items.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.lastMessageTime.compareTo(a.lastMessageTime);
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _openChat(_ChatListItem item) {
    setState(() {
      item.unreadCount = 0;
    });
    context.push('/chat/${item.id}');
  }

  Future<void> _onPullRefresh() async {
    HapticFeedback.lightImpact();
    // global-ux 叠加：下拉刷新（实际场景会重新拉取 ChatRepository）
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final me = _auth.allAccounts.isNotEmpty ? _auth.allAccounts.first : null;
    final totalUnread = _items.fold<int>(0, (sum, item) => sum + item.unreadCount);
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(
        title: Text(totalUnread > 0 ? '微信($totalUnread)' : '微信'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/weui-search.svg',
              width: 24,
              height: 24,
              theme: const SvgTheme(currentColor: Colors.black),
            ),
            onPressed: () {
              _showSnack('搜索 (Mock)');
            },
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/add2-outlined.svg',
              width: 24,
              height: 24,
              theme: const SvgTheme(currentColor: Colors.black),
            ),
            onPressed: _showTopMenu,
          ),
          const SizedBox(width: 8),
        ],
      ),
      // 用 RefreshIndicator 统一包住"加载中 / 空态 / 列表"三种情况，
      // 保证空态时也能下拉刷新。
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _onPullRefresh,
              color: WxColors.green,
              child: _items.isEmpty
                  ? ListView(
                      // 空态也要是 scrollable，否则 RefreshIndicator 收不到手势
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        _EmptyChatsState(),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: _items.length,
                      itemBuilder: (ctx, i) {
                        final item = _items[i];
                        return _ChatListRow(
                          key: ValueKey(item.id),
                          item: item,
                          myAvatar: me?.avatar,
                          onTap: () => _openChat(item),
                          onLongPress: () => _showActionSheet(item),
                          onMarkAsRead: () => _onMarkAsRead(item),
                          onDelete: () => _confirmDelete(item),
                        );
                      },
                    ),
            ),
    );
  }

  Future<void> _showTopMenu() async {
    HapticFeedback.selectionClick();
    final action = await showMenu<String>(
      context: context,
      color: const Color(0xFF4C4C4C),
      position: const RelativeRect.fromLTRB(220, 78, 12, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WxRadius.sm),
      ),
      items: const [
        PopupMenuItem(value: 'chat', child: _TopMenuItem(Icons.chat, '发起群聊')),
        PopupMenuItem(
          value: 'add',
          child: _TopMenuItem(Icons.person_add, '添加朋友'),
        ),
        PopupMenuItem(
          value: 'scan',
          child: _TopMenuItem(Icons.qr_code_scanner, '扫一扫'),
        ),
        PopupMenuItem(value: 'pay', child: _TopMenuItem(Icons.payments, '收付款')),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'chat':
        _showSnack('发起群聊 (Mock)');
        break;
      case 'add':
        _showSnack('添加朋友 (Mock)');
        break;
      case 'scan':
        _showSnack('扫一扫 (Mock)');
        break;
      case 'pay':
        context.push('/pay');
        break;
    }
  }
}

class _TopMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TopMenuItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: WxSpace.md),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: WxFontSize.body,
          ),
        ),
      ],
    );
  }
}

/// 聊天列表空态（global-ux Track 增强：明确提示可下拉刷新）
class _EmptyChatsState extends StatelessWidget {
  const _EmptyChatsState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.chat_bubble_outline, size: 80, color: WxColors.textHint),
        SizedBox(height: WxSpace.lg),
        Text(
          '暂无聊天',
          style: TextStyle(
            color: WxColors.textSecondary,
            fontSize: WxFontSize.title,
          ),
        ),
        SizedBox(height: WxSpace.xs),
        Text(
          '下拉刷新试试',
          style: TextStyle(
            color: WxColors.textTertiary,
            fontSize: WxFontSize.body,
          ),
        ),
      ],
    );
  }
}

class _ChatListRow extends StatelessWidget {
  final _ChatListItem item;
  final String? myAvatar;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const _ChatListRow({
    super.key,
    required this.item,
    required this.myAvatar,
    required this.onTap,
    required this.onLongPress,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${item.id}'),
      direction: DismissDirection.endToStart,
      // 用 ConfirmDismiss 让用户先确认删除
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('删除该聊天？'),
                content: Text('将从列表中删除与「${item.name}」的聊天记录'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      '删除',
                      style: TextStyle(color: WxColors.expense),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        color: WxColors.bg,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: WxSpace.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildSwipeButton(
              label: '标为已读',
              color: WxColors.green,
              onTap: () {
                onMarkAsRead();
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
              },
            ),
            const SizedBox(width: WxSpace.xs),
            _buildSwipeButton(
              label: '删除',
              color: WxColors.expense,
              onTap: () {
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                onDelete();
              },
            ),
          ],
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: 72,
          color: item.pinned ? const Color(0xFFEDEDED) : WxColors.card,
          padding: const EdgeInsets.symmetric(horizontal: WxSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 头像
              _buildAvatar(),
              const SizedBox(width: WxSpace.md),
              // 主体
              Expanded(
                child: Container(
                  height: 72,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFE5E5E5), // faint divider color
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16.5,
                                color: WxColors.textPrimary,
                                fontWeight: FontWeight.w400, // WeChat uses regular weight for names
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(item.lastMessageTime),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB2B2B2), // WeChat time text color
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (item.muted)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.notifications_off,
                                size: 14,
                                color: WxColors.textTertiary,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              item.lastMessagePreview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF999999), // WeChat subtitle color
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: WxAvatarSize.md,
          height: WxAvatarSize.md,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: WxColors.divider,
            borderRadius: BorderRadius.circular(WxRadius.md),
          ),
          child: Image.asset(
            item.avatar,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: WxColors.divider,
              alignment: Alignment.center,
              child: Text(
                item.name.isNotEmpty ? item.name.characters.first : '?',
                style: const TextStyle(
                  fontSize: WxFontSize.headline,
                  color: WxColors.textHint,
                ),
              ),
            ),
          ),
        ),
        if (item.unreadCount > 0)
          Positioned(
            right: item.muted ? -2 : -8,
            top: item.muted ? -2 : -7,
            child: item.muted
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: WxColors.unread,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  )
                : Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: WxColors.unread,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: WxFontSize.caption,
                        height: 1,
                        fontWeight: WxFontWeight.medium,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _buildSwipeButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 80,
        height: double.infinity,
        color: color,
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: WxFontSize.body,
            fontWeight: WxFontWeight.medium,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tDay = DateTime(t.year, t.month, t.day);
    final diff = today.difference(tDay).inDays;
    if (diff == 0) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    if (diff == 1) return '昨天';
    if (diff < 7) {
      const wk = ['一', '二', '三', '四', '五', '六', '日'];
      return '周${wk[t.weekday - 1]}';
    }
    if (t.year == now.year) {
      return '${t.month}/${t.day}';
    }
    return '${t.year}/${t.month}/${t.day}';
  }
}

/// In-memory mutable row state. Backed by Chat for initial values.
class _ChatListItem {
  final String id;
  final String name;
  final String avatar;
  final ChatType type;
  String lastMessagePreview;
  DateTime lastMessageTime;
  int unreadCount;
  bool pinned;
  bool muted;

  _ChatListItem({
    required this.id,
    required this.name,
    required this.avatar,
    required this.type,
    required this.lastMessagePreview,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.pinned,
    required this.muted,
  });

  factory _ChatListItem.fromChat(Chat c) {
    return _ChatListItem(
      id: c.id,
      name: c.name,
      avatar: c.avatar,
      type: c.type,
      lastMessagePreview: c.lastMessagePreview,
      lastMessageTime: c.lastMessageTime,
      unreadCount: c.unreadCount,
      pinned: c.pinned,
      muted: c.muted,
    );
  }
}
