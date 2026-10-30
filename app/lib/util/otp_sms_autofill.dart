import 'package:smart_auth/smart_auth.dart';

/// Android OTP capture for Mintzer SMS.
///
/// Silent [SMS Retriever] needs an 11-char app hash inside the DLT text — our
/// approved Mintzer template does not include that, so Retriever never fires.
/// We use [SMS User Consent] instead: system shows “Allow Mintzer to read this
/// one message?” → fills the 6-digit code.
class OtpSmsAutofill {
  OtpSmsAutofill._();

  static Future<String?>? _pending;

  /// Call **before** `sendOtp` so listening is active when the SMS arrives.
  static void arm() {
    _pending = _listenOnce();
  }

  /// Await the armed listener, or start a new one if [arm] was skipped.
  static Future<String?> consume() {
    final pending = _pending;
    _pending = null;
    return pending ?? _listenOnce();
  }

  static Future<void> cancel() async {
    _pending = null;
    await SmartAuth.instance.removeUserConsentApiListener();
  }

  static Future<String?> _listenOnce() async {
    try {
      final res = await SmartAuth.instance.getSmsWithUserConsentApi(
        matcher: r'\d{6}',
      );
      if (!res.hasData) return null;
      final sms = res.data!;
      final fromCode = sms.code?.replaceAll(RegExp(r'\D'), '') ?? '';
      if (fromCode.length >= 6) return fromCode.substring(0, 6);
      final m = RegExp(r'\b(\d{6})\b').firstMatch(sms.sms);
      return m?.group(1);
    } catch (_) {
      return null;
    }
  }
}
