import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wx_clone/features/login/account_login_page.dart';
import 'package:wx_clone/features/login/phone_login_page.dart';
import 'package:wx_clone/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const WxApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Login forms fit on compact screens', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 700);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PhoneLoginPage()));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const MaterialApp(home: AccountLoginPage()));
    expect(tester.takeException(), isNull);
  });
}
