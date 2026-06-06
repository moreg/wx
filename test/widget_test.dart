// Smoke test for the app shell.
//
// 验证应用根 widget 能构建。具体的登录 / 主框架测试由
// Auth Track / Home Track 接手时再补充。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wx_clone/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const WxApp());
    // 只要求构建不崩，具体页面跳转测试交给后续 Track
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
