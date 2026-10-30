import 'deal.dart';
import '../live/order_mapper.dart';

/// Locked 7-step rail: Placed → Tracking → OFD → Confirmation → Invoice → Payment → Paid
const kOrderSteps = [
  'Placed',
  'Tracking',
  'Out for delivery',
  'Confirmation',
  'Invoice',
  'Payment',
  'Paid',
];

class MockOrder {
  MockOrder({
    required this.id,
    required this.deal,
    required this.orderId,
    String? mintzerId,
    this.liveAcceptOrderId,
    this.step = 1,
    this.tracking = '',
    this.courier = '',
    this.otp = '',
    this.phoneLast4 = '',
    this.paid = false,
    this.canceled = false,
    this.note = '',
    this.successPromo = 0,
    this.nextAction = '',
    this.liveRail,
    this.invoiceStatus = '',
    this.invoiceRejectReason = '',
    this.paymentTimerSec = 48 * 3600,
    this.cheerVisit = 0,
    this.utr = '',
    this.bankName = '',
    this.accountLast4 = '',
    this.mintzerPayout,
    this.paidOn,
    DateTime? created,
  })  : mintzerId = mintzerId ?? _defaultMintzerId(id),
        created = created ?? DateTime.now();

  final String id;
  /// Mintzer reference for support / ops — e.g. `ORD000201` (not the store order id).
  final String mintzerId;
  /// Live `orders.id` for Sanctum writes (`accept_order_id`). Null = mock-only.
  final int? liveAcceptOrderId;
  final MockDeal deal;
  /// Marketplace Order ID (Flipkart / Amazon). Empty / `—` until user pastes it.
  String orderId;

  /// True when a real store Order ID is on the row (not placeholder).
  bool get hasStoreOrderId {
    final s = orderId.trim();
    return s.isNotEmpty && s != '—';
  }

  /// Store Order ID when present; otherwise Mintzer ORD ref (never blank `—`).
  String get displayOrderId => hasStoreOrderId ? orderId.trim() : mintzerId;

  /// Line for list/wallet: `Flipkart · #OD123` or `Flipkart · ORD…` while waiting.
  String get storeOrderLine {
    final store = deal.storeLabel.trim().isEmpty ? 'Store' : deal.storeLabel.trim();
    if (hasStoreOrderId) {
      final id = orderId.startsWith('#') ? orderId : '#$orderId';
      return '$store · $id';
    }
    return '$store · Order ID pending';
  }
  /// Current step index 0–6 (0 = Placed done, current is often 1 = Tracking).
  int step;
  String tracking;
  String courier;
  String otp;
  String phoneLast4;
  bool paid;
  bool canceled;
  String note;
  final int successPromo;
  final DateTime created;
  /// From live mapper §5 — empty for pure mock orders until set.
  String nextAction;
  /// Set when order came from a live row fixture / API.
  RailStep? liveRail;
  /// `''` | `verifying` | `rejected` | `verified`
  String invoiceStatus;
  String invoiceRejectReason;
  int paymentTimerSec;
  /// Payout cheer index — bump once per Order detail visit (not on a timer).
  int cheerVisit;
  String utr;
  String bankName;
  String accountLast4;
  /// Bank transfer total from live API (From Mintzer). Null → derive from deal.
  final int? mintzerPayout;
  /// Real payout day from API (`paid_at` / when UTR saved). Null = do not show Paid on.
  DateTime? paidOn;

  /// What Mintzer pays to the bank (Total receive / From Mintzer).
  /// Never invent You pay + profit. Live rows only trust API / saved Total receive.
  int get bankReturnAmount {
    final api = mintzerPayout;
    if (api != null && api > 0) return api;
    final savedReceive = deal.cardHolderReceive;
    if (savedReceive != null && savedReceive > 0) return savedReceive;
    // Live order: do not fall back to product formulas (those caused ₹33,243 confusion).
    if (liveAcceptOrderId != null || liveRail != null) {
      return deal.earn;
    }
    // Sample / mock orders only — catalog formula is fine.
    final fromDeal = deal.walletFromMintzer;
    if (fromDeal > deal.earn) return fromDeal;
    return deal.earn;
  }

  /// Which timeline steps are in edit mode (demo `editFields`).
  final Map<int, bool> editFields = {};

  bool get ongoing => !paid && !canceled;
  bool get completed => paid || canceled;

