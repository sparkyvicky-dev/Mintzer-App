import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/auth_api.dart';
import '../l10n/strings.dart';
import '../mock/session.dart';
import '../mock/session_store.dart';
import '../theme/app_theme.dart';
import '../util/external_links.dart';
import '../util/otp_sms_autofill.dart';
import '../widgets/lang_rail.dart';
import 'otp_route_args.dart';

/// Login UI locked 20 Sep 2026 — Welcome + benefits + unified phone (ChatGPT polish pass).
/// Set false only to revive pre-lock “Get Started” layout for comparison.
const bool kChatGptLoginPreview = true;

/// Login — locked demo or ChatGPT proportion preview (`kChatGptLoginPreview`).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _phoneFocus = FocusNode();
  late final ValueNotifier<String> _lang;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _lang = ValueNotifier(MockSession.language);
  }

  @override
  void dispose() {
    _phone.dispose();
    _phoneFocus.dispose();
    _lang.dispose();
    super.dispose();
  }

  String _t(String key) => L10n.t(_lang.value, key);

  void _setLang(String code) {
    if (code == _lang.value) return;
    MockSession.language = code;
    _lang.value = code;
    SessionStore.save();
  }

  Future<void> _getOtp() async {
    final phone = _phone.text.trim();
    if (phone.length != 10 || _sending) return;

    // Demo suspended path — no SMS.
    if (phone.endsWith('0000')) {
      if (!mounted) return;
      Navigator.of(context).pushNamed('/login/otp', arguments: OtpRouteArgs(phone: phone));
      return;
    }

    setState(() => _sending = true);
    // Listen before SMS lands; navigate immediately (don’t wait on Hostinger/SMS hub).
    OtpSmsAutofill.arm();
    final sendFuture = AuthApi.instance.sendOtp(phone);
    if (!mounted) return;
    Navigator.of(context).pushNamed(
      '/login/otp',
      arguments: OtpRouteArgs(phone: phone, sendFuture: sendFuture),
    );
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return kChatGptLoginPreview ? _buildChatGpt() : _buildLocked();
  }

  Widget _buildChatGpt() {
    const r = 10.0;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 140,
            child: CustomPaint(painter: _SoftWavePainter()),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 8),
                            Image.asset(
                              'assets/logos/mintzer-mark-circle.png',
                              width: 72,
                              height: 72,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            ValueListenableBuilder<String>(
                              valueListenable: _lang,
                              builder: (context, lang, _) {
                                return Column(
                                  children: [
                                    LangFadeText(
                                      language: lang,
                                      text: _t('login_welcome'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF202124),
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    LangFadeText(
                                      language: lang,
                                      text: _t('login_sub_benefit'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF5F6368),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            ValueListenableBuilder<String>(
                              valueListenable: _lang,
                              builder: (context, lang, _) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _Benefit(
                                        icon: Icons.shopping_cart_outlined,
                                        label: _t('login_benefit_1'),
                                        lang: lang,
                                      ),
                                    ),
                                    Container(width: 1, height: 40, color: const Color(0xFFE8EAED)),
                                    Expanded(
                                      child: _Benefit(
                                        icon: Icons.inventory_2_outlined,
                                        label: _t('login_benefit_2'),
                                        lang: lang,
                                      ),
                                    ),
                                    Container(width: 1, height: 40, color: const Color(0xFFE8EAED)),
                                    Expanded(
                                      child: _Benefit(
                                        icon: Icons.account_balance_wallet_outlined,
                                        label: _t('login_benefit_3'),
                                        lang: lang,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 28),
                            ValueListenableBuilder<String>(
                              valueListenable: _lang,
                              builder: (context, lang, _) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: LangFadeText(
                                    language: lang,
                                    text: _t('login_mobile'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF202124),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            _UnifiedPhoneField(
                              controller: _phone,
                              focusNode: _phoneFocus,
                              radius: r,
                            ),
                            const SizedBox(height: 8),
                            ValueListenableBuilder<String>(
                              valueListenable: _lang,
                              builder: (context, lang, _) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: LangFadeText(
                                    language: lang,
                                    text: _t('login_otp_hint'),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.3),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            ListenableBuilder(
                              listenable: _phone,
                              builder: (context, _) {
                                final ok = _phone.text.trim().length == 10;
                                return ValueListenableBuilder<String>(
                                  valueListenable: _lang,
                                  builder: (context, lang, _) {
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: FilledButton(
                                        onPressed: (ok && !_sending) ? _getOtp : null,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: MintzerColors.primary,
                                          disabledBackgroundColor: const Color(0xFFE8EAED),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
                                          elevation: 0,
                                        ),
                                        child: _sending
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : LangFadeText(
                                                language: lang,
                                                text: _t('login_get_otp_short'),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            ValueListenableBuilder<String>(
                              valueListenable: _lang,
                              builder: (context, lang, _) {
                                return _TermsLine(language: lang, prefix: _t('login_terms_prefix'));
                              },
                            ),
                            const SizedBox(height: 16),
                            ValueListenableBuilder<String>(
                              valueListenable: _lang,
                              builder: (context, lang, _) {
                                return LangRail(
                                  language: lang,
                                  onChanged: _setLang,
                                  compact: true,
                                );
                              },
                            ),
                            const Spacer(),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                _t('login_footer_slogan').toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: Color(0xFF80868B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocked() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Image.asset(
                  'assets/logos/mintzer-mark-circle.png',
                  width: 88,
                  height: 88,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<String>(
                  valueListenable: _lang,
                  builder: (context, lang, _) {
                    return Column(
                      children: [
                        LangFadeText(
                          language: lang,
                          text: _t('login_get_started'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: MintzerColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LangFadeText(
                          language: lang,
                          text: _t('login_sub'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: MintzerColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                ValueListenableBuilder<String>(
                  valueListenable: _lang,
                  builder: (context, lang, _) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: LangFadeText(
                        language: lang,
                        text: _t('login_mobile'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: MintzerColors.ink,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: MintzerColors.line),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: const Text('+91', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _phone,
                        focusNode: _phoneFocus,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          counterText: '',
                          hintText: '10-digit number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: MintzerColors.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: _phone,
                  builder: (context, _) {
                    final ok = _phone.text.trim().length == 10;
                    return ValueListenableBuilder<String>(
                      valueListenable: _lang,
                      builder: (context, lang, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: (ok && !_sending) ? _getOtp : null,
                            child: _sending
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : LangFadeText(
                                    language: lang,
                                    text: _t('login_get_otp'),
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<String>(
                  valueListenable: _lang,
                  builder: (context, lang, _) {
                    return LangFadeText(
                      language: lang,
                      text: _t('login_terms'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: MintzerColors.muted),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: _lang,
                  builder: (context, lang, _) {
                    return LangRail(language: lang, onChanged: _setLang);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnifiedPhoneField extends StatelessWidget {
  const _UnifiedPhoneField({
    required this.controller,
    required this.focusNode,
    required this.radius,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: focused ? MintzerColors.primary : const Color(0xFFDADCE0),
              width: focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Text('+91', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF202124))),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(height: 22, child: VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE8EAED))),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF202124)),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: '10-digit number',
                    hintStyle: TextStyle(fontWeight: FontWeight.w400, color: Color(0xFF9AA0A6)),
                    isDense: true,
                    contentPadding: EdgeInsets.only(right: 8, top: 12, bottom: 12),
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: Listenable.merge([controller, focusNode]),
                builder: (context, _) {
                  final showClear = focusNode.hasFocus && controller.text.isNotEmpty;
                  if (!showClear) return const SizedBox(width: 8);
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: controller.clear,
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFF9AA0A6)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label, required this.lang});
  final IconData icon;
  final String label;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: Color(0xFFF3F0FF), shape: BoxShape.circle),
          child: Icon(icon, size: 22, color: MintzerColors.primary),
        ),
        const SizedBox(height: 8),
        LangFadeText(
          language: lang,
          text: label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5F6368), height: 1.25),
        ),
      ],
    );
  }
}

class _TermsLine extends StatelessWidget {
  const _TermsLine({required this.language, required this.prefix});
  final String language;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368), height: 1.35),
        children: [
          TextSpan(text: prefix),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => openTerms(context),
              child: Text(
                L10n.t(language, 'login_terms_link'),
                style: const TextStyle(
                  fontSize: 11,
                  color: MintzerColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: MintzerColors.primary,
                ),
              ),
            ),
          ),
          const TextSpan(text: ' & '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => openPrivacy(context),
              child: Text(
                L10n.t(language, 'login_privacy_link'),
                style: const TextStyle(
                  fontSize: 11,
                  color: MintzerColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: MintzerColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _SoftWavePainter extends CustomPainter {
  const _SoftWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x147B61FF);
    final path = Path()
      ..moveTo(0, size.height * 0.38)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.12, size.width * 0.5, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.58, size.width, size.height * 0.3)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
    final paint2 = Paint()..color = const Color(0x0E7B61FF);
    final path2 = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.38, size.width * 0.55, size.height * 0.52)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.72, size.width, size.height * 0.48)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
