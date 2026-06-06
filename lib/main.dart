import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 状态栏样式：白底黑字
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const WxApp());
}

class WxApp extends StatelessWidget {
  const WxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '微信',
      theme: WxTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: WxRouter.router,
    );
  }
}
