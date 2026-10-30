import '../live/order_mapper.dart';
import '../models/mock_order.dart';

/// After the delivery OTP is saved, until the invoice is uploaded.
/// Live: Confirmation wait and unlocked Invoice both count.
/// Checking invoice, Payment, Paid, and Canceled do not show the button.
bool deliveryCallReady(MockOrder order) {
  if (!order.ongoing) return false;
  if (order.otp.trim().length < 4) return false;
  final rail = order.liveRail;
  if (rail != null) {
    return rail == RailStep.confirmation || rail == RailStep.invoice;
  }
  return order.step == 3;
}

const kDeliveryCallLines = [
  'Delivery boy calling?',
  'Delivery agent calling?',
  'Delivery person calling?',
  'Any other issue?',
  'Rescheduled?',
];

/// First WhatsApp line for the calling phrase the user tapped.
String deliveryCallHeadline(String line) {
  if (line.contains('agent')) return 'Delivery agent is calling me now.';
  if (line.contains('person')) return 'Delivery person is calling me now.';
  return 'Delivery boy is calling me now.';
}

/// WhatsApp text for a delivery-calling tap. Reschedule does not use this.
String deliveryCallMessage(MockOrder order, {String line = ''}) {
  final lines = <String>[deliveryCallHeadline(line), ''];
  final storeId = order.hasStoreOrderId ? order.orderId.trim() : order.mintzerId;
  lines.add('Order ID: $storeId');
  final mintzer = order.mintzerId.trim();
  if (mintzer.isNotEmpty && mintzer != storeId) {
    lines.add('Mintzer order: $mintzer');
  }
  final product = order.deal.name.trim();
  if (product.isNotEmpty) lines.add('Product: $product');
  final courier = order.courier.trim();
  if (courier.isNotEmpty) lines.add('Courier: $courier');
  final tracking = order.tracking.trim();
  if (tracking.isNotEmpty) lines.add('Tracking ID: $tracking');
  final last4 = order.phoneLast4.trim();
  if (last4.isNotEmpty) lines.add('Last 4: $last4');
  final otp = order.otp.trim();
  if (otp.isNotEmpty) lines.add('OTP: $otp');
  return lines.join('\n');
}

/// WhatsApp text for “Any other issue?”. Reschedule does not use this.
String deliveryHelpMessage(MockOrder order) {
  final lines = <String>['Hi Mintzer, I need help with this order.', ''];
  final storeId = order.hasStoreOrderId ? order.orderId.trim() : order.mintzerId;
  lines.add('Order ID: $storeId');
  final mintzer = order.mintzerId.trim();
  if (mintzer.isNotEmpty && mintzer != storeId) {
    lines.add('Mintzer order: $mintzer');
  }
  final product = order.deal.name.trim();
  if (product.isNotEmpty) lines.add('Product: $product');
  final tracking = order.tracking.trim();
  if (tracking.isNotEmpty) lines.add('Tracking ID: $tracking');
  return lines.join('\n');
}
