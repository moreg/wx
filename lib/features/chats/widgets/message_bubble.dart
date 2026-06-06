// 消息气泡
//
// 渲染 9 种消息类型 + 时间分组。
// 时间分组（type==time）由 ChatDetailPage 在拼装时插入；本组件只负责渲染。
//
// 9 种类型：
//   text       — 纯文本 / 撤回提示
//   image      — 点击进入 ImagePreviewPage
//   voice      — 蓝色进度条 + 时长
//   video      — ▶️ 缩略图 + 时长
//   location   — 地图缩略图 + 地点名
//   transfer   — 黄色卡片 + 金额 + 状态
//   card       — 联系人名片
//   system     — 居中灰色小字
//   time       — 居中灰色小字（时间分组分隔条）
//   file       — 文件图标 + 文件名 + 大小
//   link       — 链接卡片
//   redPacket  — 红包
//   groupNotice — 群公告（黄底卡片）
//   emoji      — 表情包（单 emoji 居中大字）
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final Chat? chat;
  final bool showSenderName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.chat,
    this.showSenderName = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isTimeHeader) {
      return _buildTimeHeader(context);
    }
    if (message.type == MessageType.system) {
      return _buildSystemMessage(context);
    }
    if (message.type == MessageType.groupNotice) {
      return _buildGroupNotice(context);
    }

    final isMe = message.direction == MessageDirection.self;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WxSpace.md,
        vertical: WxSpace.xs,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatar(context, isMe: false),
          if (!isMe) const SizedBox(width: WxSpace.sm),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSenderName && !isMe && message.senderName != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: WxSpace.xs,
                      bottom: WxSpace.xxs,
                    ),
                    child: Text(
                      message.senderName!,
                      style: const TextStyle(
                        fontSize: WxFontSize.small,
                        color: WxColors.textSecondary,
                      ),
                    ),
                  ),
                _buildBubble(context, isMe),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: WxSpace.sm),
          if (isMe) _buildAvatar(context, isMe: true),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, {required bool isMe}) {
    final avatarPath = isMe
        ? 'assets/images/avatars/avatar_5.png'
        : (chat?.avatar ?? 'assets/images/avatars/avatar_1.png');
    return Image.asset(
      avatarPath,
      width: WxAvatarSize.md - 4,
      height: WxAvatarSize.md - 4,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: WxAvatarSize.md - 4,
        height: WxAvatarSize.md - 4,
        color: WxColors.divider,
        child: const Icon(Icons.person, color: WxColors.textHint, size: 20),
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool isMe) {
    final m = message;
    final color = isMe ? WxColors.bubbleMe : WxColors.bubbleOther;

    Widget body;
    switch (m.type) {
      case MessageType.text:
        body = _buildTextBubble(context, color);
        break;
      case MessageType.image:
        body = _buildImageBubble(context);
        break;
      case MessageType.voice:
        body = _buildVoiceBubble(context, isMe, color);
        break;
      case MessageType.video:
        body = _buildVideoBubble(context, color);
        break;
      case MessageType.location:
        body = _buildLocationBubble(context, color);
        break;
      case MessageType.transfer:
        body = _buildTransferBubble(context, isMe, color);
        break;
      case MessageType.card:
        body = _buildCardBubble(context, color);
        break;
      case MessageType.file:
        body = _buildFileBubble(context, isMe, color);
        break;
      case MessageType.link:
        body = _buildLinkBubble(context, color);
        break;
      case MessageType.redPacket:
        body = _buildRedPacketBubble(context, isMe, color);
        break;
      case MessageType.emoji:
        body = _buildEmojiBubble(context);
        break;
      case MessageType.time:
      case MessageType.system:
      case MessageType.groupNotice:
        body = const SizedBox.shrink();
        break;
    }

    return GestureDetector(
      onLongPress: () => _showMessageActionSheet(context),
      onTap: () {
        if (m.type == MessageType.image) {
          _openImagePreview(context, m);
        }
      },
      child: body,
    );
  }

  // ---- 单类型实现 ----

  Widget _buildTextBubble(BuildContext context, Color color) {
    final m = message;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.66,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WxSpace.md,
          vertical: WxSpace.sm,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(WxRadius.sm),
        ),
        child: Text(
          m.text ?? '',
          style: const TextStyle(
            color: WxColors.textPrimary,
            fontSize: WxFontSize.bodyLarge,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildImageBubble(BuildContext context) {
    final m = message;
    final w = (m.imageWidth ?? 200).clamp(120, 240).toDouble();
    final h = (m.imageHeight ?? 200).clamp(120, 320).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(WxRadius.sm),
      child: Container(
        color: WxColors.divider,
        width: w,
        height: h,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                m.imageUrl ?? 'assets/images/avatars/avatar_1.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: WxColors.divider,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image,
                    color: WxColors.textHint,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceBubble(BuildContext context, bool isMe, Color color) {
    final m = message;
    final duration = m.audioDuration ?? 0;
    final width = 60.0 + (duration * 3).clamp(0, 100);
    return Container(
      width: width.toDouble(),
      padding: const EdgeInsets.symmetric(
        horizontal: WxSpace.md,
        vertical: WxSpace.sm,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(WxRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Icon(
            Icons.volume_up_rounded,
            size: 18,
            color: isMe ? WxColors.textPrimary : WxColors.linkBlue,
          ),
          const SizedBox(width: WxSpace.sm),
          Text(
            '$duration"',
            style: const TextStyle(
              fontSize: WxFontSize.body,
              color: WxColors.textPrimary,
            ),
          ),
          if (isMe) const Spacer(),
          if (isMe)
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: WxColors.textHint,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoBubble(BuildContext context, Color color) {
    final m = message;
    return ClipRRect(
      borderRadius: BorderRadius.circular(WxRadius.sm),
      child: Container(
        width: 200,
        height: 140,
        color: WxColors.textPrimary,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset(
                m.imageUrl ?? 'assets/images/avatars/avatar_2.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: WxColors.textPrimary),
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                color: Colors.black.withValues(alpha: 0.6),
                child: Text(
                  '${m.videoDuration ?? 0}"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: WxFontSize.small,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBubble(BuildContext context, Color color) {
    final m = message;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(WxRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE0EBE0),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(WxRadius.sm),
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/images/avatars/avatar_4.png'),
                  fit: BoxFit.cover,
                  opacity: 0.3,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.location_on,
                  color: WxColors.green,
                  size: 32,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(WxSpace.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.locationName ?? '',
                    style: const TextStyle(
                      fontSize: WxFontSize.body,
                      color: WxColors.textPrimary,
                      fontWeight: WxFontWeight.medium,
                    ),
                  ),
                  if (m.locationAddress != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      m.locationAddress!,
                      style: const TextStyle(
                        fontSize: WxFontSize.small,
                        color: WxColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferBubble(BuildContext context, bool isMe, Color color) {
    final m = message;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: Container(
        padding: const EdgeInsets.all(WxSpace.md),
        decoration: BoxDecoration(
          color: const Color(0xFFFAE9C8),
          borderRadius: BorderRadius.circular(WxRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: WxColors.expense,
                  size: 18,
                ),
                const SizedBox(width: WxSpace.xs),
                Text(
                  isMe ? '转账给对方' : '转账给你',
                  style: const TextStyle(
                    fontSize: WxFontSize.small,
                    color: WxColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: WxSpace.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${m.transferAmount?.toStringAsFixed(2) ?? "0.00"}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: WxFontWeight.semibold,
                    color: WxColors.textPrimary,
                  ),
                ),
                const SizedBox(width: WxSpace.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    m.transferStatus ?? '',
                    style: const TextStyle(
                      fontSize: WxFontSize.small,
                      color: WxColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: WxSpace.xs),
            Text(
              m.text ?? m.transferTitle ?? '',
              style: const TextStyle(
                fontSize: WxFontSize.small,
                color: WxColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBubble(BuildContext context, Color color) {
    final m = message;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(WxSpace.md),
      decoration: BoxDecoration(
        color: WxColors.card,
        borderRadius: BorderRadius.circular(WxRadius.sm),
        border: Border.all(color: WxColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WxColors.divider,
              borderRadius: BorderRadius.circular(WxRadius.sm),
            ),
            child: const Icon(
              Icons.person,
              color: WxColors.textHint,
              size: 24,
            ),
          ),
          const SizedBox(width: WxSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.cardName ?? '',
                  style: const TextStyle(
                    fontSize: WxFontSize.body,
                    color: WxColors.textPrimary,
                  ),
                ),
                if (m.cardWxid != null)
                  Text(
                    m.cardWxid!,
                    style: const TextStyle(
                      fontSize: WxFontSize.small,
                      color: WxColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.qr_code,
            color: WxColors.textHint,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildFileBubble(BuildContext context, bool isMe, Color color) {
    final m = message;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(WxSpace.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(WxRadius.sm),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WxColors.divider,
              borderRadius: BorderRadius.circular(WxRadius.sm),
            ),
            child: const Icon(
              Icons.insert_drive_file,
              color: WxColors.linkBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: WxSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.fileName ?? '文件',
                  style: const TextStyle(
                    fontSize: WxFontSize.body,
                    color: WxColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (m.fileSize != null)
                  Text(
                    m.fileSize!,
                    style: const TextStyle(
                      fontSize: WxFontSize.small,
                      color: WxColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkBubble(BuildContext context, Color color) {
    final m = message;
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: WxColors.card,
        borderRadius: BorderRadius.circular(WxRadius.sm),
        border: Border.all(color: WxColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(WxSpace.md),
            child: Text(
              m.linkTitle ?? '',
              style: const TextStyle(
                fontSize: WxFontSize.body,
                color: WxColors.textPrimary,
                fontWeight: WxFontWeight.medium,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (m.linkDescription != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WxSpace.md),
              child: Text(
                m.linkDescription!,
                style: const TextStyle(
                  fontSize: WxFontSize.small,
                  color: WxColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: WxSpace.sm),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Image.asset(
                  m.linkImageUrl ?? 'assets/images/avatars/avatar_3.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: WxColors.divider, width: 32, height: 32),
                ),
              ),
              const SizedBox(width: WxSpace.xs),
              const Text(
                '微信支付',
                style: TextStyle(
                  fontSize: WxFontSize.small,
                  color: WxColors.textSecondary,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right,
                color: WxColors.textHint,
                size: 16,
              ),
              const SizedBox(width: WxSpace.sm),
            ],
          ),
          const SizedBox(height: WxSpace.sm),
        ],
      ),
    );
  }

  Widget _buildRedPacketBubble(BuildContext context, bool isMe, Color color) {
    final m = message;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(WxSpace.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEE7763), Color(0xFFD35449)],
        ),
        borderRadius: BorderRadius.circular(WxRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.card_giftcard,
                color: Color(0xFFFFD584),
                size: 18,
              ),
              const SizedBox(width: WxSpace.xs),
              Text(
                m.redPacketStatus ?? '红包',
                style: const TextStyle(
                  fontSize: WxFontSize.small,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: WxSpace.sm),
          Text(
            m.redPacketTitle ?? '恭喜发财，大吉大利',
            style: const TextStyle(
              fontSize: WxFontSize.body,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '¥${m.redPacketAmount?.toStringAsFixed(2) ?? "0.00"}',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: WxFontWeight.medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiBubble(BuildContext context) {
    final m = message;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WxSpace.sm),
      child: Text(
        m.text ?? '😊',
        style: const TextStyle(fontSize: 48),
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    final m = message;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WxSpace.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WxSpace.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: WxColors.systemMessageBg,
            borderRadius: BorderRadius.circular(WxRadius.xs),
          ),
          child: Text(
            m.text ?? '',
            style: const TextStyle(
              fontSize: WxFontSize.small,
              color: WxColors.systemMessageText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupNotice(BuildContext context) {
    final m = message;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WxSpace.md,
        vertical: WxSpace.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(WxSpace.md),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(WxRadius.sm),
          border: Border.all(color: const Color(0xFFFFE0A0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.campaign,
                  size: 16,
                  color: Color(0xFFD89B45),
                ),
                const SizedBox(width: WxSpace.xs),
                Text(
                  '${m.senderName ?? "群主"} 修改了群公告',
                  style: const TextStyle(
                    fontSize: WxFontSize.small,
                    color: Color(0xFFD89B45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: WxSpace.xs),
            Text(
              m.groupNoticeText ?? '',
              style: const TextStyle(
                fontSize: WxFontSize.body,
                color: WxColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeHeader(BuildContext context) {
    final m = message;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WxSpace.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WxSpace.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: WxColors.systemMessageBg,
            borderRadius: BorderRadius.circular(WxRadius.xs),
          ),
          child: Text(
            _formatTimeLabel(m.time),
            style: const TextStyle(
              fontSize: WxFontSize.small,
              color: WxColors.systemMessageText,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tDay = DateTime(t.year, t.month, t.day);
    final diff = today.difference(tDay).inDays;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    if (diff == 0) return '今天 $hh:$mm';
    if (diff == 1) return '昨天 $hh:$mm';
    if (diff > 1 && diff < 7) {
      const wk = ['一', '二', '三', '四', '五', '六', '日'];
      return '周${wk[t.weekday - 1]} $hh:$mm';
    }
    if (t.year == now.year) {
      return '${t.month}-${t.day.toString().padLeft(2, "0")} $hh:$mm';
    }
    return '${t.year}-${t.month.toString().padLeft(2, "0")}-${t.day.toString().padLeft(2, "0")}';
  }

  // ---- 交互 ----

  void _showMessageActionSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: WxColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(WxRadius.lg)),
      ),
      builder: (ctx) {
        final items = <_SheetItem>[
          const _SheetItem(icon: Icons.undo, label: '撤回', value: 'revoke'),
          const _SheetItem(
            icon: Icons.forward,
            label: '转发',
            value: 'forward',
          ),
          const _SheetItem(
            icon: Icons.star_border,
            label: '收藏',
            value: 'collect',
          ),
          const _SheetItem(icon: Icons.copy, label: '复制', value: 'copy'),
          const _SheetItem(
            icon: Icons.delete_outline,
            label: '删除',
            value: 'delete',
          ),
          const _SheetItem(
            icon: Icons.checklist,
            label: '多选',
            value: 'multi',
          ),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final it in items) ...[
                ListTile(
                  leading: Icon(it.icon, color: WxColors.textPrimary),
                  title: Text(it.label),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _toast(context, '${it.label} (Mock)');
                  },
                ),
                if (it != items.last) const Divider(height: 0.5),
              ],
              const SizedBox(height: WxSpace.sm),
            ],
          ),
        );
      },
    );
  }

  void _toast(BuildContext context, String msg) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 100,
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
    Future.delayed(const Duration(milliseconds: 1200), entry.remove);
  }

  void _openImagePreview(BuildContext context, Message m) {
    if (m.imageUrl == null) return;
    context.push(
      '/image-preview',
      extra: {
        'url': m.imageUrl,
        'fromMe': m.direction == MessageDirection.self,
      },
    );
  }
}

class _SheetItem {
  final IconData icon;
  final String label;
  final String value;
  const _SheetItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
