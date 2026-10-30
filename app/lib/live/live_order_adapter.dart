import '../models/deal.dart';
import '../models/mock_order.dart';
import '../mock/session.dart';
import '../util/couriers.dart';
import 'brand_catalog.dart';
import 'live_order_row.dart';
import 'order_mapper.dart';

/// Turns a live row into a MockOrder for the locked UI. Never throws.
/// Does **not** invent demo notes, fake banks, or fake UTRs.
MockOrder? liveRowToMockOrder(LiveOrderRow row) {
  final step = mapLiveOrderSafe(row);
  if (step == RailStep.hide) return null;

  final deal = _dealFor(row);
  final orderId = (row.storeOrderId ?? '').trim();
  final mintzerId = _mintzerRef(row);
  final utr = (row.transactionId ?? '').trim();

  // Payout bank: API row → profile session — never invent HDFC ••••4321.
  final apiBank = (row.payoutBankName ?? '').trim();
  final apiLast4 = (row.payoutAccountLast4 ?? '').trim();
  final profileBank = MockSession.bankName.trim();
  final profileAcct = MockSession.bankAccount.trim();
  final profileLast4 = profileAcct.length >= 4
      ? profileAcct.substring(profileAcct.length - 4)
      : '';

  final bankName = apiBank.isNotEmpty ? apiBank : profileBank;
  final last4 = apiLast4.isNotEmpty
      ? apiLast4
      : (profileLast4.isNotEmpty ? profileLast4 : '');

  if (bankName.isNotEmpty && MockSession.bankName.trim().isEmpty) {
    MockSession.bankName = bankName;
  }

  return MockOrder(
    id: 'live_${row.id ?? orderId.hashCode}',
    mintzerId: mintzerId,
    liveAcceptOrderId: row.id,
    deal: deal,
    orderId: orderId.isEmpty ? '—' : orderId,
    step: railIndex(step),
    tracking: (row.orderTrackingId ?? '').trim(),
    courier: _courierFor(row),
    otp: (row.orderDeliveryOtp ?? '').trim(),
    phoneLast4: _deliveryLast4(row.accountMobileNumber),
    paid: step == RailStep.paid,
    canceled: step == RailStep.canceled,
    note: '', // live DB has no user-note column yet
    nextAction: nextActionLabel(step),
    liveRail: step,
    invoiceStatus: switch (step) {
      RailStep.invoiceVerifying => 'verifying',
      RailStep.invoiceRejected => 'rejected',
      RailStep.payment || RailStep.paid => 'verified',
      _ => '',
    },
    invoiceRejectReason: step == RailStep.invoiceRejected
        ? 'Please re-upload a clearer invoice from the store.'
        : '',
    paymentTimerSec: step == RailStep.payment ? 36 * 3600 : 48 * 3600,
    bankName: bankName,
    accountLast4: last4,
    utr: utr,
    mintzerPayout: row.mintzerPayout,
    paidOn: _parseDate(row.paidAt),
    created: _parseDate(row.orderDate) ?? DateTime.now(),
  );
}

String _courierFor(LiveOrderRow row) {
  return MintzerCouriers.labelForPartnerId(row.deliveryPartnerId);
}

String _deliveryLast4(String? raw) {
  final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return '';
  return digits.substring(digits.length - 4);
}

String _mintzerRef(LiveOrderRow row) {
  final on = (row.orderNumber ?? '').trim();
  if (on.isNotEmpty) return on;
  final n = row.id;
  if (n != null) return 'ORD${n.toString().padLeft(6, '0')}';
  final store = (row.storeOrderId ?? '').replaceAll(RegExp(r'\D'), '');
  if (store.length >= 4) {
    final tail = store.length > 6 ? store.substring(store.length - 6) : store.padLeft(6, '0');
    return 'ORD$tail';
  }
  return 'ORD${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';
}

MockDeal _dealFor(LiveOrderRow row) {
  // row.cardHolderReceive = net profit (You earn) from JSON mapper.
  // deal.cardHolderReceive below = Total receive / From Mintzer (mintzer_payout).
  final net = (row.cardHolderReceive ?? 0).clamp(0, 1 << 30);
  final tds = (row.tdsAmount ?? 0).clamp(0, 1 << 30);
  final commission = net + tds;

  final name = (row.productName ?? '').trim().isEmpty
      ? 'Order ${row.storeOrderId ?? row.orderNumber ?? row.id ?? ''}'
      : row.productName!.trim();

  final storeId = BrandCatalog.storeIdFromName(row.storeName);
  final storeLabel = BrandCatalog.storeLabel(row.storeName, storeId);
  final cardId = BrandCatalog.cardIdFromName(row.cardName);
  final cardLabel = BrandCatalog.cardLabel(row.cardName, cardId);

  final color = (row.color ?? '').trim();

  return MockDeal(
    id: 'live_deal_${row.id ?? 0}',
    type: (row.isPineLabDeal == 1) ? 'link' : 'direct',
    name: name,
    color: color,
    variant: color,
    gst: (row.gstNumber ?? '').trim().isNotEmpty,
    storeId: storeId,
    storeLabel: storeLabel,
    cardId: cardId,
    cardLabel: cardLabel,
    orderValue: row.orderAmount ?? 0,
    // Accepted checkout amount is card holder spend (You pay).
    cardHolderSpend: (row.orderAmount != null && row.orderAmount! > 0) ? row.orderAmount : null,
    // Total receive / From Mintzer (not profit). Profit is commission − TDS.
    cardHolderReceive: (row.mintzerPayout != null && row.mintzerPayout! > 0)
        ? row.mintzerPayout
        : null,
    cashback: (row.cashback != null && row.cashback! > 0) ? row.cashback! : 0,
    commission: commission > 0 ? commission : net,
    tds: tds > 0 ? tds : 0,
    imageAsset: null,
    imageUrl: (row.imageUrl ?? '').trim().isEmpty ? null : row.imageUrl!.trim(),
    paymentHours: (row.isPineLabDeal == 1) ? 24 : 48,
    offerText: (row.isPineLabDeal == 1) ? 'Instant · Paid within 24 working hours' : null,
    badge: (row.isPineLabDeal == 1) ? 'instant' : null,
    couponCode: row.couponCode,
  );
}

DateTime? _parseDate(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s.replaceFirst(' ', 'T'));
}
