/// Curated demo orders matching locked HTML seed (not live Phpadmin dump).
library;

import 'live_order_row.dart';

/// Tracking due — store id, no tracking.
const kLiveTrackingDue = LiveOrderRow(
  id: 201,
  productName: 'IQOO Z10 Lite 5G (4GB/128GB)',
  storeName: 'Flipkart',
  cardHolderReceive: 300,
  storeOrderId: 'OD998877665',
  orderStatus: 'Placed',
);

/// Confirmation wait — OTP in, admin has not marked Delivered yet.
const kLiveConfirmationDue = LiveOrderRow(
  id: 207,
  productName: 'boAt Airdopes 141',
  storeName: 'Amazon',
  cardHolderReceive: 220,
  storeOrderId: '402-5544332211',
  orderStatus: 'Out For Delivery',
  orderTrackingId: 'FMPP1234567890',
  orderDeliveryOtp: '482910',
);

/// Invoice due — admin Delivered, no invoice file yet.
const kLiveInvoiceDue = LiveOrderRow(
  id: 202,
  productName: 'boAt Airdopes 141',
  storeName: 'Amazon',
  cardHolderReceive: 220,
  storeOrderId: '402-5544332210',
  orderStatus: 'Delivered',
  orderTrackingId: 'FMPP1234567890',
  orderDeliveryOtp: '482910',
);

/// Already paid.
const kLiveAlreadyPaid = LiveOrderRow(
  id: 203,
  productName: 'Noise ColorFit Pro 5',
  storeName: 'Flipkart',
  cardHolderReceive: 380,
  storeOrderId: 'OD112233445',
  orderStatus: 'Delivered',
  orderTrackingId: 'FMPC9988776655',
  orderDeliveryOtp: '991122',
  accountOrderPdf: 'invoices/demo.pdf',
  verificationStatus: 'Verified',
  isPayout: 1,
);

/// Canceled — appears under Completed.
const kLiveCanceled = LiveOrderRow(
  id: 206,
  productName: 'Samsung Galaxy M35',
  storeName: 'Flipkart',
  cardHolderReceive: 450,
  storeOrderId: 'OD776655443',
  orderStatus: 'canceled',
  orderTrackingId: 'EK55667788',
);

const kLiveInvoiceVerifying = LiveOrderRow(
  id: 204,
  productName: 'Samsung Galaxy M14',
  storeName: 'Flipkart',
  cardHolderReceive: 450,
  storeOrderId: 'OD555666777',
  orderStatus: 'Delivered',
  orderTrackingId: 'EK1234567',
  orderDeliveryOtp: '111111',
  accountOrderPdf: 'invoices/wait.pdf',
);

const kLivePineLab = LiveOrderRow(
  id: 205,
  storeOrderId: 'PL-88',
  isPineLabDeal: 1,
);

const kLiveAllNull = LiveOrderRow();

const kMustTestLiveRows = [
  kLiveTrackingDue,
  kLiveConfirmationDue,
  kLiveInvoiceDue,
  kLiveAlreadyPaid,
  kLiveCanceled,
];

const kAllLiveFixtures = [
  kLiveTrackingDue,
  kLiveConfirmationDue,
  kLiveInvoiceDue,
  kLiveAlreadyPaid,
  kLiveCanceled,
  kLiveInvoiceVerifying,
  kLivePineLab,
  kLiveAllNull,
];
