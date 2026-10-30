import 'dart:async';

import 'package:flutter/material.dart';
import '../api/placements_api.dart';
import '../config/app_config.dart';
import '../live/order_mapper.dart';
import '../live/orders_repository.dart';
import '../models/delivery_address.dart';
import '../models/deal.dart';
import '../models/mock_order.dart';
import '../models/mock_ticket.dart';
import 'sample_deals.dart';
import 'home_promos.dart';
import 'partner_cards.dart';
import 'session_store.dart';
import '../util/format.dart';

/// In-memory mock. KYC/payout already done (seeded demo user).
class MockSession {
  static final activeDeal = ValueNotifier<MockDeal?>(null);
  /// Placement countdown end (set when Accept reserves the deal). Shared Home + Place order.
  static DateTime? placementEndsAt;
  static const placementMinutes = 15;
  /// Live `accept-order` id (orders.id) while placement is open.
  static int? activeAcceptOrderId;
  /// Dealer address reserved / shown on Place order.
  static DeliveryAddress? placementAddress;
  static String? placementGstNumber;

  static int get placementSecLeft {
    final end = placementEndsAt;
    if (end == null) return 0;
    final cap = placementMinutes * 60;
    return end.difference(DateTime.now()).inSeconds.clamp(0, cap * 4);
  }

  static void reserveDeal(
    MockDeal deal, {
    int? acceptOrderId,
    DateTime? endsAt,
    DeliveryAddress? address,
    String? gstNumber,
  }) {
    activeDeal.value = deal;
    activeAcceptOrderId = acceptOrderId;
    placementAddress = address;
    placementGstNumber = gstNumber;
    placementEndsAt = endsAt ?? DateTime.now().add(const Duration(minutes: placementMinutes));
  }

  static void clearPlacement() {
    activeDeal.value = null;
    placementEndsAt = null;
    activeAcceptOrderId = null;
    placementAddress = null;
    placementGstNumber = null;
  }

  /// Rehydrate Place order after kill / Orders “Continue”.
  /// Timer from [order.created] + [placementMinutes] when endsAt unknown.
  static void resumePlacementFromOrder(MockOrder order) {
    final acceptId = order.liveAcceptOrderId;
    if (acceptId != null &&
        activeAcceptOrderId == acceptId &&
        activeDeal.value != null &&
        placementEndsAt != null &&
        placementEndsAt!.isAfter(DateTime.now())) {
      // Same live placement already in memory — keep timer/address.
      activeDeal.value = order.deal;
      return;
    }

    final end = order.created.add(const Duration(minutes: placementMinutes));
    if (!end.isAfter(DateTime.now())) {
      // Past window — clear strip and release server slot. Never grant a new grace.
      expireOpenPlacement(acceptOrderId: acceptId);
      return;
    }

    activeDeal.value = order.deal;
    activeAcceptOrderId = acceptId;
    placementEndsAt = end;
    // Keep existing dealer address if any; Place order falls back to mock rows.
  }

  /// Clear local placement and best-effort auto-delete the live accept.
  static void expireOpenPlacement({int? acceptOrderId}) {
    final id = acceptOrderId ?? activeAcceptOrderId;
    final token = authToken;
    clearPlacement();
    if (AppConfig.useLiveAcceptApi && token.isNotEmpty && id != null) {
      unawaited(
        PlacementsApi.instance.autoDeleteOrder(authToken: token, acceptOrderId: id),
      );
    }
  }

  /// True when this live row is the open Accept (no store Order ID yet).
  /// Past the placement window counts as not open (avoids resurrecting a dead timer).
  /// Instant / link deals have no 15‑min placement timer — never treat as open placement.
  static bool isOpenPlacementOrder(MockOrder o) {
    if (o.canceled || o.paid) return false;
    if (o.deal.isInstantLink) return false;
    if (o.liveRail != null && o.liveRail != RailStep.placement) return false;
    final end = o.created.add(const Duration(minutes: placementMinutes));
    if (!end.isAfter(DateTime.now())) return false;
    if (o.liveRail == RailStep.placement) return true;
    if (!o.hasStoreOrderId && o.liveAcceptOrderId != null) return true;
    return false;
  }

