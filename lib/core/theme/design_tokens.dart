// WeChat design tokens — 1:1 visual fidelity
// All colors, sizes, fonts aligned with WeChat iOS official UI

import 'package:flutter/material.dart';

class WxColors {
  // 品牌色
  static const Color green = Color(0xFF07C160); // 微信绿
  static const Color greenDark = Color(0xFF06AD56);
  static const Color greenPress = Color(0xFF1A8F4F);

  // 链接色
  static const Color linkBlue = Color(0xFF576B95);
  static const Color linkBlueDark = Color(0xFF45547A);

  // 背景
  static const Color bg = Color(0xFFEDEDED); // 聊天/列表主背景
  static const Color bgLight = Color(0xFFF7F7F7); // 顶部导航栏
  static const Color card = Color(0xFFFFFFFF);
  static const Color overlay = Color(0x66000000); // 模态遮罩

  // 消息气泡
  static const Color bubbleMe = Color(0xFF95EC69); // 自己消息
  static const Color bubbleOther = Color(0xFFFFFFFF); // 对方消息

  // 文字
  static const Color textPrimary = Color(0xFF181818);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textTertiary = Color(0xFFB2B2B2);
  static const Color textHint = Color(0xFFBFBFBF);
  static const Color textOnGreen = Color(0xFFFFFFFF);

  // 分割线
  static const Color divider = Color(0xFFE5E5E5);
  static const Color dividerLight = Color(0xFFEDEDED);

  // 状态色
  static const Color income = Color(0xFF07C160); // 收入绿
  static const Color expense = Color(0xFFE64340); // 支出红
  static const Color warning = Color(0xFFFA9D3B);
  static const Color unread = Color(0xFFFA5151); // 未读红点

  // 启动页
  static const Color splashBg = Color(0xFFFFFFFF);
  static const Color splashText = Color(0xFF181818);
  static const Color splashSubText = Color(0xFF888888);
  static const Color splashVersion = Color(0xFFB2B2B2);

  // 系统
  static const Color systemMessageBg = Color(0xCCEDEDED); // 系统消息背景（半透明）
  static const Color systemMessageText = Color(0xFF888888);
}

class WxSpace {
  // 间距系统（基于 4dp 网格）
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double huge = 32;
  static const double giant = 48;
}

class WxRadius {
  // 圆角系统
  static const double none = 0;
  static const double xs = 2;
  static const double sm = 4; // 消息气泡、输入框
  static const double md = 6; // 头像
  static const double lg = 8; // 卡片
  static const double xl = 12;
  static const double round = 999; // 圆形（用于头像等）
}

class WxFontSize {
  static const double caption = 10;
  static const double small = 12;
  static const double body = 14;
  static const double bodyLarge = 15;
  static const double title = 16;
  static const double titleLarge = 17;
  static const double headline = 18;
  static const double display = 20;
  static const double huge = 24;
  static const double splash = 28; // 启动页"微信"
}

class WxFontWeight {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

class WxIconSize {
  static const double tiny = 12;
  static const double small = 16;
  static const double medium = 20;
  static const double large = 24; // Tab 栏图标
  static const double xlarge = 32;
  static const double huge = 48;
}

class WxAvatarSize {
  static const double xs = 32; // 列表小头像
  static const double sm = 40; // 列表标准
  static const double md = 48; // 聊天详情
  static const double lg = 64; // 个人页
  static const double xl = 96; // 启动页 / 个人详情大图
}

class WxElevation {
  static const double none = 0;
  static const double sm = 1;
  static const double md = 2;
  static const double lg = 4;
}
