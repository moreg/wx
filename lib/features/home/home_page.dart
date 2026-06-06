// 主框架 4 Tab 容器
//
// 用 [IndexedStack] 包裹 4 个 Tab 页面以保留各 Tab 的内部状态
// （切 Tab 不重建）。当前 Tab 索引写入 prefs，App 启动时恢复。
//
// 4 个 Tab 都是占位页（ChatListPage / ContactsPage / DiscoverPage /
// MePage），具体内容由各自 Track 负责实现。本文件只负责壳。
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/design_tokens.dart';
import '../chats/chat_list_page.dart';
import '../contacts/contacts_page.dart';
import '../discover/discover_page.dart';
import '../me/me_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _kTabIndexPrefsKey = 'home_tab_index';

  static const List<_TabSpec> _tabs = <_TabSpec>[
    _TabSpec(
      label: '微信',
      icon: 'assets/icons/wechat-outlined.svg',
      activeIcon: 'assets/icons/wechat-filled.svg',
    ),
    _TabSpec(
      label: '通讯录',
      icon: 'assets/icons/address-book-outlined.svg',
      activeIcon: 'assets/icons/address-book-filled.svg',
    ),
    _TabSpec(
      label: '发现',
      icon: 'assets/icons/discover-outlined.svg',
      activeIcon: 'assets/icons/discover-filled.svg',
    ),
    _TabSpec(
      label: '我',
      icon: 'assets/icons/people-outlined.svg',
      activeIcon: 'assets/icons/people-filled.svg',
    ),
  ];

  int _index = 0;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _restoreTabIndex();
  }

  Future<void> _restoreTabIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_kTabIndexPrefsKey) ?? 0;
      if (!mounted) return;
      setState(() {
        _index = saved.clamp(0, _tabs.length - 1);
        _restored = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _restored = true);
    }
  }

  Future<void> _persistTabIndex(int i) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kTabIndexPrefsKey, i);
    } catch (_) {
      // 静默失败：tab 切换不应阻塞
    }
  }

  void _onTap(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _persistTabIndex(i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack 一次性构建所有子节点并按 index 显示，
      // 切 Tab 不重建各 Tab 内部状态。
      body: IndexedStack(
        index: _restored ? _index : 0,
        children: const <Widget>[
          ChatListPage(),
          ContactsPage(),
          DiscoverPage(),
          MePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        items: [
          for (final t in _tabs)
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                t.icon,
                width: WxIconSize.large,
                height: WxIconSize.large,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                t.activeIcon,
                width: WxIconSize.large,
                height: WxIconSize.large,
                colorFilter: const ColorFilter.mode(
                  WxColors.green,
                  BlendMode.srcIn,
                ),
              ),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final String icon;
  final String activeIcon;
  const _TabSpec({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