  static final orders = ValueNotifier<List<MockOrder>>(_seedOrders());
  /// Home catalog — live API when on (starts empty); sample only if live deals flag off.
  static final deals = ValueNotifier<List<MockDeal>>(List<MockDeal>.from(_seedDealsPlaceholder()));
  /// Home promo carousel — live `getbanners` when loaded.
  /// Starts empty in the live app so the two built-in slides do not flash first.
  static final homePromos = ValueNotifier<List<HomePromoSlide>>(
    AppConfig.useLiveDealsApi ? <HomePromoSlide>[] : List<HomePromoSlide>.from(kMockHomePromos),
  );
  static final tickets = ValueNotifier<List<MockTicket>>(
    AppConfig.useLiveTicketsApi ? <MockTicket>[] : _seedTickets(),
  );
  static final notifications = ValueNotifier<List<MockNotification>>(
    AppConfig.useLiveNotificationsApi ? <MockNotification>[] : _seedNotifications(),
  );
  /// Shell tab: 0 Home · 1 Orders · 2 Wallet · 3 Profile
  static final tabIndex = ValueNotifier<int>(0);
  /// Home scroll chrome — matches demo header-gone / nav-mini.
  /// 0 expanded · 1 compact · 2 mini (header hidden + pill nav)
  static final homeChrome = ValueNotifier<int>(0);
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  static int successPromoSeq = 0;
  static bool kycDone = false;
  static bool payoutDone = false;
  static String panName = '';
  static String panNumber = '';
  /// Login phone (10 digits, no +91).
  static String phoneDigits = '9876543210';
  /// Sanctum token from live `verify-otp` (empty = not signed in via API).
  static String authToken = '';
  static int? userId;
  /// Preferred display name before KYC / when user sets a nickname.
  static String displayName = '';
  /// Avatar: letter vs photo URL from live profile.
  static bool useLetterAvatar = true;
  /// Absolute URL from `getuserprofile` / `updateProfileImage`.
  static String profilePictureUrl = '';
  static String bankName = '';
  static String bankAccount = '';
  static String bankIfsc = '';
  static String upiId = '';
  /// Live invite code from `getReferralSettings` (`reffereal_code`).
  static String referralCode = '';
  /// Partner Apply catalog from `getBanks` (empty = use designed fallback).
  static final partnerCards = ValueNotifier<List<PartnerCardOffer>>(const []);
  /// Notification prefs (Profile leftovers).
  static bool pushMaster = true;
  static bool pushDeals = true;
  static bool pushOrders = true;
  static bool pushPayments = true;
  /// Home tutorial banner: show on up to [tutorialMaxShows] **visits**.
  /// One ✕ hides for this session; next cold start can show again until max.
  static const tutorialMaxShows = 2;
  static int tutorialDismissCount = 0;
  /// Not persisted — one close must hide immediately (do not require 2 taps).
  static bool tutorialHiddenThisSession = false;

  static bool get showHomeTutorial =>
      !tutorialHiddenThisSession && tutorialDismissCount < tutorialMaxShows;
  /// First Accept: shopping mode gate (demo modalShopMode).
  static bool shopModeAsked = false;
  /// `external` | `inapp`
  static String shopMode = 'external';
  /// Place order checklist collapsed after first dismiss / collapse.
  static bool placeInstructionsSeen = false;
  /// Home: apply this card filter once when returning from Apply for cards.
  /// ValueNotifier so Home paints filtered deals **before** the route finishes popping.
  static final homeCardFilter = ValueNotifier<String?>(null);

  /// Skip the next forced Home deals refresh (View deals should feel instant).
  static bool skipNextHomeDealsRefresh = false;

