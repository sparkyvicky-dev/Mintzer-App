import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/notifications_api.dart';
import '../config/app_config.dart';
import '../mock/session.dart';

/// Live `getnotifications` → [MockSession.notifications].
class NotificationsRepository {
  NotificationsRepository._();
  static final instance = NotificationsRepository._();

  static const _cacheKey = 'mintzer_notifications_cache_v1';

  bool _loading = false;

  bool get _canLive =>
      AppConfig.useLiveNotificationsApi && MockSession.authToken.isNotEmpty;

  Future<void> hydrateFromCache() async {
    if (!AppConfig.useLiveNotificationsApi) return;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final list = <MockNotification>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final n = _fromJson(Map<String, dynamic>.from(item));
        if (n != null) list.add(n);
      }
      if (list.isEmpty) return;
      MockSession.notifications.value = list;
    } catch (_) {}
  }

  Future<void> refreshFromLiveApi({bool force = false}) async {
    if (!_canLive) return;
    if (_loading && !force) return;
    _loading = true;
    try {
      final raw = await NotificationsApi.instance.fetchNotifications(
        authToken: MockSession.authToken,
      );
      final list = <MockNotification>[];
      for (final m in raw) {
        final n = _fromJson(m);
        if (n != null) list.add(n);
      }
      if (list.isEmpty && MockSession.notifications.value.isNotEmpty) return;
      MockSession.notifications.value = list;
      if (raw.isNotEmpty) {
        try {
          final p = await SharedPreferences.getInstance();
          await p.setString(_cacheKey, jsonEncode(raw));
        } catch (_) {}
      }
    } catch (_) {
      // Keep last list.
    } finally {
      _loading = false;
    }
  }

  Future<void> markAllReadLive() async {
    MockSession.markAllNotificationsRead();
    if (!_canLive) return;
    await NotificationsApi.instance.markAllRead(authToken: MockSession.authToken);
  }

  Future<void> markOneReadLive(MockNotification n) async {
    MockSession.markNotificationRead(n.id);
    if (!_canLive) return;
    final id = int.tryParse(n.id.replaceAll(RegExp(r'\D'), ''));
    if (id == null) return;
    await NotificationsApi.instance.markOneRead(
      authToken: MockSession.authToken,
      notificationId: id,
    );
  }

  /// Clear wipes inbox for real — server delete when live, else local only.
  Future<void> clearAllLive() async {
    MockSession.clearNotifications();
    if (!_canLive) return;
    try {
      await NotificationsApi.instance.clearAll(authToken: MockSession.authToken);
    } catch (_) {
      // Local already empty; next refresh may refill until server catches up.
    }
  }

  static MockNotification? _fromJson(Map<String, dynamic> json) {
    try {
      final idRaw = json['id'];
      final id = idRaw == null ? '' : idRaw.toString().trim();
      if (id.isEmpty) return null;
      final title = (json['title'] ?? '').toString().trim();
      var body = (json['content'] ?? json['body'] ?? '').toString().trim();
      final isRead = json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1';
      final created = _parseDate(json['date'] ?? json['created_at']) ?? DateTime.now();

      var ref = '';
      final ticketMarker = RegExp(r'\[ticket:(\d+)\]\s*', caseSensitive: false).firstMatch(body);
      if (ticketMarker != null) {
        ref = 'TKT-${ticketMarker.group(1)}';
        body = body.substring(ticketMarker.end).trim();
      } else {
        final titleTicket = RegExp(r'#(\d+)').firstMatch(title);
        if (titleTicket != null) ref = 'TKT-${titleTicket.group(1)}';
      }

      final kind = ref.isNotEmpty
          ? NotificationKind.ticket
          : _guessKind('$title $body');
      final action = switch (kind) {
        NotificationKind.ticket => 'ticket',
        NotificationKind.order => 'order',
        NotificationKind.payout => 'wallet',
        NotificationKind.deal => 'home',
        NotificationKind.system => 'home',
      };

      return MockNotification(
        id: id,
        title: title.isEmpty ? 'Mintzer' : title,
        body: body.isEmpty ? 'Tap to open' : body,
        kind: kind,
        action: action,
        ref: ref,
        unread: !isRead,
        created: created,
      );
    } catch (_) {
      return null;
    }
  }

  static NotificationKind _guessKind(String hay) {
    final s = hay.toLowerCase();
    if (s.contains('ticket') ||
        s.contains('support') ||
        s.contains('query') ||
        s.contains('mintzer replied') ||
        s.contains('replied')) {
      return NotificationKind.ticket;
    }
    if (s.contains('payout') || s.contains('paid') || s.contains('utr') || s.contains('bank')) {
      return NotificationKind.payout;
    }
    if (s.contains('deal') || s.contains('offer') || s.contains('live now') || s.contains('stock')) {
      return NotificationKind.deal;
    }
    if (s.contains('order') ||
        s.contains('ship') ||
        s.contains('deliver') ||
        s.contains('invoice') ||
        s.contains('tracking') ||
        s.contains('otp')) {
      return NotificationKind.order;
    }
    return NotificationKind.system;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s.replaceFirst(' ', 'T'));
  }
}
