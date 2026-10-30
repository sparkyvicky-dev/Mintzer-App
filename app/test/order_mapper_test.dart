import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mintzer/live/live_fixtures.dart';
import 'package:mintzer/live/live_order_adapter.dart';
import 'package:mintzer/live/live_order_json.dart';
import 'package:mintzer/live/live_order_row.dart';
import 'package:mintzer/live/order_mapper.dart';
import 'package:mintzer/live/orders_repository.dart';

void main() {
  test('all-null row is a placement, never throws', () {
    expect(mapLiveOrder(const LiveOrderRow()), RailStep.placement);
    expect(mapLiveOrderSafe(null), RailStep.placement);
  });

  test('expired accept hidden', () {
    expect(
      mapLiveOrder(const LiveOrderRow(deletedAt: '2026-01-01')),
      RailStep.hide,
    );
    expect(liveRowToMockOrder(const LiveOrderRow(deletedAt: '2026-01-01')), isNull);
  });

  test('paid even if other fields empty', () {
    expect(mapLiveOrder(const LiveOrderRow(isPayout: 1)), RailStep.paid);
    expect(mapLiveOrder(const LiveOrderRow(transactionId: 'UTR1')), RailStep.paid);
  });

  test('OTP / OFD waits on Confirmation until admin Delivered', () {
    expect(
      mapLiveOrder(const LiveOrderRow(
        storeOrderId: 'OD1',
        orderTrackingId: 'EK1',
        orderDeliveryOtp: '123456',
        orderStatus: 'Out For Delivery',
      )),
      RailStep.confirmation,
    );
  });

  test('admin Delivered unlocks invoice', () {
    expect(
      mapLiveOrder(const LiveOrderRow(
        storeOrderId: 'OD1',
        orderTrackingId: 'EK1',
        orderStatus: 'Delivered',
      )),
      RailStep.invoice,
    );
  });

  test('canceled statuses', () {
    expect(mapLiveOrder(const LiveOrderRow(orderStatus: 'Cancelled')), RailStep.canceled);
    expect(mapLiveOrder(const LiveOrderRow(orderStatus: 'Rejected')), RailStep.canceled);
    expect(mapLiveOrder(const LiveOrderRow(orderStatus: 'Declined')), RailStep.canceled);
  });

  group('STATUS must-tests (Tracking / Invoice / Paid)', () {
    test('Tracking due', () {
      final step = mapLiveOrder(kLiveTrackingDue);
      expect(step, RailStep.tracking);
      expect(nextActionLabel(step), 'Add tracking ID');
      expect(railIndex(step), 1);
      final o = liveRowToMockOrder(kLiveTrackingDue)!;
      expect(o.orderId, 'OD998877665');
      expect(o.paid, isFalse);
      expect(o.step, 1);
      expect(o.actionLabel, 'Add tracking ID');
      expect(o.note, isEmpty); // hide empty note
    });

    test('Confirmation wait after OTP', () {
      final step = mapLiveOrder(kLiveConfirmationDue);
      expect(step, RailStep.confirmation);
      expect(nextActionLabel(step), 'Waiting for delivery');
      expect(railIndex(step), 3);
      final o = liveRowToMockOrder(kLiveConfirmationDue)!;
      expect(o.otp, '482910');
      expect(o.step, 3);
      expect(o.actionLabel, 'Waiting for delivery');
    });

    test('Invoice due after admin Delivered', () {
      final step = mapLiveOrder(kLiveInvoiceDue);
      expect(step, RailStep.invoice);
      expect(nextActionLabel(step), 'Upload invoice');
      expect(railIndex(step), 4);
      final o = liveRowToMockOrder(kLiveInvoiceDue)!;
      expect(o.otp, '482910');
      expect(o.tracking, isNotEmpty);
      expect(o.step, 4);
    });

    test('Already paid', () {
      final step = mapLiveOrder(kLiveAlreadyPaid);
      expect(step, RailStep.paid);
      expect(nextActionLabel(step), 'Completed');
      final o = liveRowToMockOrder(kLiveAlreadyPaid)!;
      expect(o.paid, isTrue);
      expect(o.completed, isTrue);
      // No UTR on row — still paid, no crash
      expect(o.orderId, isNotEmpty);
    });

    test('all three open without crash', () {
      for (final row in kMustTestLiveRows) {
        expect(() => mapLiveOrder(row), returnsNormally);
        expect(() => liveRowToMockOrder(row), returnsNormally);
        expect(liveRowToMockOrder(row), isNotNull);
      }
    });
  });

  test('invoice verifying and rejected', () {
    expect(mapLiveOrder(kLiveInvoiceVerifying), RailStep.invoiceVerifying);
    expect(
      mapLiveOrder(const LiveOrderRow(
        storeOrderId: 'X',
        accountOrderPdf: 'a.pdf',
        verificationStatus: 'Re-Upload',
      )),
      RailStep.invoiceRejected,
    );
    expect(
      mapLiveOrder(const LiveOrderRow(
        storeOrderId: 'X',
        accountOrderPdf: 'a.pdf',
        verificationStatus: 'Verified',
      )),
      RailStep.payment,
    );
  });

  test('shipped without otp → OFD', () {
    expect(
      mapLiveOrder(const LiveOrderRow(storeOrderId: 'OD', orderStatus: 'Shipped')),
      RailStep.ofd,
    );
    expect(
      mapLiveOrder(const LiveOrderRow(storeOrderId: 'OD', orderTrackingId: 'FMPP1')),
      RailStep.ofd,
    );
  });

  test('pine lab paths', () {
    expect(mapLiveOrder(kLivePineLab), RailStep.invoice);
    expect(
      mapLiveOrder(const LiveOrderRow(
        isPineLabDeal: 1,
        paymentScreenshot: 'shot.jpg',
        isPaymentVerified: 0,
      )),
      RailStep.invoiceVerifying,
    );
    expect(
      mapLiveOrder(const LiveOrderRow(
        isPineLabDeal: 1,
        paymentScreenshot: 'shot.jpg',
        isPaymentVerified: 1,
      )),
      RailStep.payment,
    );
    expect(
      mapLiveOrder(const LiveOrderRow(
        isPineLabDeal: 1,
        paymentScreenshot: 'shot.jpg',
        isPaymentVerified: 1,
        isPayout: 1,
      )),
      RailStep.paid,
    );
  });

  test('never re-ask order id when store_order_id set', () {
    final o = liveRowToMockOrder(kLiveTrackingDue)!;
    expect(o.orderId, isNot(equals('—')));
    expect(o.orderId.startsWith('OD'), isTrue);
  });

  test('whitespace-only fields treated as empty', () {
    expect(
      mapLiveOrder(const LiveOrderRow(
        storeOrderId: 'OD',
        orderTrackingId: '   ',
        orderDeliveryOtp: ' ',
      )),
      RailStep.tracking,
    );
  });

  test('JSON dump parses sparse getOrderList shapes', () {
    final rows = liveOrderRowsFromList([
      {
        'id': '1001',
        'store_order_id': 'OD112233445566',
        'order_status': 'Placed',
        'name': 'Samsung Galaxy M14 (4GB/128GB)',
        'card_holder_recieve': '450',
        'is_payout': '0',
        'order_tracking_id': null,
        'deleted_at': null,
      },
      {
        'id': 1002,
        'store_order_id': '402-9988776-5544332',
        'order_status': 'Out For Delivery',
        'order_tracking_id': 'FMPP9876543210',
        'order_delivery_otp': '482910',
        'account_order_pdf': '',
        'is_payout': 0,
      },
      {
        'id': 1003,
        'store_order_id': 'OD778899001122',
        'order_status': 'Delivered',
        'is_payout': 1,
        'transaction_id': null,
        'account_order_pdf': 'invoices/old.pdf',
        'verification_status': 'Verified',
      },
      null,
      'bad',
    ]);
    expect(rows.length, 3);
    expect(mapLiveOrder(rows[0]), RailStep.tracking);
    expect(mapLiveOrder(rows[1]), RailStep.confirmation);
    expect(mapLiveOrder(rows[2]), RailStep.paid);

    OrdersRepository.instance.loadRemoteJson([
      {
        'id': 1001,
        'store_order_id': 'OD112233445566',
        'order_status': 'Placed',
        'name': 'From dump',
        'card_holder_recieve': 450,
      },
    ]);
    final list = OrdersRepository.instance.fetchOrders();
    expect(list.length, 1);
    expect(list.first.actionLabel, 'Add tracking ID');
    OrdersRepository.instance.clearRemote();
  });

  test('wallet earn uses net profit when to_card_holder <= earning_price', () {
    final row = liveOrderRowFromJson({
      'accept_order_id': 9,
      'store_order_id': 'OD1',
      'earning_price': 700, // gross You earn
      'to_card_holder': 686, // net after TDS
      'tds_amount': 14,
      'order_amount': 63000,
      'is_payout': 1,
    });
    expect(row.cardHolderReceive, 686);
    final o = liveRowToMockOrder(row)!;
    expect(o.deal.earn, 686);
    expect(o.paid, isTrue);
  });

  test('wallet earn ignores legacy reimbursement in to_card_holder', () {
    // Legacy paid row: to_card_holder ≈ what Mintzer sent, earnings empty.
    final row = liveOrderRowFromJson({
      'accept_order_id': 100,
      'store_order_id': 'ord5645',
      'earning_price': 0,
      'to_card_holder': 44670,
      'card_holder_recieve': 44670,
      'order_amount': 43670,
      'tds_amount': 0,
      'is_payout': 1,
    });
    expect(row.cardHolderReceive, isNull);
    final o = liveRowToMockOrder(row)!;
    expect(o.deal.earn, 0);
  });

  test('wallet earn uses earning_price when to_card_holder is reimbursement', () {
    final row = liveOrderRowFromJson({
      'accept_order_id': 768,
      'store_order_id': 'OD2',
      'earning_price': 600,
      'to_card_holder': 68999, // wrongly large / receive
      'order_amount': 63344,
      'tds_amount': 0,
      'is_payout': 1,
    });
    expect(row.cardHolderReceive, 600);
    expect(liveRowToMockOrder(row)!.deal.earn, 600);
  });

  test('bank return uses mintzer_payout not spend plus earn', () {
    final row = liveOrderRowFromJson({
      'accept_order_id': 1257,
      'store_order_id': 'OD338787534076189100',
      'earning_price': 900,
      'order_amount': 32343,
      'mintzer_payout': 31635,
      'cashback': 1608,
      'tds_amount': 0,
      'is_payout': 1,
      'transaction_id': 'O9J6081026000001',
    });
    final o = liveRowToMockOrder(row)!;
    expect(o.bankReturnAmount, 31635);
    expect(o.bankReturnAmount, isNot(32343 + 900));
    expect(o.deal.earn, 900);
    expect(o.deal.cashback, 1608);
    expect(o.deal.walletFromMintzer, 31635);
  });

  test('paid_at maps to paidOn for Paid on date', () {
    final row = liveOrderRowFromJson({
      'accept_order_id': 1257,
      'store_order_id': 'OD338787534076189100',
      'earning_price': 900,
      'order_amount': 32343,
      'mintzer_payout': 31635,
      'is_payout': 1,
      'transaction_id': 'O9J6081026000001',
      'paid_at': '2026-10-08 16:22:00',
    });
    final o = liveRowToMockOrder(row)!;
    expect(o.paidOn, isNotNull);
    expect(o.paidOn!.year, 2026);
    expect(o.paidOn!.month, 10);
    expect(o.paidOn!.day, 8);
  });

  test('bundled live dump JSON maps without crash', () {
    final file = File('assets/live/must_test_orders.json');
    expect(file.existsSync(), isTrue);
    final list = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    OrdersRepository.instance.loadRemoteJson(list);
    final orders = OrdersRepository.instance.fetchOrders();
    // Soft-deleted dump rows may be filtered — still must not throw while mapping.
    for (final raw in list) {
      expect(() => liveOrderRowFromJson(Map<String, dynamic>.from(raw as Map)), returnsNormally);
      final row = liveOrderRowFromJson(Map<String, dynamic>.from(raw as Map));
      expect(() => liveRowToMockOrder(row), returnsNormally);
    }
    for (final o in orders) {
      expect(() => o.actionLabel, returnsNormally);
      expect(() => o.deal.earn, returnsNormally);
    }
    OrdersRepository.instance.clearRemote();
  });
  test('live Hostinger shapes (tracking + invoice + paid) map without crash', () {
    final file = File('assets/live/live_mapper_shapes_export.json');
    expect(file.existsSync(), isTrue);
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(decoded['status'], isTrue);
    final rows = decoded['rows'] as List<dynamic>;
    expect(rows.length, greaterThanOrEqualTo(2));
    final labels = <String>[];
    for (final raw in rows) {
      final map = Map<String, dynamic>.from(raw as Map);
      labels.add(map['_label']?.toString() ?? '');
      final row = liveOrderRowFromJson(map);
      final step = mapLiveOrderSafe(row);
      expect(step, isNot(RailStep.hide));
      final order = liveRowToMockOrder(row);
      expect(order, isNotNull);
      expect(() => order!.actionLabel, returnsNormally);
      expect(() => order!.deal.earn, returnsNormally);
    }
    expect(labels, contains('tracking_due'));
    expect(labels, contains('already_paid'));
    expect(labels, contains('invoice_due'));
  });
}
