import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mintzer/live/live_order_adapter.dart';
import 'package:mintzer/live/live_order_json.dart';
import 'package:mintzer/mock/session.dart';
import 'package:mintzer/models/mock_order.dart';
import 'package:mintzer/screens/order_detail_screen.dart';
import 'package:mintzer/screens/wallet_screen.dart';
import 'package:mintzer/theme/app_theme.dart';

/// On-device crash gate. Prefer Profile → Load must-test if this hang on wireless ADB.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('on-device: tracking + invoice + paid detail + wallet without crash', (tester) async {
    MockSession.authToken = '';
    MockSession.userId = 0;
    MockSession.activeDeal.value = null;

    final raw = await rootBundle.loadString('assets/live/live_mapper_shapes_export.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rows = decoded['rows'] as List<dynamic>;
    final orders = <MockOrder>[];
    for (final item in rows) {
      if (item is! Map) continue;
      final order = liveRowToMockOrder(
        liveOrderRowFromJson(Map<String, dynamic>.from(item)),
      );
      if (order != null) orders.add(order);
    }
    expect(orders.length, greaterThanOrEqualTo(3));
    MockSession.orders.value = orders;

    for (final order in orders) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: OrderDetailScreen(order: order),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(OrderDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: WalletScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(WalletScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
