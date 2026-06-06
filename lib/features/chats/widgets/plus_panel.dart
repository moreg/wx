// "+" 面板（PLAN §7.9.10）
//
// 6 宫格：图片 / 拍摄 / 语音 / 位置 / 名片 / 文件。
// 点击任一项 toast 提示（Mock 行为）；真实功能不在范围内。
import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

class PlusPanel extends StatelessWidget {
  final ValueChanged<String> onItemTap;
  const PlusPanel({super.key, required this.onItemTap});

  static const List<_PanelItem> _items = <_PanelItem>[
    _PanelItem(icon: Icons.photo_outlined, label: '图片'),
    _PanelItem(icon: Icons.camera_alt_outlined, label: '拍摄'),
    _PanelItem(icon: Icons.mic_none, label: '语音'),
    _PanelItem(icon: Icons.location_on_outlined, label: '位置'),
    _PanelItem(icon: Icons.person_add_alt, label: '名片'),
    _PanelItem(icon: Icons.insert_drive_file_outlined, label: '文件'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WxColors.bgLight,
      padding: const EdgeInsets.symmetric(vertical: WxSpace.lg),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: WxSpace.lg),
        itemCount: _items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: WxSpace.lg,
          crossAxisSpacing: WxSpace.lg,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (ctx, i) {
          final it = _items[i];
          return InkResponse(
            onTap: () => onItemTap(it.label),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: WxColors.card,
                    borderRadius: BorderRadius.circular(WxRadius.md),
                    border: Border.all(color: WxColors.divider),
                  ),
                  child: Icon(it.icon, color: WxColors.textPrimary, size: 28),
                ),
                const SizedBox(height: WxSpace.xs),
                Text(
                  it.label,
                  style: const TextStyle(
                    fontSize: WxFontSize.small,
                    color: WxColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PanelItem {
  final IconData icon;
  final String label;
  const _PanelItem({required this.icon, required this.label});
}
