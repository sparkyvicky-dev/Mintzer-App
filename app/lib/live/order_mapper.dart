import 'live_order_row.dart';

/// Locked 7-step rail. `hide` = expired accept, not shown in My Orders.
enum RailStep {
  hide,
  canceled,
  placement,
  tracking,
  ofd,
  /// OTP saved; waiting for admin Delivered before invoice upload.
  confirmation,
  invoice,
  invoiceVerifying,
  invoiceRejected,
  payment,
  paid,
}

bool _has(String? s) => s != null && s.trim().isNotEmpty;

String _status(LiveOrderRow r) => (r.orderStatus ?? '').trim().toLowerCase();

/// Pure mapper. Must not throw on nulls. Spec: 11-live-order-migration.md §9.
RailStep mapLiveOrder(LiveOrderRow r) {
  if (_has(r.deletedAt) && !_has(r.storeOrderId)) return RailStep.hide;

  const canceled = {'cancelled', 'canceled', 'rejected', 'declined'};
  if (canceled.contains(_status(r))) return RailStep.canceled;

  if (r.isPayout == 1 || _has(r.transactionId)) return RailStep.paid;

  if (r.isPineLabDeal == 1) {
    if (!_has(r.paymentScreenshot)) return RailStep.invoice;
    if (r.isPaymentVerified != 1) return RailStep.invoiceVerifying;
    return RailStep.payment;
  }

  final v = (r.verificationStatus ?? '').trim();
  if (v == 'Re-Upload' || v == 'Alerted') return RailStep.invoiceRejected;
  if (_has(r.accountOrderPdf) && !_has(v)) return RailStep.invoiceVerifying;
  if (_has(r.accountOrderPdf) && v == 'Verified') return RailStep.payment;

  // Invoice unlocks only after admin marks Delivered.
  if (_status(r) == 'delivered') {
    return RailStep.invoice;
  }
  // OTP / OFD → Confirmation wait (not Upload invoice yet).
  if (_has(r.orderDeliveryOtp) || _status(r) == 'out for delivery') {
    return RailStep.confirmation;
  }
  if (_has(r.orderTrackingId) || _status(r) == 'shipped') {
    return RailStep.ofd;
  }
  if (_has(r.storeOrderId)) return RailStep.tracking;
  return RailStep.placement;
}

/// List-card next-action labels (§5).
String nextActionLabel(RailStep step) => switch (step) {
      RailStep.hide => '',
      RailStep.canceled => 'Canceled',
      RailStep.placement => 'Continue order',
      RailStep.tracking => 'Add tracking ID',
      RailStep.ofd => 'Enter delivery OTP',
      RailStep.confirmation => 'Waiting for delivery',
      RailStep.invoice => 'Upload invoice',
      RailStep.invoiceVerifying => 'Checking invoice',
      RailStep.invoiceRejected => 'Re-upload',
      RailStep.payment => 'On the way',
      RailStep.paid => 'Completed',
    };

/// UI rail index 0–6 (Placed…Paid). Placement/hide → 0.
int railIndex(RailStep step) => switch (step) {
      RailStep.hide || RailStep.placement => 0,
      RailStep.tracking => 1,
      RailStep.ofd => 2,
      RailStep.confirmation => 3,
      RailStep.invoice ||
      RailStep.invoiceVerifying ||
      RailStep.invoiceRejected =>
        4,
      RailStep.payment => 5,
      RailStep.paid || RailStep.canceled => 6,
    };

/// Safe entry: never throws; bad rows → placement.
RailStep mapLiveOrderSafe(LiveOrderRow? r) {
  if (r == null) return RailStep.placement;
  try {
    return mapLiveOrder(r);
  } catch (_) {
    return RailStep.placement;
  }
}
