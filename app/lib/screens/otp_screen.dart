import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/auth_api.dart';
import '../api/profile_api.dart';
import '../l10n/strings.dart';
import '../live/banners_repository.dart';
import '../live/deals_repository.dart';
import '../live/notifications_repository.dart';
import '../live/orders_repository.dart';
import '../live/partner_cards_repository.dart';
import '../live/tickets_repository.dart';
import '../mock/session.dart';
import '../mock/session_store.dart';
import '../push/push_bootstrap.dart';
import '../theme/app_theme.dart';
import '../util/otp_sms_autofill.dart';
import '../widgets/lang_rail.dart';
import '../widgets/mintzer_toast.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone, this.sendFuture});

  final String phone;

  /// In-flight `sendotp` from login (screen opens immediately).
  final Future<void>? sendFuture;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _digits = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
  final _hidden = TextEditingController();
  int _resendSec = 30;
  bool _verifying = false;
  bool _resending = false;
  bool _sendingSms = false;
  bool _sendFailed = false;

  static const _radius = 10.0;

  @override
  void initState() {
    super.initState();
    _sendingSms = widget.sendFuture != null;
    _awaitSend();
    _awaitSmsConsent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.first.requestFocus();
    });
  }

  Future<void> _awaitSend() async {
    final future = widget.sendFuture;
    if (future == null) {
      _tickResend();
      return;
    }
    try {
      await future;
      if (!mounted) return;
      setState(() => _sendingSms = false);
      _tickResend();
    } on AuthApiException catch (e) {
      await OtpSmsAutofill.cancel();
      if (!mounted) return;
      setState(() {
        _sendingSms = false;
        _sendFailed = true;
      });
      showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
      Navigator.of(context).pop();
    } catch (_) {
      await OtpSmsAutofill.cancel();
      if (!mounted) return;
      setState(() {
        _sendingSms = false;
        _sendFailed = true;
      });
      showMintzerToast(
        context,
        'Couldn’t send OTP. Check your connection.',
        kind: MintzerToastKind.danger,
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _awaitSmsConsent() async {
    if (widget.phone.endsWith('0000')) return;
    final code = await OtpSmsAutofill.consume();
    if (!mounted || code == null || code.isEmpty || _sendFailed) return;
    _applyCode(code);
  }

  void _applyCode(String raw) {
    final digits = raw.length > 6 ? raw.substring(0, 6) : raw;
    for (var j = 0; j < 6; j++) {
      _digits[j].text = j < digits.length ? digits[j] : '';
    }
    _hidden.text = digits;
    setState(() {});
    if (digits.length == 6) {
      _focus[5].unfocus();
      _verify();
    } else if (digits.isNotEmpty) {
      _focus[digits.length.clamp(0, 5)].requestFocus();
    }
  }

  void _tickResend() async {
    while (mounted && _resendSec > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _resendSec--);
    }
  }

  @override
  void dispose() {
    OtpSmsAutofill.cancel();
    _hidden.dispose();
    for (final c in _digits) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _digits.map((c) => c.text).join();
  String _t(String key, [Map<String, String>? vars]) => L10n.t(MockSession.language, key, vars);

  /// +91 68686 68686
  String get _phoneDisplay {
    final d = widget.phone.replaceAll(RegExp(r'\D'), '');
    if (d.length == 10) return '+91 ${d.substring(0, 5)} ${d.substring(5)}';
    return '+91 $d';
  }

  Future<void> _verify() async {
    if (_verifying || _code.length != 6) return;
    setState(() => _verifying = true);

    if (widget.phone.endsWith('0000')) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/suspended');
      return;
    }

    try {
      final result = await AuthApi.instance.verifyOtp(mobile10: widget.phone, otp: _code);
      MockSession.phoneDigits = widget.phone.replaceAll(RegExp(r'\D'), '').substring(0, 10);
      MockSession.authToken = result.token;
      MockSession.userId = result.userId;
      await SessionStore.save();
      if (!mounted) return;
      // Go to intro immediately — never block on push/orders/deals/profile network.
      Navigator.of(context).pushReplacementNamed('/intro');
      // ignore: discarded_futures
      _warmSessionAfterLogin(result.token);
    } on AuthApiException catch (e) {
      if (!mounted) return;
      setState(() => _verifying = false);
      showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
    } catch (_) {
      if (!mounted) return;
      setState(() => _verifying = false);
      showMintzerToast(
        context,
        'Couldn’t verify. Check your connection.',
        kind: MintzerToastKind.danger,
      );
    }
  }

  Future<void> _warmSessionAfterLogin(String token) async {
    try {
      await PushBootstrap.syncTokenToBackend();
    } catch (_) {}
    Future<void> soft(Future<dynamic> f) async {
      try {
        await f;
      } catch (_) {}
    }

    await Future.wait([
      soft(OrdersRepository.instance.refreshFromLiveApi()),
      soft(DealsRepository.instance.refreshFromLiveApi()),
      soft(TicketsRepository.instance.refreshFromLiveApi()),
      soft(NotificationsRepository.instance.refreshFromLiveApi()),
      soft(ProfileApi.instance.refreshProfileIntoSession(authToken: token)),
      soft(ProfileApi.instance.refreshBankIntoSession(authToken: token)),
      soft(ProfileApi.instance.refreshReferralIntoSession(authToken: token)),
      soft(BannersRepository.instance.refreshFromLiveApi()),
      soft(PartnerCardsRepository.instance.refreshFromLiveApi()),
    ]);
  }

  void _onOtpChanged(int i, String v) {
    if (i == 0 && v.length > 1) {
      _applyCode(v);
      return;
    }
    if (v.length > 1) {
      _applyCode(v);
      return;
    }
    if (v.isNotEmpty && i < 5) _focus[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _focus[i - 1].requestFocus();
    setState(() {});
    if (_code.length == 6) _verify();
  }

  Future<void> _resend() async {
    if (_resending || widget.phone.endsWith('0000')) {
      setState(() => _resendSec = 30);
      _tickResend();
      return;
    }
    setState(() => _resending = true);
    OtpSmsAutofill.arm();
    try {
      await AuthApi.instance.sendOtp(widget.phone);
      if (!mounted) return;
      setState(() {
        _resendSec = 30;
        _resending = false;
      });
      _tickResend();
      showMintzerToast(context, 'OTP sent again', kind: MintzerToastKind.info);
      // Keep listening for the new SMS (arm already started).
      final code = await OtpSmsAutofill.consume();
      if (!mounted || code == null || code.isEmpty) return;
      _applyCode(code);
    } on AuthApiException catch (e) {
      await OtpSmsAutofill.cancel();
      if (!mounted) return;
      setState(() => _resending = false);
      showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
    } catch (_) {
      await OtpSmsAutofill.cancel();
      if (!mounted) return;
      setState(() => _resending = false);
      showMintzerToast(
        context,
        'Couldn’t resend OTP. Try again.',
        kind: MintzerToastKind.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ok = _code.length == 6;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: SafeArea(
        child: AutofillGroup(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const sidePad = 24.0;
              const gap = 8.0;
              final avail = constraints.maxWidth - sidePad * 2;
              final box = ((avail - gap * 5) / 6).clamp(48.0, 54.0);
              final groupW = box * 6 + gap * 5;
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                padding: EdgeInsets.fromLTRB(sidePad, 0, sidePad, 24 + MediaQuery.viewInsetsOf(context).bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logos/mintzer-mark-circle.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    LangFadeText(
                      language: MockSession.language,
                      text: _t('otp_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sendingSms
                          ? _t('otp_sending', {'phone': _phoneDisplay})
                          : _t('otp_sent', {'phone': _phoneDisplay}),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368), height: 1.35),
                    ),
                    Offstage(
                      offstage: true,
                      child: TextField(
                        controller: _hidden,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        keyboardType: TextInputType.number,
                        onChanged: _applyCode,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: groupW,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 6; i++) ...[
                            if (i > 0) SizedBox(width: gap),
                            SizedBox(
                              width: box,
                              height: box,
                              child: TextField(
                                controller: _digits[i],
                                focusNode: _focus[i],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                textInputAction: i == 5 ? TextInputAction.done : TextInputAction.next,
                                autofillHints: i == 0 ? const [AutofillHints.oneTimeCode] : null,
                                maxLength: i == 0 ? 6 : 1,
                                enableSuggestions: false,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF202124),
                                ),
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(_radius),
                                    borderSide: const BorderSide(color: Color(0xFFDADCE0), width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(_radius),
                                    borderSide: const BorderSide(color: MintzerColors.primary, width: 2),
                                  ),
                                ),
                                onChanged: (v) => _onOtpChanged(i, v),
                                onTap: () {
                                  if (_digits[i].text.isEmpty) {
                                    final firstEmpty = _digits.indexWhere((c) => c.text.isEmpty);
                                    if (firstEmpty >= 0 && firstEmpty != i) {
                                      _focus[firstEmpty].requestFocus();
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: groupW,
                      height: 44,
                      child: FilledButton(
                        onPressed: (ok && !_verifying) ? _verify : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: MintzerColors.primary,
                          disabledBackgroundColor: const Color(0xFFF3F0FF),
                          disabledForegroundColor: const Color(0xFF9B8FD4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        child: _verifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_t('otp_verify')),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_resendSec > 0)
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
                          children: [
                            TextSpan(text: _t('otp_resend_prefix')),
                            TextSpan(
                              text: '${_resendSec}s',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: MintzerColors.primary,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      TextButton(
                        onPressed: _resending ? null : _resend,
                        child: _resending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _t('otp_resend'),
                                style: const TextStyle(fontWeight: FontWeight.w700, color: MintzerColors.primary),
                              ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
