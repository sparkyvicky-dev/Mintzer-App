import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../live/tickets_repository.dart';
import '../live/deals_repository.dart';
import '../mock/session.dart';
import '../models/deal.dart';
import '../models/mock_ticket.dart';
import '../screens/deal_detail_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/place_order_screen.dart';
import '../screens/ticket_detail_screen.dart';
import '../screens/tickets_screen.dart';

/// Global navigator for FCM / local-notification taps (phone tray → screen).
class MintzerNav {
  MintzerNav._();
  static final key = GlobalKey<NavigatorState>();

  static NavigatorState? get nav => key.currentState;
}

/// Route phone-tray pushes to the right screen.
class PushRouter {
  PushRouter._();

  static bool _busy = false;

  static Future<void> handleData(Map<String, dynamic> data) async {
    if (data.isEmpty) return;
    if (_busy) return;
    _busy = true;
    try {
      developer.log('PushRouter data=$data', name: 'mintzer.push');
      final type = (data['type'] ?? '').toString().trim().toLowerCase();
      final ticketId = _first(data, const ['ticket_id', 'ticketId', 'ticket']);
      final orderId = _first(data, const ['order_id', 'orderId', 'order']);
      final dealId = _first(data, const ['deal_id', 'dealId', 'deal']);

      // Wait until navigator is ready (cold start from tray).
      for (var i = 0; i < 40; i++) {
        if (MintzerNav.nav != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      final nav = MintzerNav.nav;
      if (nav == null) return;

      if (MockSession.authToken.isEmpty) {
        nav.pushNamedAndRemoveUntil('/login', (_) => false);
        return;
      }

      if (type.contains('ticket') || ticketId != null) {
        await _openTicket(nav, ticketId);
        return;
      }
      if (type.contains('order') ||
          type.contains('tracking') ||
          type.contains('otp') ||
          type.contains('invoice') ||
          type.contains('payment') ||
          orderId != null) {
        await _openOrder(nav, orderId);
        return;
      }
      if (type.contains('deal') || dealId != null) {
        await _openDeal(nav, dealId);
        return;
      }
      if (type == 'general' || type == 'in_app') {
        await nav.push(MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()));
        return;
      }
      // Fallback: open bell inbox.
      await nav.push(MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()));
    } catch (e, st) {
      developer.log('PushRouter failed: $e\n$st', name: 'mintzer.push');
    } finally {
      _busy = false;
    }
  }

  /// Payload from local notification tap (JSON string or plain id).
  static Future<void> handlePayload(String? payload) async {
    if (payload == null || payload.trim().isEmpty) return;
    final raw = payload.trim();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        await handleData(Map<String, dynamic>.from(decoded));
        return;
      }
    } catch (_) {}
    // Plain ticket / order id fallback.
    if (RegExp(r'^\d+$').hasMatch(raw)) {
      await handleData({'ticket_id': raw, 'type': 'ticket.reply'});
    }
  }

  static String? _first(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s != 'null' && s != '0') return s;
    }
    return null;
  }

  static Future<void> _openTicket(NavigatorState nav, String? ticketId) async {
    if (AppConfig.useLiveTicketsApi && MockSession.authToken.isNotEmpty) {
      await TicketsRepository.instance.refreshFromLiveApi(force: true);
    }
    MockTicket? match;
    final needle = (ticketId ?? '').replaceAll(RegExp(r'\D'), '');
    for (final t in MockSession.tickets.value) {
      if (needle.isEmpty) break;
      if (t.id == 'TKT-$needle' || TicketsRepository.liveNumericId(t)?.toString() == needle) {
        match = t;
        break;
      }
    }
    if (match != null) {
      await nav.push(MaterialPageRoute<void>(builder: (_) => TicketDetailScreen(ticket: match!)));
    } else {
      await nav.push(MaterialPageRoute<void>(builder: (_) => const TicketsScreen()));
    }
  }

  static Future<void> _openOrder(NavigatorState nav, String? orderId) async {
    if (orderId != null && orderId.isNotEmpty) {
      final match = MockSession.orders.value.where(
        (o) =>
            o.orderId == orderId ||
            o.mintzerId == orderId ||
            o.orderId.contains(orderId) ||
            (o.liveAcceptOrderId != null && '${o.liveAcceptOrderId}' == orderId),
      );
      if (match.isNotEmpty) {
        final o = match.first;
        if (MockSession.isOpenPlacementOrder(o)) {
          MockSession.resumePlacementFromOrder(o);
          final deal = MockSession.activeDeal.value ?? o.deal;
          await nav.push(MaterialPageRoute<void>(builder: (_) => PlaceOrderScreen(deal: deal)));
          return;
        }
        await nav.push(MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(order: o)));
        return;
      }
    }
    MockSession.tabIndex.value = 1;
  }

  static Future<void> _openDeal(NavigatorState nav, String? dealIdRaw) async {
    final needle = (dealIdRaw ?? '').replaceAll(RegExp(r'\D'), '');
    MockDeal? match;
    if (needle.isNotEmpty) {
      for (final d in MockSession.deals.value) {
        if (d.liveNumericId?.toString() == needle || d.id == 'live_$needle' || d.id == needle) {
          match = d;
          break;
        }
      }
      if (match == null && AppConfig.useLiveDealsApi) {
        await DealsRepository.instance.refreshFromLiveApi(precacheImages: false);
        for (final d in MockSession.deals.value) {
          if (d.liveNumericId?.toString() == needle || d.id == 'live_$needle') {
            match = d;
            break;
          }
        }
      }
    }
    if (match != null) {
      await nav.push(MaterialPageRoute<void>(builder: (_) => DealDetailScreen(deal: match!)));
      return;
    }
    MockSession.tabIndex.value = 0;
  }
}
