import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mintzer/app.dart';
import 'package:mintzer/live/live_deal_adapter.dart';
import 'package:mintzer/mock/sample_deals.dart';
import 'package:mintzer/mock/session.dart';
import 'package:mintzer/models/mock_order.dart';
import 'package:mintzer/models/mock_ticket.dart';
import 'package:mintzer/screens/deal_detail_screen.dart';
import 'package:mintzer/screens/home_screen.dart';
import 'package:mintzer/screens/order_success_screen.dart';
import 'package:mintzer/screens/orders_screen.dart';
import 'package:mintzer/screens/payout_details_screen.dart';
import 'package:mintzer/screens/profile_screen.dart';
import 'package:mintzer/screens/tickets_screen.dart';
import 'package:mintzer/screens/wallet_screen.dart';
import 'package:mintzer/theme/app_theme.dart';
import 'package:mintzer/util/format.dart';

void main() {
  setUp(() {
    MockSession.activeDeal.value = null;
    MockSession.tabIndex.value = 0;
    MockSession.resetTickets();
    MockSession.themeMode.value = ThemeMode.light;
  });

  testWidgets('login shell loads', (tester) async {
    await tester.pumpWidget(const MintzerApp());
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Accept. Order. Get paid.'), findsOneWidget);
    expect(find.text('Get OTP →'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
  });

  testWidgets('login language switches copy', (tester) async {
    await tester.pumpWidget(const MintzerApp());
    await tester.tap(find.text('हि'));
    await tester.pumpAndSettle();
    expect(find.text('शुरू करें'), findsOneWidget);
    expect(find.text('स्वीकारो. ऑर्डर. पेमेंट.'), findsOneWidget);
  });

  test('indian rupee grouping', () {
    expect(formatInr(300), '₹300');
    expect(formatInr(22999), '₹22,999');
    expect(formatInr(17519), '₹17,519');
    expect(formatInr(79900), '₹79,900');
  });

  test('wallet and checkout formulas', () {
    final d = kSampleDeals.firstWhere((e) => e.id == 'd1');
    expect(d.spend, 17519);
    expect(d.walletFromMintzer, 16424);
    expect(d.earn, 300);
  });

  test('live deal wires receive and cash reward', () {
    final d = liveDealFromJson({
      'id': 9,
      'name': 'Phone',
      'original_price': 32000,
      'selling_price': 32000,
      'cashback': 401,
      'earning_price': 400,
      'tds_amount': 40,
      'cash_reward': 150,
      'card_holder_receive': 8000,
    });
    expect(d, isNotNull);
    expect(d!.walletFromMintzer, 8000);
    expect(d.cashRewardShown, 150);
    expect(d.earn, 360);
  });

  test('submitOrder clears placement and prepends order', () {
    final deal = kSampleDeals.first;
    MockSession.activeDeal.value = deal;
    final before = MockSession.orders.value.length;
    final o = MockSession.submitOrder(deal: deal, orderId: 'OD123456789');
    expect(MockSession.activeDeal.value, isNull);
    expect(o.orderId, 'OD123456789');
    expect(o.step, 1);
    expect(MockSession.orders.value.length, before + 1);
    expect(MockSession.orders.value.first.id, o.id);
  });

  testWidgets('home grid shows earn buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: HomeScreen(onWallet: () {}),
      ),
    );
    expect(find.textContaining('Earn ₹'), findsWidgets);
    expect(find.text('All Deals'), findsOneWidget);
  });

  testWidgets('deal detail money card', (tester) async {
    final deal = kSampleDeals.firstWhere((e) => e.id == 'd2');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DealDetailScreen(deal: deal),
      ),
    );
    expect(find.text('Product value'), findsOneWidget);
    expect(find.text('Checkout value'), findsOneWidget);
    expect(find.text('From Mintzer'), findsOneWidget);
    expect(find.text('From bank cashback'), findsOneWidget);
    expect(find.text('Swipe to accept  ›››'), findsOneWidget);
  });

  testWidgets('orders screen shows Ongoing and View order', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const OrdersScreen(),
      ),
    );
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('Ongoing'), findsOneWidget);
    expect(find.text('Add tracking ID'), findsWidgets);
    expect(find.text('View order'), findsWidgets);
  });

  testWidgets('order success shows Go to My Orders', (tester) async {
    final o = MockOrder(
      id: 'ord_t',
      deal: kSampleDeals.first,
      orderId: 'OD111',
      successPromo: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: OrderSuccessScreen(order: o),
      ),
    );
    expect(find.text('Order Placed'), findsOneWidget);
    expect(find.text('Go to My Orders →'), findsOneWidget);
  });

  testWidgets('wallet shows Total earned and no withdraw', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const WalletScreen(),
      ),
    );
    expect(find.text('Total earned'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Withdraw'), findsNothing);
  });

  testWidgets('profile opens FAQ', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const ProfileScreen(),
      ),
    );
    expect(find.text('Refer & earn ₹200'), findsOneWidget);
    await tester.tap(find.text('FAQ'));
    await tester.pumpAndSettle();
    expect(find.text('What is Mintzer?'), findsOneWidget);
  });

  testWidgets('My tickets list shows seed ticket', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const TicketsScreen(),
      ),
    );
    expect(find.text('TKT-240917'), findsOneWidget);
    expect(find.text('Paid extra vs app'), findsOneWidget);
  });

  testWidgets('payout details save form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const PayoutDetailsScreen(),
      ),
    );
    expect(find.text('Where should we send your earnings?'), findsOneWidget);
    expect(find.text('Arun Kumar'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  test('createTicket prepends and simulate advances status', () {
    final before = MockSession.tickets.value.length;
    final t = MockSession.createTicket(
      subject: 'Different color',
      category: 'diff_color',
      orderId: 'OD998877665',
      answers: const ['No'],
      message: 'Wrong color arrived',
    );
    expect(MockSession.tickets.value.length, before + 1);
    expect(t.status, TicketStatus.submitted);
    MockSession.simulateAdminReply(t);
    expect(t.status, TicketStatus.inProgress);
    MockSession.simulateAdminReply(t);
    expect(t.status, TicketStatus.resolved);
  });
}
