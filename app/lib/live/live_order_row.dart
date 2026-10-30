/// Raw live `newapp.orders` fields. Every field nullable — old rows are sparse.
class LiveOrderRow {
  const LiveOrderRow({
    this.id,
    this.productName,
    this.storeName,
    this.cardName,
    this.cardHolderReceive,
    this.orderAmount,
    this.tdsAmount,
    this.storeOrderId,
    this.orderStatus,
    this.orderTrackingId,
    this.orderDeliveryOtp,
    this.accountOrderPdf,
    this.verificationStatus,
    this.isPayout,
    this.transactionId,
    this.isPineLabDeal,
    this.paymentScreenshot,
    this.isPaymentVerified,
    this.deletedAt,
    this.orderNumber,
    this.color,
    this.gstNumber,
    this.imageUrl,
    this.orderDate,
    this.payoutBankName,
    this.payoutAccountLast4,
    this.mintzerPayout,
    this.cashback,
    this.paidAt,
    this.deliveryPartnerId,
    this.accountMobileNumber,
    this.couponCode,
  });

  final int? id;
  final String? productName;
  final String? storeName;
  /// Bank card name from deal (`offer`) — map to our card logos, never remote PNG.
  final String? cardName;
  final int? cardHolderReceive;
  final int? orderAmount;
  final int? tdsAmount;
  final String? storeOrderId;
  final String? orderStatus;
  final String? orderTrackingId;
  final String? orderDeliveryOtp;
  final String? accountOrderPdf;
  final String? verificationStatus;
  final int? isPayout;
  final String? transactionId;
  final int? isPineLabDeal;
  final String? paymentScreenshot;
  final int? isPaymentVerified;
  final String? deletedAt;
  /// Live `order_number` e.g. ORD0493.
  final String? orderNumber;
  final String? color;
  final String? gstNumber;
  /// Admin product / phone PNG only (`order_deal_image` / `image`).
  final String? imageUrl;
  final String? orderDate;
  /// Holder payout bank (from Auth user on getOrderList).
  final String? payoutBankName;
  final String? payoutAccountLast4;
  /// Bank transfer total (From Mintzer / card_holder_receive) — not profit alone.
  final int? mintzerPayout;
  /// Bank cashback on the deal snapshot (separate from Mintzer transfer).
  final int? cashback;
  /// Payout day when admin marked paid / saved UTR (`paid_at`). Null if unknown.
  final String? paidAt;
  /// Live `delivery_partner_id`.
  final String? deliveryPartnerId;
  /// Last digits of the delivery phone (`account_mobile_number`).
  final String? accountMobileNumber;
  /// Store coupon from the deal. Empty means the app hides the line.
  final String? couponCode;
}
