import '../models/mock_ticket.dart';

/// Map live `getticket` row → [MockTicket]. Never throws.
/// Additive `replies` when table exists; else single opening message.
MockTicket? liveTicketFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  try {
    final id = json['id'];
    final idStr = id == null ? '' : id.toString().trim();
    if (idStr.isEmpty) return null;

    final subject = (json['subject'] ?? '').toString().trim();
    final message = (json['message'] ?? '').toString().trim();
    final statusRaw = (json['ticket_status'] ?? '').toString().trim();
    final created = _parseDate(json['created_at']) ?? DateTime.now();
    final supports = json['supports_replies'] == true ||
        json['supports_replies'] == 1 ||
        json['supports_replies'] == '1';

    final messages = <TicketMessage>[];
    if (message.isNotEmpty) {
      messages.add(TicketMessage(fromYou: true, text: message, at: created));
    }
    final rawReplies = json['replies'];
    if (rawReplies is List) {
      for (final item in rawReplies) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final text = (m['message'] ?? '').toString().trim();
        if (text.isEmpty) continue;
        final fromUser = m['from_user'] == true || m['from_user'] == 1 || m['from_user'] == '1';
        messages.add(TicketMessage(
          fromYou: fromUser,
          text: text,
          at: _parseDate(m['created_at']) ?? created,
        ));
      }
    }

    final unread = messages.isNotEmpty && !messages.last.fromYou;
    final orderRef = _orderRefFrom(json, message);

    return MockTicket(
      id: 'TKT-$idStr',
      subject: subject.isEmpty ? 'Support' : subject,
      category: subject.isEmpty ? 'other' : subject.toLowerCase(),
      orderId: orderRef,
      status: _mapStatus(statusRaw),
      created: created,
      answers: const [],
      messages: messages,
      unread: unread,
      liveRemote: true,
      supportsReplies: supports,
    );
  } catch (_) {
    return null;
  }
}

List<MockTicket> liveTicketsFromList(dynamic data) {
  if (data is! List) return const [];
  final out = <MockTicket>[];
  final seen = <String>{};
  for (final item in data) {
    Map<String, dynamic>? map;
    if (item is Map<String, dynamic>) {
      map = item;
    } else if (item is Map) {
      map = Map<String, dynamic>.from(item);
    }
    final t = liveTicketFromJson(map);
    if (t == null) continue;
    if (!seen.add(t.id)) continue;
    out.add(t);
  }
  return out;
}

TicketStatus _mapStatus(String raw) {
  final s = raw.toLowerCase().trim();
  if (s.contains('complete') || s.contains('resolved') || s.contains('closed')) {
    return TicketStatus.resolved;
  }
  if (s.contains('process') || s.contains('escalat') || s.contains('progress')) {
    return TicketStatus.inProgress;
  }
  return TicketStatus.submitted;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s.replaceFirst(' ', 'T'));
}

/// Prefer API `order_ref` / `order_id`; else parse opening line `Order ORD… · storeId`.
String _orderRefFrom(Map<String, dynamic> json, String message) {
  for (final key in const ['order_ref', 'order_id', 'orderId', 'accept_order_id']) {
    final v = (json[key] ?? '').toString().trim();
    if (v.isNotEmpty && v != '—') return v;
  }
  final m = RegExp(
    r'^Order\s+([^\n]+)',
    caseSensitive: false,
    multiLine: true,
  ).firstMatch(message.trim());
  if (m == null) return '';
  final rest = m.group(1)!.trim();
  if (rest.isEmpty) return '';
  final parts = rest
      .split(RegExp(r'\s*[·/|,]\s*'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty && e != '—')
      .toList();
  if (parts.isEmpty) return rest;
  for (final p in parts) {
    if (p.toUpperCase().startsWith('ORD')) return p;
  }
  return parts.first;
}
