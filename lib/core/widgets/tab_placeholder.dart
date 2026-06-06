// 通用 Tab 占位
//
// 4 Tab 的壳统一显示这个占位。后续各 Track 替换时直接换成自己的页面即可。
import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

class TabPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const TabPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 80, color: WxColors.textHint),
          const SizedBox(height: WxSpace.lg),
          Text(
            title,
            style: const TextStyle(
              fontSize: WxFontSize.title,
              color: WxColors.textSecondary,
            ),
          ),
          const SizedBox(height: WxSpace.xs),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: WxFontSize.body,
              color: WxColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
