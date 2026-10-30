enum TicketStatus {
  submitted,
  inProgress,
  resolved,
  closed;

  /// Internal / detail label — list uses [TicketInboxFace] instead.
  String get label => switch (this) {
        TicketStatus.submitted => 'Submitted',
        TicketStatus.inProgress => 'In progress',
        TicketStatus.resolved => 'Resolved',
        TicketStatus.closed => 'Closed',
      };

  bool get isOpen => this == TicketStatus.submitted || this == TicketStatus.inProgress;
  bool get isDone => this == TicketStatus.resolved || this == TicketStatus.closed;
}

/// User-facing inbox status (one primary concept per card).
enum TicketInboxFace {
  waitingForSupport,
  supportReplied,
  yourReplyNeeded,
  resolved;

  String get label => switch (this) {
        TicketInboxFace.waitingForSupport => 'Waiting for support',
        TicketInboxFace.supportReplied => 'Support replied',
        TicketInboxFace.yourReplyNeeded => 'Your reply needed',
        TicketInboxFace.resolved => 'Resolved',
      };

  /// Compact pill on the card (title row).
  String get pill => switch (this) {
        TicketInboxFace.waitingForSupport => 'Open',
        TicketInboxFace.supportReplied => 'Reply',
        TicketInboxFace.yourReplyNeeded => 'Reply',
        TicketInboxFace.resolved => 'Done',
      };
}

class TicketMessage {
  TicketMessage({required this.fromYou, required this.text, required this.at});

  final bool fromYou;
  final String text;
  final DateTime at;
}

class MockTicket {
  MockTicket({
    required this.id,
    required this.subject,
    required this.category,
    required this.orderId,
    required this.status,
    required this.created,
    required this.answers,
    required this.messages,
    this.unread = false,
    this.liveRemote = false,
    this.supportsReplies = false,
  });

  final String id;
  final String subject;
  final String category;
  final String orderId;
  TicketStatus status;
  final DateTime created;
  final List<String> answers;
  final List<TicketMessage> messages;
  bool unread;

  /// From live `getticket`.
  final bool liveRemote;

  /// User-facing 5-digit ticket number (e.g. `48291`).
  String get shortNumber {
    final m = RegExp(r'(\d+)').firstMatch(id);
    if (m == null) return '00000';
    final digits = m.group(1)!;
    if (digits.length >= 5) return digits.substring(digits.length - 5);
    return digits.padLeft(5, '0');
  }

  String get displayNumber => shortNumber;

  /// Live additive replies ready (`supports_replies` + table).
  final bool supportsReplies;

  String get categoryLabel => switch (category) {
        'paid_extra' => 'Payment',
        'canceled' => 'Canceled',
        'color' => 'Product',
        'variant' => 'Product',
        'account' => 'Account',
        'payout' => 'Payout',
        'deal' => 'Deal',
        'app' => 'App',
        'other' => 'Other',
        _ => category.isEmpty ? 'Support' : category[0].toUpperCase() + category.substring(1),
      };

  TicketMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  DateTime get updatedAt => lastMessage?.at ?? created;

  TicketInboxFace get inboxFace {
    if (status.isDone) return TicketInboxFace.resolved;
    final last = lastMessage;
    if (last == null) return TicketInboxFace.waitingForSupport;
    if (!last.fromYou) {
      return unread ? TicketInboxFace.supportReplied : TicketInboxFace.yourReplyNeeded;
    }
    return TicketInboxFace.waitingForSupport;
  }

  /// One-line preview when support (or last) message exists and face wants it.
  String? get previewLine {
    final last = lastMessage;
    if (last == null) return null;
    if (inboxFace == TicketInboxFace.supportReplied || inboxFace == TicketInboxFace.yourReplyNeeded) {
      final t = last.text.trim();
      if (t.isEmpty) return null;
      return t.length > 72 ? '${t.substring(0, 71)}…' : t;
    }
    return null;
  }
}