  /// Locked 5 EN bar: en · hi · kn · ml.
  /// [languageRevision] ticks when the code changes so open screens rebuild.
  static final languageRevision = ValueNotifier<int>(0);
  static String _language = 'en';
  static String get language => _language;
  static set language(String value) {
    final next = switch (value) {
      'hi' || 'kn' || 'ml' => value,
      _ => 'en',
    };
    if (_language == next) return;
    _language = next;
    languageRevision.value++;
  }

  static String get languageLabel => switch (language) {
        'hi' => 'हिन्दी',
        'kn' => 'ಕನ್ನಡ',
        'ml' => 'മലയാളം',
        _ => 'English',
      };

  static String get themeLabel => switch (themeMode.value) {
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
        _ => 'Light',
      };

  static String get ticketsSubtitle {
    final open = tickets.value.where((t) => t.status.isOpen).length;
    if (open == 0) return 'None';
    return '$open open';
  }

  /// Home greeting first name — **PAN only**. Empty until KYC (Home shows plain Morning / Hi).
  static String get greetingFirstName {
    if (!kycDone) return '';
    final raw = panName.trim();
    if (raw.isEmpty) return '';
    // No PAN number yet → treat as not verified (legacy mock leftover).
    if (panNumber.trim().isEmpty) return '';
    // Strip old demo seed names if they somehow persist.
    final lower = raw.toLowerCase();
    if (lower == 'arun' || lower == 'member' || lower == 'there') return '';
    final first = raw.split(RegExp(r'\s+')).firstWhere((p) => p.isNotEmpty, orElse: () => raw);
    final shown = personName(first);
    if (shown.length <= 14) return shown;
    return '${shown.substring(0, 12)}…';
  }

  /// Profile / chrome display — live API name or PAN; never invents a fake first name.
  static String get profileDisplayName {
    final raw = panName.trim().isNotEmpty && panNumber.trim().isNotEmpty
        ? panName.trim()
        : displayName.trim();
    if (raw.isEmpty) return '';
    final lower = raw.toLowerCase();
    if (lower == 'arun' || lower == 'member' || lower == 'there') {
      final fallback = displayName.trim();
      if (fallback.isEmpty || fallback.toLowerCase() == 'arun') return '';
      return _shortFirst(fallback);
    }
    return _shortFirst(raw);
  }

  static String _shortFirst(String raw) {
    final first = personName(raw.split(RegExp(r'\s+')).firstWhere((p) => p.isNotEmpty, orElse: () => raw));
    if (first.length <= 14) return first;
    return '${first.substring(0, 12)}…';
  }

  static String get phoneDisplay {
    final d = phoneDigits.replaceAll(RegExp(r'\D'), '');
    if (d.length == 10) return '+91 ${d.substring(0, 5)} ${d.substring(5)}';
    return '+91 $phoneDigits';
  }

  static int get totalEarned => orders.value
      .where((o) => o.paid && !o.canceled)
      .fold(0, (s, o) => s + o.deal.earn);

  static int get pendingEarn => orders.value
      .where((o) => o.ongoing && o.liveRail != RailStep.placement)
      .where((o) {
        final id = o.orderId.trim();
        return id.isNotEmpty && id != '—';
      })
      .fold(0, (s, o) => s + o.deal.earn);

  static bool get hasActiveOrder =>
      activeDeal.value != null || orders.value.any((o) => o.ongoing);

  static List<MockOrder> _seedOrders() {
    return OrdersRepository.instance.fetchOrders();
  }

  static List<MockDeal> _seedDealsPlaceholder() {
    if (AppConfig.useLiveDealsApi) return const [];
    return List<MockDeal>.from(kSampleDeals);
  }

  /// Private order notes, kept on this phone. Live orders have no note column yet.
  static final orderNotes = <String, String>{};

  static void rememberOrderNote(String orderId, String note) {
    final t = note.trim();
    if (t.isEmpty || t.startsWith('Cancel:')) {
      orderNotes.remove(orderId);
    } else {
      orderNotes[orderId] = t;
    }
    // ignore: unawaited_futures
    SessionStore.saveOrderNotes();
  }

