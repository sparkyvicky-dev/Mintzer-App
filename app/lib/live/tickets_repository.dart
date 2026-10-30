import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_api.dart';
import '../api/tickets_api.dart';
import '../config/app_config.dart';
import '../mock/session.dart';
import '../models/mock_ticket.dart';
import 'live_ticket_adapter.dart';

/// Live tickets → [MockSession.tickets]. Additive; never invents reply threads.
class TicketsRepository {
  TicketsRepository._();
  static final instance = TicketsRepository._();

  static const _cacheKey = 'mintzer_tickets_cache_v1';

  List<TicketSubject> _subjects = const [];
  bool _loading = false;

  List<TicketSubject> get subjects => _subjects;

  bool get _canLive =>
      AppConfig.useLiveTicketsApi && MockSession.authToken.isNotEmpty;

  /// Last ticket list, before the first frame, so an order does not grow a ticket late.
  Future<void> hydrateFromCache() async {
    if (!AppConfig.useLiveTicketsApi) return;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      final list = liveTicketsFromList(decoded);
      if (list.isEmpty) return;
      MockSession.tickets.value = list;
    } catch (_) {}
  }

  Future<void> refreshFromLiveApi({bool force = false}) async {
    if (!_canLive) return;
    if (_loading && !force) return;
    _loading = true;
    try {
      final raw = await TicketsApi.instance.fetchTickets(
        authToken: MockSession.authToken,
      );
      final list = liveTicketsFromList(raw);
      if (list.isEmpty && MockSession.tickets.value.isNotEmpty) return;
      MockSession.tickets.value = list;
      if (raw.isNotEmpty) {
        try {
          final p = await SharedPreferences.getInstance();
          await p.setString(_cacheKey, jsonEncode(raw));
        } catch (_) {}
      }
    } catch (_) {
      // Keep last list — never wipe on soft fail.
    } finally {
      _loading = false;
    }
  }

  Future<List<TicketSubject>> ensureSubjects() async {
    if (!_canLive) return const [];
    if (_subjects.isNotEmpty) return _subjects;
    try {
      _subjects = await TicketsApi.instance.fetchSubjects(
        authToken: MockSession.authToken,
      );
    } catch (_) {
      _subjects = const [];
    }
    return _subjects;
  }

  /// Resolve a UI label to a live `subjects.id` (name contains / equals).
  int? subjectIdForLabel(String label) {
    final needle = label.trim().toLowerCase();
    if (needle.isEmpty || _subjects.isEmpty) return null;

    for (final s in _subjects) {
      if (s.name.toLowerCase() == needle) return s.id;
    }
    for (final s in _subjects) {
      final n = s.name.toLowerCase();
      if (n.contains(needle) || needle.contains(n)) return s.id;
    }
    for (final s in _subjects) {
      if (s.name.toLowerCase().contains('other')) return s.id;
    }
    return _subjects.first.id;
  }

  /// Create via live API then refresh list. Throws [AuthApiException] on hard fail.
  Future<MockTicket?> submitLive({
    required String subjectLabel,
    required String message,
    String? orderRef,
  }) async {
    if (!_canLive) return null;

    await ensureSubjects();
    final sid = subjectIdForLabel(subjectLabel);
    if (sid == null) {
      throw AuthApiException('No ticket topics available. Try again later.');
    }

    final ref = orderRef?.trim() ?? '';
    final buf = StringBuffer();
    if (ref.isNotEmpty && ref != '—') {
      buf.writeln('Order $ref');
    }
    buf.write(message.trim());

    await TicketsApi.instance.addTicket(
      authToken: MockSession.authToken,
      subjectId: sid,
      message: buf.toString().trim(),
      orderRef: ref.isNotEmpty && ref != '—' ? ref : null,
    );
    await refreshFromLiveApi(force: true);

    // Prefer ticket whose orderRef / message mentions this order.
    final list = MockSession.tickets.value;
    if (ref.isNotEmpty && ref != '—') {
      final tokens = ref
          .split(RegExp(r'\s*[·/|,]\s*'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e != '—')
          .toSet();
      for (final t in list) {
        if (tokens.any((n) =>
            t.orderId == n ||
            t.orderId.contains(n) ||
            t.messages.any((m) => m.text.contains(n)))) {
          return t;
        }
      }
    }
    for (final t in list) {
      if (t.subject.toLowerCase().contains(subjectLabel.toLowerCase()) ||
          t.messages.any((m) => m.text.contains(message.trim()))) {
        return t;
      }
    }
    return list.isEmpty ? null : list.first;
  }

  /// Numeric live orders.id from `TKT-123`.
  static int? liveNumericId(MockTicket t) {
    final m = RegExp(r'(\d+)').firstMatch(t.id);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  Future<void> replyLive({required MockTicket ticket, required String message}) async {
    if (!_canLive) throw AuthApiException('Not signed in');
    final id = liveNumericId(ticket);
    if (id == null) throw AuthApiException('Invalid ticket');
    await TicketsApi.instance.addReply(
      authToken: MockSession.authToken,
      ticketId: id,
      message: message,
    );
    await refreshFromLiveApi(force: true);
  }

  Future<void> closeLive({required MockTicket ticket}) async {
    if (!_canLive) throw AuthApiException('Not signed in');
    final id = liveNumericId(ticket);
    if (id == null) throw AuthApiException('Invalid ticket');
    await TicketsApi.instance.closeTicket(
      authToken: MockSession.authToken,
      ticketId: id,
    );
    await refreshFromLiveApi(force: true);
  }
}
