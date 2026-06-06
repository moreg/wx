// 表情面板（PLAN §7.9.10）
//
// 8 列 × 4 行 emoji 字符。不做表情商店。
// 点击 emoji 字符后回调给 ChatInputBar 插入到 TextField。
import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

class EmojiPanel extends StatelessWidget {
  final ValueChanged<String> onEmojiTap;
  const EmojiPanel({super.key, required this.onEmojiTap});

  // 32 个常用 emoji（4 行 × 8 列）
  static const List<String> _emojis = <String>[
    '😀', '😁', '😂', '🤣', '😃', '😄', '😅', '😆',
    '😉', '😊', '😋', '😎', '😍', '😘', '😗', '😙',
    '😚', '🙂', '🤗', '🤔', '🤐', '😐', '😑', '😶',
    '🙄', '😏', '😣', '😥', '😮', '🤐', '😯', '😪',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.bgLight,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: WxSpace.sm,
          vertical: WxSpace.md,
        ),
        itemCount: _emojis.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (ctx, i) {
          return InkResponse(
            onTap: () => onEmojiTap(_emojis[i]),
            child: Center(
              child: Text(
                _emojis[i],
                style: const TextStyle(fontSize: 28),
              ),
            ),
          );
        },
      ),
    );
  }
}
