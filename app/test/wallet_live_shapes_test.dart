import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mintzer/live/live_order_adapter.dart';
import 'package:mintzer/live/live_order_json.dart';
import 'package:mintzer/mock/session.dart';
import 'package:mintzer/models/mock_order.dart';
import 'package:mintzer/screens/wallet_screen.dart';
import 'package:mintzer/theme/app_theme.dart';

void main() {
  setUp(() {
    MockSession.authToken = '';
    MockSession.userId = 0;
    MockSession.tabIndex.value = 2;
    MockSession.orders.value = [];
  });

  tearDown(() {
    MockSession.orders.value = [];
  });

  testWidgets('Wallet opens with live tracking+invoice+paid shapes without crash', (tester) async {
    final file = File('assets/live/live_mapper_shapes_export.json');
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final rows = decoded['rows'] as List<dynamic>;
    final orders = <MockOrder>[];
    for (final raw in rows) {
      final o = liveRowToMockOrder(liveOrderRowFromJson(Map<String, dynamic>.from(raw as Map)));
      if (o != null) orders.add(o);
    }
    expect(orders.length, greaterThanOrEqualTo(3));
    MockSession.orders.value = orders;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: WalletScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.byType(WalletScreen), findsOneWidget);
    expect(find.byType(Scrollable), findsWidgets);
  });
}
