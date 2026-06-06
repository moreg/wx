import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/splash/splash_page.dart';
import '../features/login/login_page.dart';
import '../features/login/phone_login_page.dart';
import '../features/home/home_page.dart';
import '../features/pay/pay_page.dart';
import '../features/wallet/wallet_page.dart';
import '../features/bills/bill_list_page.dart';
import '../features/bills/bill_detail_page.dart';
import '../features/bills/bill_filter_page.dart';
import '../features/bills/bill_stats_page.dart';
import '../features/bills/bill_import_page.dart';
import '../features/chats/chat_list_page.dart';
import '../features/chats/chat_detail_page.dart';
import '../features/contacts/contacts_page.dart';
import '../features/discover/discover_page.dart';
import '../features/me/me_page.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/about_page.dart';
import '../features/bills/widgets/image_preview.dart';

import 'theme/design_tokens.dart';

class WxRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // 启动页
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),

      // 登录
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginPage()),
        routes: [
          // 点首页"登录"后进入的表单页
          GoRoute(
            path: 'phone',
            builder: (context, state) => const PhoneLoginPage(),
          ),
        ],
      ),

      // 主框架（4 Tab）
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),

      // 聊天详情（从聊天列表进入）
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatDetailPage(chatId: chatId);
        },
      ),

      // 支付/服务
      GoRoute(path: '/pay', builder: (context, state) => const PayPage()),

      // 钱包
      GoRoute(path: '/wallet', builder: (context, state) => const WalletPage()),

      // 账单相关
      GoRoute(
        path: '/bills',
        builder: (context, state) => const BillListPage(),
        routes: [
          GoRoute(
            path: 'filter',
            builder: (context, state) => const BillFilterPage(),
          ),
          GoRoute(
            path: 'stats',
            builder: (context, state) => const BillStatsPage(),
          ),
          GoRoute(
            path: 'import',
            builder: (context, state) => const BillImportPage(),
          ),
          GoRoute(
            path: 'detail/:billId',
            builder: (context, state) {
              final billId = state.pathParameters['billId']!;
              return BillDetailPage(billId: billId);
            },
          ),
        ],
      ),

      // 聊天列表
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ChatListPage(),
      ),

      // 通讯录
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactsPage(),
      ),

      // 发现
      GoRoute(
        path: '/discover',
        builder: (context, state) => const DiscoverPage(),
      ),

      // 我
      GoRoute(path: '/me', builder: (context, state) => const MePage()),

      // 设置
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),

      // 关于微信
      GoRoute(path: '/about', builder: (context, state) => const AboutPage()),

      // 图片预览
      GoRoute(
        path: '/image-preview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ImagePreviewPage(
            imageUrl: extra?['url'] as String? ?? '',
            fromMe: extra?['fromMe'] as bool? ?? false,
          );
        },
      ),
    ],
  );
}

class WxTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: WxColors.green,
      scaffoldBackgroundColor: WxColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: WxColors.bgLight,
        foregroundColor: WxColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: WxFontSize.title,
          fontWeight: WxFontWeight.medium,
          color: WxColors.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: WxColors.card,
        selectedItemColor: WxColors.green,
        unselectedItemColor: WxColors.textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: WxElevation.sm,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: WxColors.textPrimary,
          fontSize: WxFontSize.bodyLarge,
        ),
        bodyMedium: TextStyle(
          color: WxColors.textPrimary,
          fontSize: WxFontSize.body,
        ),
        bodySmall: TextStyle(
          color: WxColors.textSecondary,
          fontSize: WxFontSize.small,
        ),
        titleLarge: TextStyle(
          color: WxColors.textPrimary,
          fontSize: WxFontSize.titleLarge,
          fontWeight: WxFontWeight.medium,
        ),
        titleMedium: TextStyle(
          color: WxColors.textPrimary,
          fontSize: WxFontSize.title,
          fontWeight: WxFontWeight.medium,
        ),
        titleSmall: TextStyle(
          color: WxColors.textPrimary,
          fontSize: WxFontSize.body,
          fontWeight: WxFontWeight.medium,
        ),
        labelLarge: TextStyle(
          color: WxColors.textPrimary,
          fontSize: WxFontSize.body,
        ),
        labelMedium: TextStyle(
          color: WxColors.textSecondary,
          fontSize: WxFontSize.small,
        ),
        labelSmall: TextStyle(
          color: WxColors.textTertiary,
          fontSize: WxFontSize.caption,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: WxColors.divider,
        thickness: 0.5,
        space: 0,
      ),
      splashColor: WxColors.dividerLight,
      highlightColor: WxColors.dividerLight,
    );
  }
}
