import 'dart:convert';

import 'package:flutter/services.dart';

import '../live/live_order_adapter.dart';
import '../live/live_order_json.dart';
import '../mock/session.dart';
import '../models/mock_order.dart';

/// Debug / must-test helper — loads Hostinger-exported shapes into session.
class MustTestShapes {
  MustTestShapes._();

  static const assetPath = 'assets/live/live_mapper_shapes_export.json';

  /// Returns number of orders loaded (0 on failure).
  static Future<int> loadIntoSession() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return 0;
      final rows = decoded['rows'];
      if (rows is! List) return 0;
      final out = <MockOrder>[];
      for (final item in rows) {
        if (item is! Map) continue;
        final order = liveRowToMockOrder(
          liveOrderRowFromJson(Map<String, dynamic>.from(item)),
        );
        if (order != null) out.add(order);
      }
      if (out.isEmpty) return 0;
      MockSession.orders.value = out;
      return out.length;
    } catch (_) {
      return 0;
    }
  }
}
