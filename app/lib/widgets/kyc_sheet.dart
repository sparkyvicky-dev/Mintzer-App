import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/s.dart';
import '../api/auth_api.dart';
import '../api/profile_api.dart';
import '../config/app_config.dart';
import '../mock/session.dart';
import '../mock/session_store.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';

/// First Accept — Step 1 of 2 (PAN). On success → Step 2 payout in same flow.
Future<bool> showKycSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (c) {
      S.watch(c);
      return const _KycBody();
    },
  );
  return result == true;
}

class _KycBody extends StatefulWidget {
  const _KycBody();

  @override
  State<_KycBody> createState() => _KycBodyState();
}

class _KycBodyState extends State<_KycBody> {
  final _pan = TextEditingController();
  String? _err;
  bool _looking = false;
  bool _verified = false;
  int _waitSecs = 0;
  Timer? _waitTimer;

  static final _panRe = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

  bool get _formatOk => _panRe.hasMatch(_pan.text);

  @override
  void dispose() {
    _waitTimer?.cancel();
    _pan.dispose();
    super.dispose();
  }

  void _startWait() {
    _waitTimer?.cancel();
    _waitSecs = 0;
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _waitSecs += 1);
    });
  }

  void _stopWait() {
    _waitTimer?.cancel();
    _waitTimer = null;
  }

  Future<void> _verify() async {
    final pan = _pan.text;
    if (!_formatOk) {
      setState(() => _err = S.e('PAN format is invalid'));
      return;
    }
    setState(() {
      _err = null;
      _looking = true;
    });
    _startWait();

    try {
      if (!AppConfig.panVerifyLiveEnabled || MockSession.authToken.isEmpty) {
        _stopWait();
        setState(() {
          _looking = false;
          // l10n-missing
          _err = 'PAN verification is unavailable. Try again.';
        });
        return;
      }
      final name = await ProfileApi.instance.panVerify(
        authToken: MockSession.authToken,
        pan: pan,
      );
      if (!mounted) return;
      _stopWait();
      setState(() {
        _looking = false;
        _verified = true;
        MockSession.panName = personName(name);
        MockSession.panNumber = pan;
        MockSession.kycDone = true;
      });
      await SessionStore.save();
    } on AuthApiException catch (e) {
      if (!mounted) return;
      _stopWait();
      setState(() {
        _looking = false;
        _err = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      _stopWait();
      setState(() {
        _looking = false;
        _err = S.e('PAN could not be verified. Try again.');
      });
    }
  }

  Future<void> _continueToPayout() async {
    // Close KYC, open payout immediately (continuous Step 1 → 2).
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFDADCE0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Text(S.e('Verify PAN'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            // l10n-missing
            const Text('Step 1 of 2', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MintzerColors.primary)),
            const SizedBox(height: 8),
            // l10n-missing
            const Text(
              'Verify your PAN to accept your first deal.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF202124), height: 1.35),
            ),
            const SizedBox(height: 4),
            Text(
              S.e('Your verified name will be used for payout setup.'),
              style: TextStyle(fontSize: 13, color: Color(0xFF5F6368), height: 1.35),
            ),
            const SizedBox(height: 16),
            if (!_verified) ...[
              Text(S.t('pan_number'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
              const SizedBox(height: 6),
              TextField(
                controller: _pan,
                autofocus: true,
                maxLength: 10,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                  color: Color(0xFF202124),
                ),
                inputFormatters: [PanTextFormatter()],
                decoration: softInputDecoration(
                  hint: 'ABCDE1234F',
                  errorText: _err,
                ).copyWith(counterText: ''),
                onChanged: (_) => setState(() {
                  _err = null;
                }),
              ),
              if (_formatOk && _err == null && !_looking) ...[
                const SizedBox(height: 8),
                 Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Color(0xFF188038)),
                    SizedBox(width: 6),
                    Text(S.e('Valid PAN format'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF188038))),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              // l10n-missing
              const Text(
                'Used to verify your identity and process payouts.',
                style: TextStyle(fontSize: 11, color: Color(0xFF9AA0A6), height: 1.3),
              ),
              if (_looking) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(color: MintzerColors.primary, minHeight: 3),
                const SizedBox(height: 8),
                // l10n-missing
                const Text(
                  'Checking the name on this PAN.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                ),
                if (_waitSecs > 0)
                  Text(
                    // l10n-missing
                    '${_waitSecs}s',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5F6368)),
                  ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: (_formatOk && !_looking) ? _verify : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: MintzerColors.primary,
                  disabledBackgroundColor: const Color(0xFFE8EAED),
                  disabledForegroundColor: const Color(0xFF9AA0A6),
                ),
                child: Text(S.e('Verify PAN')),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF9AA0A6),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: Text(S.t('cancel')),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                S.e('Used for identity verification and payout setup.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFF9AA0A6)),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCEEAD6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                      children: [
                        Icon(Icons.check_circle, size: 20, color: Color(0xFF188038)),
                        SizedBox(width: 8),
                        Text(S.e('PAN verified'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF188038))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      personName(MockSession.panName),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF202124)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.e('Your identity has been verified. This name will be used for payout-account matching.'),
                      style: TextStyle(fontSize: 12, color: Color(0xFF137333), height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _continueToPayout,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48), backgroundColor: MintzerColors.primary),
                child: Text(S.e('Continue to payout setup →')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Uppercase + strip spaces/specials; max 10.
class PanTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final clipped = cleaned.length > 10 ? cleaned.substring(0, 10) : cleaned;
    return TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
  }
}

InputDecoration softInputDecoration({String? hint, String? errorText, String? label}) {
  const fill = Color(0xFFF7F7F9);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFFE8EAED)),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: Color(0xFF9AA0A6),
      letterSpacing: 0,
      height: 1.3,
    ),
    errorText: errorText,
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: MintzerColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD93025)),
    ),
  );
}
