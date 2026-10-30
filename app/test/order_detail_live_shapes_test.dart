import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mintzer/live/live_order_adapter.dart';
import 'package:mintzer/live/live_order_json.dart';
import 'package:mintzer/mock/session.dart';
import 'package:mintzer/models/mock_order.dart';
import 'package:mintzer/screens/order_detail_screen.dart';
import 'package:mintzer/theme/app_theme.dart';

/// Crash-safe Play gate: pump Order detail for live Hostinger shapes (no live HTTP).
void main() {
  setUp(() {
    // Empty token → Order detail / orders must not kick live refresh timers.
    MockSession.authToken = '';
    MockSession.userId = 0;
    MockSession.activeDeal.value = null;
    MockSession.orders.value = [];
  });

  tearDown(() {
    MockSession.orders.value = [];
  });

  List<Map<String, dynamic>> liveShapes() {
    final file = File('assets/live/live_mapper_shapes_export.json');
    expect(file.existsSync(), isTrue);
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final rows = decoded['rows'] as List<dynamic>;
    return [for (final r in rows) Map<String, dynamic>.from(r as Map)];
  }

  MockOrder orderFor(String label) {
    final map = liveShapes().firstWhere((r) => r['_label'] == label);
    final order = liveRowToMockOrder(liveOrderRowFromJson(map));
    expect(order, isNotNull, reason: label);
    return order!;
  }

  for (final label in ['tracking_due', 'invoice_due', 'already_paid']) {
    testWidgets('Order detail opens ($label) without crash', (tester) async {
      final order = orderFor(label);
      MockSession.orders.value = [order];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: OrderDetailScreen(order: order),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byType(OrderDetailScreen), findsOneWidget);
      // Scrollable body mounted (rail / money / actions) — proves paint without red screen.
      expect(find.byType(Scrollable), findsWidgets);
    });
  }
}
