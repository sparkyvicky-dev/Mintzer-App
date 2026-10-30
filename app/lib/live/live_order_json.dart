import 'live_order_row.dart';

/// Parse one item from live `getOrderList` (or admin dump). Never throws.
LiveOrderRow liveOrderRowFromJson(Map<String, dynamic>? json) {
  if (json == null) return const LiveOrderRow();
  try {
    final invoiceFlag = json['is_invoice_uploaded'];
    final pdf = _str(json['account_order_pdf']);
    final invoicePath = pdf ??
        ((invoiceFlag == true || invoiceFlag == 1 || invoiceFlag == '1') ? 'uploaded' : null);

    return LiveOrderRow(
      id: _asInt(json['id']) ?? _asInt(json['accept_order_id']),
      productName: _str(json['order_deal_name']) ??
          _str(json['name']) ??
          _str(json['deal_name']),
      storeName: _str(json['store_name']),
      // Additive `offer` = bank card name. Never use bank_card_image URL.
      cardName: _str(json['offer']) ??
          _str(json['bank_card_name']) ??
          _str(json['card_name']),
      // Wallet / You earn = **profit only** (never reimbursement / From Mintzer).
      cardHolderReceive: _netEarn(json),
      orderAmount: _asInt(json['order_amount']) ?? _asInt(json['selling_price']),
      tdsAmount: _asInt(json['tds_amount']),
      storeOrderId: _str(json['store_order_id']),
      orderStatus: _str(json['order_status']),
      orderTrackingId: _str(json['order_tracking_id']),
      orderDeliveryOtp: _str(json['order_delivery_otp']) ?? _str(json['otp']),
      accountOrderPdf: invoicePath,
      verificationStatus: _str(json['verification_status']),
      isPayout: _asInt(json['is_payout']),
      transactionId: _str(json['transaction_id']),
      isPineLabDeal: _asInt(json['is_pine_lab_deal']),
      paymentScreenshot: _str(json['payment_screenshot']),
      isPaymentVerified: _asInt(json['is_payment_verified']),
      deletedAt: _str(json['deleted_at']),
      orderNumber: _str(json['order_number']),
      color: _str(json['order_deal_color']) ?? _str(json['color']),
      gstNumber: _str(json['order_deal_gst_number']) ?? _str(json['gst_number']),
      // Product PNG only — ignore store_image / bank_card_image.
      imageUrl: _str(json['order_deal_image']) ?? _str(json['image']),
      orderDate: _str(json['order_date']),
      payoutBankName: _str(json['payout_bank_name']),
      payoutAccountLast4: _str(json['payout_account_last4']),
      mintzerPayout: _asInt(json['mintzer_payout']) ??
          _asInt(json['card_holder_receive']) ??
          _asInt(json['card_holder_recieve']),
      cashback: _asInt(json['cashback']) ?? _asInt(json['order_deal_cashback']),
      // Prefer real payout day; never invent from order_date (accept day).
      paidAt: _str(json['paid_at']) ??
          _str(json['payout_date']) ??
          _str(json['payout_at']),
      deliveryPartnerId: _str(json['delivery_partner_id']),
      accountMobileNumber: _str(json['account_mobile_number']) ??
          _str(json['mobile_no']),
      couponCode: _str(json['coupon_code']),
    );
  } catch (_) {
    return const LiveOrderRow();
  }
}

List<LiveOrderRow> liveOrderRowsFromList(dynamic data) {
  if (data is! List) return const [];
  final out = <LiveOrderRow>[];
  final seenIds = <int>{};
  for (final item in data) {
    LiveOrderRow row;
    if (item is Map<String, dynamic>) {
      row = liveOrderRowFromJson(item);
    } else if (item is Map) {
      row = liveOrderRowFromJson(Map<String, dynamic>.from(item));
    } else {
      continue;
    }
    // getOrderList leftJoins order_deal — can duplicate the same orders.id.
    final id = row.id;
    if (id != null) {
      if (!seenIds.add(id)) continue;
    }
    out.add(row);
  }
  return out;
}

/// Net **profit** for Wallet · You earn (not total Mintzer sent / From Mintzer).
///
/// Live columns (Accept today):
/// - `earning_price` / `earnings` / `order_deal_card_holder_earn` = gross You earn
/// - `to_card_holder` = gross − TDS when Accept wrote it correctly
///
/// Legacy paid rows often stored **reimbursement** in `to_card_holder` /
/// `card_holder_recieve` (≈ order_amount, tens of thousands) with `earnings` = 0.
/// Never treat that as profit.
int? _netEarn(Map<String, dynamic> json) {
  final tds = _asInt(json['tds_amount']) ?? 0;
  final orderAmt = _asInt(json['order_amount']) ?? _asInt(json['selling_price']);
  final toHolder = _asInt(json['to_card_holder']);
  final receiveAlias = _asInt(json['card_holder_recieve']);

  final gross = _firstPositive([
    _asInt(json['earning_price']),
    _asInt(json['order_deal_card_holder_earn']),
    _asInt(json['card_holder_earn']),
  ]);

  if (gross != null) {
    // Net after TDS when Accept stored it on the order.
    if (toHolder != null && toHolder > 0 && toHolder <= gross) return toHolder;
    if (tds > 0 && tds < gross) return gross - tds;
    return gross;
  }

  // No earnings field — only use to_card_holder / receive if it looks like profit
  // (much smaller than order amount), not like reimbursement.
  final candidate = _firstPositive([toHolder, receiveAlias]);
  if (candidate == null) return null;
  if (_looksLikeProfitNotPayout(candidate, orderAmt)) return candidate;
  return null;
}

int? _firstPositive(List<int?> values) {
  for (final v in values) {
    if (v != null && v > 0) return v;
  }
  return null;
}

/// True when [amount] is plausible You-earn, not walletFromMintzer / order spend.
bool _looksLikeProfitNotPayout(int amount, int? orderAmt) {
  if (orderAmt != null && orderAmt > 0) {
    // Profit is typically a few % of spend; reimbursement ≈ spend.
    if (amount >= (orderAmt * 0.35).round()) return false;
    return true;
  }
  // No spend context: reject huge “earn” figures (legacy receive dumps).
  return amount <= 5000;
}

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty || s == 'null' ? null : s;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is bool) return v ? 1 : 0;
  return int.tryParse(v.toString().trim());
}
