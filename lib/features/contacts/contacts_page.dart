// 通讯录 Tab — 完整静态 UI
//
// 1:1 复刻微信 iOS 通讯录：搜索栏 + 4 个固定入口 +
// 按字母分组的 30 个 mock 联系人 + 右侧字母索引条。
//
// 字母索引条支持点击 / 长按 / 拖动：手势命中字母后弹中央气泡提示，
// 并将列表滚到该字母分组。
import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../data/models/contact.dart';
import '../../data/repositories/contacts_data.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  static const List<_QuickEntry> _quickEntries = <_QuickEntry>[
    _QuickEntry(icon: Icons.group_outlined, label: '新的朋友', color: Color(0xFFFA9D3B)),
    _QuickEntry(icon: Icons.chat_bubble_outline, label: '仅聊天的朋友', color: Color(0xFF07C160)),
    _QuickEntry(icon: Icons.location_on_outlined, label: '群聊', color: Color(0xFF576B95)),
    _QuickEntry(icon: Icons.bookmark_outline, label: '标签', color: Color(0xFFE64340)),
  ];

  // 字母 -> 在扁平化后 ListView 的索引（用于滚动定位 + 反向查找）
  late final Map<String, int> _letterToIndex;
  // 扁平化的 list 项：包含 quick entry 区块、字母 header、联系人
  late final List<_ListItem> _items;
  // 用于右侧索引条显示的字母集合
  late final List<String> _indexLetters;

  final ScrollController _scrollCtrl = ScrollController();

  // 当前选中的字母（用于中央气泡提示 + 高亮）
  String? _activeLetter;

  // 单个字母 cell 的高度
  static const double _indexCellHeight = 18.0;

  @override
  void initState() {
    super.initState();
    _buildItems();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// 把 contacts 数据 + 4 个固定入口 + 字母 header 摊平到一个 List 里，
  /// 同时记录每个字母的起始位置（用于字母索引跳转）。
  void _buildItems() {
    final List<_ListItem> items = <_ListItem>[];
    final Map<String, int> letterToIndex = <String, int>{};
    final Set<String> seenLetters = <String>{};

    // 1. 搜索栏
    items.add(const _ListItem.searchBar());
    // 2. 4 个固定入口
    for (final e in _quickEntries) {
      items.add(_ListItem.quickEntry(e));
    }
    // 3. 字母分组的联系人
    //    先按 sortKey + pinyin 排序
    final sorted = <Contact>[...kAllContacts]..sort((a, b) {
      final s = a.sortKey.compareTo(b.sortKey);
      if (s != 0) return s;
      return a.pinyin.compareTo(b.pinyin);
    });
    for (final c in sorted) {
      if (seenLetters.add(c.sortKey)) {
        letterToIndex[c.sortKey] = items.length;
        items.add(_ListItem.letterHeader(c.sortKey));
      }
      items.add(_ListItem.contact(c));
    }
    // 4. 底部 padding 让最后一项不贴底
    items.add(const _ListItem.footer());

    _items = items;
    _letterToIndex = letterToIndex;
    // 5. 右侧索引条只显示数据中实际出现过的字母
    _indexLetters = kContactIndexLetters
        .where(seenLetters.contains)
        .toList(growable: false);
  }

  /// 字母索引回调。`letter` 是被选中的字母，hitOffset 是命中位置。
  void _onLetterHit(String letter) {
    if (_activeLetter == letter) return;
    setState(() => _activeLetter = letter);
    final target = _letterToIndex[letter];
    if (target == null) return;
    // 估算每个 item 大约 56dp（headers 矮一点）
    final offset = (target * 56.0).clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.jumpTo(offset);
  }

  void _clearActiveLetter() {
    if (_activeLetter != null) {
      setState(() => _activeLetter = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(title: const Text('通讯录'), centerTitle: true),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            ListView.builder(
              controller: _scrollCtrl,
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                switch (item.kind) {
                  case _ItemKind.searchBar:
                    return const _SearchBar();
                  case _ItemKind.quickEntry:
                    return _QuickEntryRow(entry: item.entry!);
                  case _ItemKind.letterHeader:
                    return _LetterHeader(letter: item.letter!);
                  case _ItemKind.contact:
                    return _ContactTile(contact: item.contact!);
                  case _ItemKind.footer:
                    return const SizedBox(height: WxSpace.huge);
                }
              },
            ),
            // 右侧字母索引条
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _IndexBar(
                letters: _indexLetters,
                activeLetter: _activeLetter,
                cellHeight: _indexCellHeight,
                onLetter: _onLetterHit,
                onCancel: _clearActiveLetter,
              ),
            ),
            // 中央气泡提示
            if (_activeLetter != null)
              IgnorePointer(
                child: Center(child: _LetterBubble(letter: _activeLetter!)),
              ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 索引数据结构
// =====================================================================

enum _ItemKind { searchBar, quickEntry, letterHeader, contact, footer }

class _ListItem {
  final _ItemKind kind;
  final _QuickEntry? entry;
  final String? letter;
  final Contact? contact;

  const _ListItem._({
    required this.kind,
    this.entry,
    this.letter,
    this.contact,
  });

  const _ListItem.searchBar() : this._(kind: _ItemKind.searchBar);
  const _ListItem.quickEntry(_QuickEntry e) : this._(kind: _ItemKind.quickEntry, entry: e);
  const _ListItem.letterHeader(String l) : this._(kind: _ItemKind.letterHeader, letter: l);
  const _ListItem.contact(Contact c) : this._(kind: _ItemKind.contact, contact: c);
  const _ListItem.footer() : this._(kind: _ItemKind.footer);
}

class _QuickEntry {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickEntry({required this.icon, required this.label, required this.color});
}

// =====================================================================
// 搜索栏
// =====================================================================

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      padding: const EdgeInsets.symmetric(
        horizontal: WxSpace.lg,
        vertical: WxSpace.sm,
      ),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: WxColors.bg,
          borderRadius: BorderRadius.circular(WxRadius.sm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: WxSpace.md),
        child: Row(
          children: const [
            Icon(Icons.search, size: 18, color: WxColors.textSecondary),
            SizedBox(width: WxSpace.sm),
            Text(
              '搜索',
              style: TextStyle(
                fontSize: WxFontSize.body,
                color: WxColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 固定入口（4 个）
// =====================================================================

class _QuickEntryRow extends StatelessWidget {
  final _QuickEntry entry;
  const _QuickEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('${entry.label} - TODO'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                duration: const Duration(seconds: 2),
              ),
            );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WxSpace.lg,
            vertical: WxSpace.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(WxRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(entry.icon, color: entry.color, size: 20),
              ),
              const SizedBox(width: WxSpace.md),
              Expanded(
                child: Text(
                  entry.label,
                  style: const TextStyle(
                    fontSize: WxFontSize.bodyLarge,
                    color: WxColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: WxColors.textHint,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// 字母分组 header
// =====================================================================

class _LetterHeader extends StatelessWidget {
  final String letter;
  const _LetterHeader({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: WxColors.bg,
      padding: const EdgeInsets.fromLTRB(
        WxSpace.lg,
        WxSpace.xs,
        WxSpace.lg,
        WxSpace.xs,
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: WxFontSize.body,
          color: WxColors.textSecondary,
        ),
      ),
    );
  }
}

// =====================================================================
// 联系人行
// =====================================================================

class _ContactTile extends StatelessWidget {
  final Contact contact;
  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.card,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('${contact.name} 的详情页 - TODO'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                duration: const Duration(seconds: 2),
              ),
            );
        },
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WxSpace.lg,
              vertical: WxSpace.sm,
            ),
            child: Row(
              children: [
                _AvatarImage(avatar: contact.avatar, name: contact.name),
                const SizedBox(width: WxSpace.md),
                Expanded(
                  child: Text(
                    contact.name,
                    style: const TextStyle(
                      fontSize: WxFontSize.bodyLarge,
                      color: WxColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// 头像
// =====================================================================

class _AvatarImage extends StatelessWidget {
  final String avatar;
  final String name;
  const _AvatarImage({required this.avatar, required this.name});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WxRadius.sm),
      child: Image.asset(
        avatar,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _AvatarFallback(name: name),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final letter = name.isEmpty ? '?' : name.characters.first;
    return Container(
      width: 40,
      height: 40,
      color: WxColors.green.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: WxColors.green,
          fontSize: WxFontSize.title,
          fontWeight: WxFontWeight.medium,
        ),
      ),
    );
  }
}

// =====================================================================
// 右侧字母索引条
// =====================================================================

class _IndexBar extends StatelessWidget {
  final List<String> letters;
  final String? activeLetter;
  final double cellHeight;
  final ValueChanged<String> onLetter;
  final VoidCallback onCancel;

  const _IndexBar({
    required this.letters,
    required this.activeLetter,
    required this.cellHeight,
    required this.onLetter,
    required this.onCancel,
  });

  /// 根据命中位置推算选中的字母
  String? _letterAt(double localY) {
    if (letters.isEmpty) return null;
    final i = (localY / cellHeight).floor();
    if (i < 0 || i >= letters.length) return null;
    return letters[i];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) {
        final l = _letterAt(d.localPosition.dy);
        if (l != null) onLetter(l);
      },
      onVerticalDragUpdate: (d) {
        final l = _letterAt(d.localPosition.dy);
        if (l != null) onLetter(l);
      },
      onTapUp: (_) => onCancel(),
      onTapCancel: onCancel,
      onVerticalDragEnd: (_) => onCancel(),
      onVerticalDragCancel: onCancel,
      child: Container(
        width: 22,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in letters)
              SizedBox(
                height: cellHeight,
                width: 22,
                child: Center(
                  child: Text(
                    l,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: l == activeLetter
                          ? WxFontWeight.semibold
                          : WxFontWeight.regular,
                      color: l == activeLetter
                          ? WxColors.green
                          : WxColors.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 中央字母气泡
// =====================================================================

class _LetterBubble extends StatelessWidget {
  final String letter;
  const _LetterBubble({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(WxRadius.md),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 32,
          color: Colors.white,
          fontWeight: WxFontWeight.medium,
        ),
      ),
    );
  }
}
