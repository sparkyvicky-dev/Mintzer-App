import 'package:flutter_test/flutter_test.dart';
import 'package:mintzer/live/order_mapper.dart';
import 'package:mintzer/models/deal.dart';
import 'package:mintzer/models/mock_order.dart';
import 'package:mintzer/util/delivery_call.dart';

void main() {
  test('call message includes order, product, courier, tracking, and otp', () {
    final order = MockOrder(
      id: 'ord_1',
      mintzerId: 'ORD000201',
      deal: const MockDeal(
        id: 'd',
        type: 'direct',
        name: 'iQOO Neo 10',
        color: 'Alpine White',
        variant: '8GB/256GB',
        gst: true,
        storeId: 'iqoo',
        storeLabel: 'iQOO',
        cardId: 'onecard',
        cardLabel: 'OneCard',
        orderValue: 27999,
        commission: 500,
      ),
      orderId: 'OD990011122',
      step: 3,
      courier: 'Ekart',
      tracking: 'EK9988776655',
      phoneLast4: '3210',
      otp: '482916',
    );

    expect(deliveryCallReady(order), isTrue);
    expect(
      deliveryCallMessage(order),
      'Delivery boy is calling me now.\n'
      '\n'
      'Order ID: OD990011122\n'
      'Mintzer order: ORD000201\n'
      'Product: iQOO Neo 10\n'
      'Courier: Ekart\n'
      'Tracking ID: EK9988776655\n'
      'Last 4: 3210\n'
      'OTP: 482916',
    );
  });

  test('button stays off before otp and after confirmation', () {
    final order = MockOrder(
      id: 'ord_2',
      deal: const MockDeal(
        id: 'd',
        type: 'direct',
        name: 'Phone',
        color: 'Black',
        variant: '1',
        gst: false,
        storeId: 'flipkart',
        storeLabel: 'Flipkart',
        cardId: 'any',
        cardLabel: 'Any',
        orderValue: 100,
        commission: 10,
      ),
      orderId: 'OD1',
      step: 2,
    );
    expect(deliveryCallReady(order), isFalse);

    final liveAfterOtp = MockOrder(
      id: 'ord_3',
      deal: order.deal,
      orderId: 'OD1',
      step: 3,
      otp: '482916',
      liveRail: RailStep.confirmation,
    );
    expect(deliveryCallReady(liveAfterOtp), isTrue);

    final liveInvoiceOpen = MockOrder(
      id: 'ord_3b',
      deal: order.deal,
      orderId: 'OD1',
      step: 4,
      otp: '482916',
      liveRail: RailStep.invoice,
    );
    expect(deliveryCallReady(liveInvoiceOpen), isTrue);

    final invoiceIn = MockOrder(
      id: 'ord_4',
      deal: order.deal,
      orderId: 'OD1',
      step: 4,
      otp: '482916',
      liveRail: RailStep.invoiceVerifying,
    );
    expect(deliveryCallReady(invoiceIn), isFalse);
  });

  test('help message names the order and does not include otp', () {
    final order = MockOrder(
      id: 'ord_h',
      mintzerId: 'ORD000201',
      deal: const MockDeal(
        id: 'd',
        type: 'direct',
        name: 'iQOO Neo 10',
        color: 'Alpine White',
        variant: '8GB/256GB',
        gst: true,
        storeId: 'iqoo',
        storeLabel: 'iQOO',
        cardId: 'onecard',
        cardLabel: 'OneCard',
        orderValue: 27999,
        commission: 500,
      ),
      orderId: 'OD990011122',
      tracking: 'EK9988776655',
      otp: '482916',
    );
    final text = deliveryHelpMessage(order);
    expect(text, contains('I need help with this order'));
    expect(text, contains('Order ID: OD990011122'));
    expect(text, contains('Product: iQOO Neo 10'));
    expect(text, contains('Tracking ID: EK9988776655'));
    expect(text, isNot(contains('OTP')));
  });

  test('calling headline follows the button words', () {
    final order = MockOrder(
      id: 'ord_h2',
      deal: const MockDeal(
        id: 'd',
        type: 'direct',
        name: 'Phone',
        color: 'Black',
        variant: '1',
        gst: false,
        storeId: 'flipkart',
        storeLabel: 'Flipkart',
        cardId: 'any',
        cardLabel: 'Any',
        orderValue: 100,
        commission: 10,
      ),
      orderId: 'OD1',
      otp: '482916',
    );
    expect(deliveryCallMessage(order, line: 'Delivery agent calling?'), contains('Delivery agent is calling me now.'));
    expect(deliveryCallMessage(order, line: 'Delivery person calling?'), contains('Delivery person is calling me now.'));
    expect(kDeliveryCallLines, contains('Delivery boy calling?'));
    expect(kDeliveryCallLines, contains('Rescheduled?'));
  });
}
