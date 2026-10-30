import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/orders_api.dart';
import '../api/profile_api.dart';
import '../config/app_config.dart';
import '../mock/session.dart';
import '../models/mock_order.dart';
import 'live_fixtures.dart';
import 'live_order_adapter.dart';
import 'live_order_json.dart';
import 'live_order_row.dart';
import 'order_mapper.dart';

/// Source of orders for the shell.
/// Live API when signed in · else fixtures / dump.
class OrdersRepository {
  OrdersRepository._();
  static final instance = OrdersRepository._();

  static const _cacheKey = 'mintzer_orders_cache_v1';

  /// When set, [fetchOrders] prefers this JSON list (staging dump / HTTP body).
  List<Map<String, dynamic>>? remoteJson;

  Future<bool>? _inFlight;

  List<MockOrder> fetchOrders() {
    // Live-API mode: never inject fake must-test rows (Play safety).
    final List<LiveOrderRow> rows;
    if (remoteJson != null) {
      rows = liveOrderRowsFromList(remoteJson);
    } else if (AppConfig.useLiveOrdersApi) {
      rows = const [];
    } else if (AppConfig.useLiveDumpFixtures) {
      rows = List<LiveOrderRow>.from(kMustTestLiveRows);
    } else {
      rows = List<LiveOrderRow>.from(kMustTestLiveRows);
    }

    final out = <MockOrder>[];
    for (final row in rows) {
      final step = mapLiveOrderSafe(row);
      if (step == RailStep.hide) continue;
      final o = liveRowToMockOrder(row);
      if (o != null) out.add(o);
    }
    return out;
  }

  /// Restore last good order list before first paint (avoids Completed empty flash).
  Future<void> hydrateFromCache() async {
    if (!AppConfig.useLiveOrdersApi) return;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      loadRemoteJson(decoded);
      MockSession.reloadOrdersFromRepo();
    } catch (e) {
      debugPrint('Orders cache hydrate failed: $e');
    }
  }

  /// Pull from `POST /getOrderList` and refresh [MockSession.orders].
  Future<bool> refreshFromLiveApi() {
    if (!AppConfig.useLiveOrdersApi) return Future.value(false);
    final existing = _inFlight;
    if (existing != null) return existing;
    final run = _refreshBody();
    _inFlight = run.whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  Future<bool> _refreshBody() async {
    final token = MockSession.authToken;
    if (token.isEmpty) {
      // Signed out — clear. Signed-in empty API must not wipe cache (handled below).
      return false;
    }

    // Bank is nice-to-have — never block / fail the order list on it.
    try {
      await ProfileApi.instance.refreshBankIntoSession(authToken: token);
    } catch (_) {}

    Object? lastErr;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
      try {
        final list = await OrdersApi.instance.fetchOrderList(
          authToken: token,
          pageSize: 200,
        );

        // Transient empty — keep last good list (fixes Completed needing 2–3 retries).
        if (list.isEmpty && remoteJson != null && remoteJson!.isNotEmpty) {
          debugPrint('OrdersApi returned empty — keeping ${remoteJson!.length} cached orders');
          MockSession.reloadOrdersFromRepo();
          return true;
        }

        loadRemoteJson(list);
        MockSession.reloadOrdersFromRepo();
        if (list.isNotEmpty) {
          await _persistCache(list);
        }
        return true;
      } catch (e, st) {
        lastErr = e;
        debugPrint('OrdersApi refresh attempt ${attempt + 1} failed: $e\n$st');
      }
    }

    debugPrint('OrdersApi refresh gave up: $lastErr');
    // Keep last remoteJson — never wipe on failure.
    MockSession.reloadOrdersFromRepo();
    return false;
  }

  Future<void> _persistCache(List<Map<String, dynamic>> list) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_cacheKey, jsonEncode(list));
    } catch (_) {}
  }

  /// Load a staging/API dump. Malformed items are skipped via safe parse.
  void loadRemoteJson(List<dynamic> data) {
    remoteJson = data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  void clearRemote() => remoteJson = null;

  /// Offline live rows from `Phpadmin/orders.sql` extract. No network.
  Future<void> loadBundledLiveDump() async {
    if (!AppConfig.useLiveDumpFixtures) return;
    final raw = await rootBundle.loadString(AppConfig.liveDumpAsset);
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      loadRemoteJson(decoded);
    }
  }
}