  String get actionLabel {
    if (canceled) return 'Canceled';
    if (paid) return 'Completed';
    if (nextAction.isNotEmpty) {
      if (deal.isInstantLink &&
          (nextAction.toLowerCase().contains('invoice') ||
              nextAction.toLowerCase().contains('upload'))) {
        if (nextAction.toLowerCase().contains('checking')) return 'Checking payment proof';
        if (nextAction.toLowerCase().contains('re-upload')) return 'Re-upload screenshot';
        return 'Upload payment screenshot';
      }
      return nextAction;
    }
    if (step <= 1) return 'Add tracking ID';
    if (step == 2) return 'Enter delivery OTP';
    if (step == 3) return 'Waiting for delivery';
    if (step == 4) {
      return deal.isInstantLink ? 'Upload payment screenshot' : 'Upload invoice';
    }
    if (step == 5) return 'On the way';
    return 'Completed';
  }

  /// Short CTA for list card (avoids truncation).
  String get actionCtaShort {
    final a = actionLabel.toLowerCase();
    if (a.contains('tracking')) return 'Add tracking →';
    if (a.contains('screenshot')) return 'Upload proof →';
    if (a.contains('invoice') || a.contains('re-upload') || a.contains('upload')) return 'Upload →';
    if (a.contains('otp')) return 'Enter OTP →';
    if (a.contains('continue')) return 'Continue →';
    if (a.contains('checking')) return 'Checking…';
    return '$actionLabel →';
  }

  /// User must tap something in-app (not waiting on Mintzer / bank).
  bool get needsUserAction {
    if (!ongoing) return false;
    final a = actionLabel.toLowerCase();
    return a.contains('tracking') ||
        a.contains('otp') ||
        a.contains('upload') ||
        a.contains('re-upload') ||
        a.contains('continue');
  }

  /// Plain status when there is no primary action button.
  String get statusLine {
    if (canceled) return 'Canceled';
    if (paid) return 'Completed';
    final a = actionLabel.toLowerCase();
    if (a.contains('checking')) return 'Checking invoice';
    if (a.contains('on the way')) return 'Payout on the way';
    if (a.contains('waiting')) return 'Waiting for delivery confirmation';
    return actionLabel;
  }

  /// Note shown on My Orders card (hide cancel-reason prefix).
  String get listNote {
    final n = note.trim();
    if (n.isEmpty || n.startsWith('Cancel:')) return '';
    return n;
  }

  /// Compact list rail: Ordered · Shipped · Delivered · Verified
  ///
  /// [listCompletedThrough] = last stage index that is ✓ (−1 = none).
  /// [listCurrentStage] = pulsing stage, or null when waiting with no in-progress stage.
  ///
  /// **Never** marks Verified while upload / tracking / OTP is still required.
  (int completedThrough, int? current) get listStage {
    if (canceled) return (-1, 0);
    if (paid) return (3, null);

    final rail = liveRail;
    if (rail != null) {
      return switch (rail) {
        RailStep.hide || RailStep.placement => (-1, 0),
        RailStep.tracking => (0, 1),
        RailStep.ofd => (1, 2),
        // OTP in; waiting for admin Delivered — Delivered stage still current.
        RailStep.confirmation => (1, 2),
        // Admin Delivered; invoice not verified yet — Verified stays grey.
        RailStep.invoice || RailStep.invoiceRejected => (2, null),
        RailStep.invoiceVerifying || RailStep.payment => (2, 3),
        RailStep.paid => (3, null),
        RailStep.canceled => (-1, 0),
      };
    }

    // Mock 7-step fallback (0 Placed … 6 Paid).
    if (step <= 0) return (-1, 0);
    if (step == 1) return (0, 1);
    if (step == 2 || step == 3) return (1, 2);
    if (step == 4) {
      final a = actionLabel.toLowerCase();
      if (a.contains('checking') || a.contains('verifying')) return (2, 3);
      // Upload / re-upload still due — do not show Verified.
      return (2, null);
    }
    if (step >= 5) return (2, 3);
    return (-1, 0);
  }
}

String _defaultMintzerId(String id) {
  final digits = id.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return 'ORD${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';
  }
  final n = digits.length > 6 ? digits.substring(digits.length - 6) : digits.padLeft(6, '0');
  return 'ORD$n';
}
