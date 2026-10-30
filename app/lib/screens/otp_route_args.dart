/// Args for `/login/otp` — phone + optional in-flight send (instant navigate).
class OtpRouteArgs {
  const OtpRouteArgs({
    required this.phone,
    this.sendFuture,
  });

  final String phone;

  /// Completes when live `sendotp` finishes. Null = already sent / demo path.
  final Future<void>? sendFuture;
}