  static void _applySavedNotes(List<MockOrder> list) {
    for (final o in list) {
      final saved = orderNotes[o.id];
      if (saved == null || saved.isEmpty) continue;
      if (o.note.startsWith('Cancel:')) continue;
      o.note = saved;
    }
  }

  /// Reload My Orders from repository (fixtures or staged JSON dump).
  static void reloadOrdersFromRepo() {
    final list = OrdersRepository.instance.fetchOrders();
    _applySavedNotes(list);
    orders.value = list;
    syncOpenPlacementFromOrders();
  }

  /// After a restart the Accept is still on the server, but the in-memory deal is gone.
  /// Put it back so My Orders can show the card instead of a count with an empty list.
  static void syncOpenPlacementFromOrders() {
    // Release stale direct-deal accepts still on the list (server may lag).
    // Never auto-delete Instant / link — those wait for payment verify, not a 15‑min OID timer.
    for (final o in orders.value) {
      if (o.canceled || o.paid || o.hasStoreOrderId || o.liveAcceptOrderId == null) continue;
      if (o.deal.isInstantLink) continue;
      if (o.liveRail != null && o.liveRail != RailStep.placement) continue;
      final end = o.created.add(const Duration(minutes: placementMinutes));
      if (end.isAfter(DateTime.now())) continue;
      expireOpenPlacement(acceptOrderId: o.liveAcceptOrderId);
    }

    if (activeDeal.value != null &&
        placementEndsAt != null &&
        !placementEndsAt!.isAfter(DateTime.now())) {
      expireOpenPlacement();
    }

    final open = orders.value.where(isOpenPlacementOrder).toList();
    if (open.isEmpty) {
      if (activeDeal.value != null &&
          (placementEndsAt == null || !placementEndsAt!.isAfter(DateTime.now()))) {
        clearPlacement();
      }
      return;
    }
    if (activeDeal.value != null &&
        activeAcceptOrderId != null &&
        placementEndsAt != null &&
        placementEndsAt!.isAfter(DateTime.now())) {
      return;
    }
    resumePlacementFromOrder(open.first);
  }

  static MockOrder submitOrder({required MockDeal deal, required String orderId}) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final acceptId = activeAcceptOrderId;
    final o = MockOrder(
      id: acceptId != null ? 'live_$acceptId' : 'ord_$ts',
      mintzerId: 'ORD${(ts % 1000000).toString().padLeft(6, '0')}',
      liveAcceptOrderId: acceptId,
      deal: deal,
      orderId: orderId.trim(),
      step: 1,
      liveRail: acceptId != null ? RailStep.tracking : null,
      nextAction: acceptId != null ? 'Add tracking ID' : '',
      successPromo: successPromoSeq++ % 4,
    );
    orders.value = [o, ...orders.value];
    clearPlacement();
    return o;
  }

  static void cancelOrder(MockOrder o, String reason) {
    o.canceled = true;
    o.note = o.note.isEmpty ? 'Cancel: $reason' : o.note;
    updateOrder(o);
  }

  static void goToOrdersTab() => tabIndex.value = 1;
  static void goToHomeTab() => tabIndex.value = 0;
  static void goToWalletTab() => tabIndex.value = 2;

  static void updateOrder(MockOrder o) {
    orders.value = [...orders.value];
  }

  /// Test helper — restore seeded ticket list.
  static void resetTickets() => tickets.value = _seedTickets();

  static List<MockTicket> _seedTickets() {
    final now = DateTime.now();
    final waitingAt = now.subtract(const Duration(minutes: 12));
    final replyAt = now.subtract(const Duration(minutes: 2));
    final resolvedAt = now.subtract(const Duration(days: 2));
    return [
      MockTicket(
        id: 'TKT-240918',
        subject: 'Paid extra vs app',
        category: 'paid_extra',
        orderId: 'OD778812345',
        status: TicketStatus.inProgress,
        created: now.subtract(const Duration(hours: 5)),
        answers: const ['Checkout cost more: Yes', 'Have screenshot: Yes'],
        unread: true,
        messages: [
          TicketMessage(
            fromYou: true,
            text: 'Checkout was more than You pay on Mintzer.',
            at: now.subtract(const Duration(hours: 5)),
          ),
          TicketMessage(
            fromYou: false,
            text: 'We’ve checked the amount you paid against the deal. Reply with a clear checkout screenshot if you still see a gap.',
            at: replyAt,
          ),
        ],
      ),
      MockTicket(
        id: 'TKT-240917',
        subject: 'Tracking not updating',
        category: 'other',
        orderId: 'OD778800112',
        status: TicketStatus.submitted,
        created: waitingAt.subtract(const Duration(hours: 1)),
        answers: const [],
        unread: false,
        messages: [
          TicketMessage(
            fromYou: true,
            text: 'Store shows shipped but Mintzer still says Placed.',
            at: waitingAt,
          ),
        ],
      ),
      MockTicket(
        id: 'TKT-240801',
        subject: 'Wrong bank credited',
        category: 'payout',
        orderId: 'OD770011223',
        status: TicketStatus.resolved,
        created: resolvedAt,
        answers: const [],
        unread: false,
        messages: [
          TicketMessage(fromYou: true, text: 'Payout went to an old account.', at: resolvedAt),
          TicketMessage(
            fromYou: false,
            text: 'Fixed — next Mintzer payout will use your saved payout account.',
            at: resolvedAt.add(const Duration(hours: 4)),
          ),
        ],
      ),
    ];
  }

  static MockTicket createTicket({
    required String subject,
    required String category,
    required String orderId,
    required List<String> answers,
    required String message,
  }) {
    final now = DateTime.now();
    final t = MockTicket(
      id: 'TKT-${now.millisecondsSinceEpoch.toString().substring(7)}',
      subject: subject,
      category: category,
      orderId: orderId,
      status: TicketStatus.submitted,
      created: now,
      answers: answers,
      messages: [TicketMessage(fromYou: true, text: message, at: now)],
    );
    tickets.value = [t, ...tickets.value];
    return t;
  }

  /// Match by store Order ID, Mintzer ORD ref, live accept id, or message body.
  static MockTicket? ticketForOrder(String orderId, {String? mintzerId, int? liveAcceptOrderId}) {
    final needles = <String>{
      if (orderId.trim().isNotEmpty && orderId.trim() != '—') orderId.trim(),
      if (mintzerId != null && mintzerId.trim().isNotEmpty) mintzerId.trim(),
      if (liveAcceptOrderId != null) '$liveAcceptOrderId',
    };
    if (needles.isEmpty) return null;

    for (final t in tickets.value) {
      if (t.status == TicketStatus.closed) continue;
      if (_ticketTouchesNeedles(t, needles)) return t;
    }
    return null;
  }

  static MockTicket? ticketForMockOrder(MockOrder order) {
    return ticketForOrder(
      order.orderId,
      mintzerId: order.mintzerId,
      liveAcceptOrderId: order.liveAcceptOrderId,
    );
  }

  static bool _ticketTouchesNeedles(MockTicket t, Set<String> needles) {
    final ref = t.orderId.trim();
    if (ref.length < 4) return false;
    final refLower = ref.toLowerCase();
    for (final n in needles) {
      final needle = n.trim();
      if (needle.length < 4) continue;
      if (refLower == needle.toLowerCase()) return true;
    }
    return false;
  }

  static void simulateAdminReply(MockTicket t) {
    final next = switch (t.status) {
      TicketStatus.submitted => TicketStatus.inProgress,
      TicketStatus.inProgress => TicketStatus.resolved,
      _ => null,
    };
    if (next == null) return;
    final text = next == TicketStatus.inProgress
        ? 'We’ve received your details and are checking with ops.'
        : 'Checked with ops — this is resolved. If it’s still off, reply from this ticket.';
    t.status = next;
    t.messages.add(TicketMessage(fromYou: false, text: text, at: DateTime.now()));
    t.unread = true;
    tickets.value = [...tickets.value];
  }

  static void userReply(MockTicket t, String text) {
    t.messages.add(TicketMessage(fromYou: true, text: text, at: DateTime.now()));
    t.unread = false;
    if (t.status == TicketStatus.submitted) t.status = TicketStatus.inProgress;
    tickets.value = [...tickets.value];
  }

  static void markTicketRead(MockTicket t) {
    if (!t.unread) return;
    t.unread = false;
    tickets.value = [...tickets.value];
  }

  static void savePayout({
    required String bankName,
    required String account,
    required String ifsc,
    required String upi,
  }) {
    MockSession.bankName = bankName;
    bankAccount = account;
    bankIfsc = ifsc;
    upiId = upi;
    payoutDone = true;
    SessionStore.save();
  }

  static List<MockNotification> _seedNotifications() {
    final now = DateTime.now();
    return [
      MockNotification(
        id: 'n_ticket',
        title: 'Paid extra vs app',
        body: 'We’re matching your invoice with the deal amount.',
        kind: NotificationKind.ticket,
        action: 'ticket',
        ref: 'TKT-240918',
        meta: 'TKT-240918 · Order OD778812345',
        unread: true,
        created: now.subtract(const Duration(minutes: 2)),
      ),
      MockNotification(
        id: 'n_invoice',
        title: 'Invoice approved',
        body: 'Your invoice is verified. Mintzer payout will process next.',
        kind: NotificationKind.order,
        action: 'orders',
        ref: 'OD778812345',
        meta: 'Order OD778812345',
        unread: false,
        created: now.subtract(const Duration(hours: 3)),
      ),
      MockNotification(
        id: 'n_payout',
        title: '₹372 Mintzer payout sent',
        body: 'Paid to your bank account. Wallet shows the record.',
        kind: NotificationKind.payout,
        action: 'wallet',
        ref: '',
        meta: 'Order OD770011223',
        unread: false,
        created: now.subtract(const Duration(hours: 20)),
      ),
      MockNotification(
        id: 'n_delivered',
        title: 'Order delivered',
        body: 'Parcel arrived at our address. Upload invoice when ready.',
        kind: NotificationKind.order,
        action: 'orders',
        ref: 'OD778800112',
        meta: 'Order OD778800112',
        unread: false,
        created: now.subtract(const Duration(days: 1, hours: 4)),
      ),
      MockNotification(
        id: 'n_deal',
        title: 'Deal no longer available',
        body: 'That listing ended. Browse Home for live deals.',
        kind: NotificationKind.deal,
        action: '',
        ref: '',
        meta: 'iPhone 16 128GB',
        unread: false,
        created: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  static void addNotification({
    required String title,
    required String body,
    String action = '',
    String ref = '',
    NotificationKind? kind,
    String? meta,
  }) {
    final resolved = kind ??
        switch (action) {
          'ticket' => NotificationKind.ticket,
          'wallet' => NotificationKind.payout,
          'orders' => NotificationKind.order,
          _ => NotificationKind.system,
        };
    notifications.value = [
      MockNotification(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        kind: resolved,
        action: action,
        ref: ref,
        meta: meta,
        unread: true,
        created: DateTime.now(),
      ),
      ...notifications.value,
    ];
  }

  static void markNotificationRead(String id) {
    for (final n in notifications.value) {
      if (n.id == id) n.unread = false;
    }
    notifications.value = [...notifications.value];
  }

  static void markAllNotificationsRead() {
    for (final n in notifications.value) {
      n.unread = false;
    }
    notifications.value = [...notifications.value];
  }

  static void clearNotifications() {
    notifications.value = [];
  }

  static bool get hasUnreadNotifications => notifications.value.any((n) => n.unread);
}

enum NotificationKind { ticket, order, payout, deal, system }

class MockNotification {
  MockNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.action,
    required this.ref,
    required this.unread,
    required this.created,
    this.meta,
  });

  final String id;
  final String title;
  final String body;
  final NotificationKind kind;
  final String action;
  final String ref;
  final String? meta;
  bool unread;
  final DateTime created;
}
