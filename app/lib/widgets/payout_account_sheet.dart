import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/s.dart';
import '../api/auth_api.dart';
import '../api/profile_api.dart';
import '../mock/session.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import 'kyc_sheet.dart' show showKycSheet, softInputDecoration;
import 'mintzer_toast.dart';

/// First Accept Step 2 / Profile — payout account (IFSC → bank, no bank dropdown).
Future<bool> showPayoutSheet(BuildContext context, {bool stepOfTwo = true}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) {
      S.watch(ctx);
      return PayoutAccountForm(asSheet: true, showStep: stepOfTwo);
    },
  );
  return result == true;
}

class PayoutAccountForm extends StatefulWidget {
  const PayoutAccountForm({
    super.key,
    this.asSheet = false,
    this.showStep = false,
    this.onSaved,
  });

  final bool asSheet;
  final bool showStep;
  /// Profile screen: called after save instead of Navigator.pop(true).
  final VoidCallback? onSaved;

  @override
  State<PayoutAccountForm> createState() => _PayoutAccountFormState();
}

class _PayoutAccountFormState extends State<PayoutAccountForm> {
  late final TextEditingController _acct;
  late final TextEditingController _confirm;
  late final TextEditingController _ifsc;
  late final TextEditingController _upi;
  String? _acctErr;
  String? _confirmErr;
  String? _ifscErr;
  String? _upiErr;
  String? _bank;
  String? _branch;
  bool _lookingIfsc = false;
  /// Bank account or UPI. One payout method at a time.
  bool _upiMode = false;
  bool _saving = false;
  /// When payout already saved: show summary until user taps Change.
  late bool _editing;

  @override
  void initState() {
    super.initState();
    _acct = TextEditingController(text: MockSession.bankAccount);
    _confirm = TextEditingController(text: MockSession.bankAccount);
    _ifsc = TextEditingController(text: MockSession.bankIfsc);
    _upi = TextEditingController(text: MockSession.upiId);
    if (MockSession.bankIfsc.trim().isNotEmpty && MockSession.bankName.trim().isNotEmpty) {
      _bank = MockSession.bankName;
    }
    if (MockSession.bankIfsc.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onIfscChanged(MockSession.bankIfsc);
      });
    }
    _upiMode = MockSession.bankAccount.trim().isEmpty && MockSession.upiId.trim().isNotEmpty;
    _editing = !MockSession.payoutDone ||
        (MockSession.bankAccount.trim().isEmpty && MockSession.upiId.trim().isEmpty);
  }

  @override
  void dispose() {
    _acct.dispose();
    _confirm.dispose();
    _ifsc.dispose();
    _upi.dispose();
    super.dispose();
  }

  Future<void> _onIfscChanged(String raw) async {
    final ifsc = raw.trim().toUpperCase().replaceAll(' ', '');
    if (_ifsc.text.trim().toUpperCase().replaceAll(' ', '') != ifsc) {
      _ifsc.value = TextEditingValue(
        text: ifsc,
        selection: TextSelection.collapsed(offset: ifsc.length),
      );
    }
    setState(() => _ifscErr = null);
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
      setState(() {
        _bank = null;
        _branch = null;
      });
      return;
    }
    setState(() => _lookingIfsc = true);
    try {
      final hit = await ProfileApi.instance.lookupIfsc(
        authToken: MockSession.authToken,
        ifsc: ifsc,
      );
      if (!mounted || _ifsc.text.trim().toUpperCase().replaceAll(' ', '') != ifsc) return;
      setState(() {
        _lookingIfsc = false;
        _bank = hit.bank;
        _branch = hit.branch;
      });
    } on AuthApiException catch (e) {
      if (!mounted || _ifsc.text.trim().toUpperCase().replaceAll(' ', '') != ifsc) return;
      setState(() {
        _lookingIfsc = false;
        _ifscErr = e.message;
        _keepSavedBrand(ifsc);
      });
    } catch (_) {
      if (!mounted || _ifsc.text.trim().toUpperCase().replaceAll(' ', '') != ifsc) return;
      setState(() {
        _lookingIfsc = false;
        _ifscErr = S.e('Couldn’t find this IFSC. Check and try again.');
        _keepSavedBrand(ifsc);
      });
    }
  }

  void _keepSavedBrand(String ifsc) {
    final savedIfsc = MockSession.bankIfsc.trim().toUpperCase();
    final savedBank = MockSession.bankName.trim();
    if (ifsc == savedIfsc && savedBank.isNotEmpty) {
      _bank = savedBank;
      return;
    }
    _bank = null;
    _branch = null;
  }

  void _validateAcctLive(String raw) {
    final acct = raw.replaceAll(' ', '');
    final confirm = _confirm.text.replaceAll(' ', '');
    setState(() {
      if (acct.isEmpty) {
        _acctErr = null;
      } else if (!RegExp(r'^\d+$').hasMatch(acct)) {
        _acctErr = S.e('Account number must be digits only');
      } else if (acct.length < 9) {
        // l10n-missing
        _acctErr = 'Enter a valid account number';
      } else if (acct.length > 18) {
        // l10n-missing
        _acctErr = 'Account number looks too long';
      } else {
        _acctErr = null;
      }
      if (confirm.isNotEmpty) {
        _confirmErr = confirm != acct ? S.e('Account numbers don’t match') : null;
      }
    });
  }

  void _validateConfirmLive(String raw) {
    final acct = _acct.text.replaceAll(' ', '');
    final confirm = raw.replaceAll(' ', '');
    setState(() {
      if (confirm.isEmpty) {
        _confirmErr = null;
      } else if (confirm != acct) {
        _confirmErr = S.e('Account numbers don’t match');
      } else {
        _confirmErr = null;
      }
    });
  }

  void _validateUpiLive(String raw) {
    final upi = raw.trim();
    setState(() {
      if (upi.isEmpty) {
        _upiErr = null;
      } else if (!RegExp(r'^[a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,}$').hasMatch(upi)) {
        _upiErr = S.e('Enter a valid UPI ID');
      } else {
        _upiErr = null;
      }
    });
  }

  bool _runFullValidation() {
    if (_upiMode) {
      final upi = _upi.text.trim();
      String? upiErr;
      if (upi.isEmpty || !RegExp(r'^[a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,}$').hasMatch(upi)) {
        upiErr = S.e('Enter a valid UPI ID');
      }
      setState(() => _upiErr = upiErr);
      return upiErr == null;
    }

    final acct = _acct.text.replaceAll(' ', '');
    final confirm = _confirm.text.replaceAll(' ', '');
    final ifsc = _ifsc.text.trim().toUpperCase().replaceAll(' ', '');

    String? acctErr;
    if (acct.isEmpty) {
      acctErr = S.e('Enter account number');
    } else if (!RegExp(r'^\d{9,18}$').hasMatch(acct)) {
      // l10n-missing
      acctErr = 'Enter a valid account number';
    }

    String? confirmErr;
    if (confirm.isEmpty) {
      confirmErr = S.e('Re-enter account number');
    } else if (confirm != acct) {
      confirmErr = S.e('Account numbers don’t match');
    }

    String? ifscErr;
    if (ifsc.isEmpty) {
      ifscErr = S.e('Enter IFSC code');
    } else if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
      // l10n-missing
      ifscErr = 'Enter a valid IFSC code';
    } else if (_bank == null) {
      // l10n-missing
      ifscErr = 'Enter a valid IFSC to find your bank';
    }

    setState(() {
      _acctErr = acctErr;
      _confirmErr = confirmErr;
      _ifscErr = ifscErr;
      _upiErr = null;
    });

    return acctErr == null && confirmErr == null && ifscErr == null && _bank != null;
  }

  Future<void> _save() async {
    if (_lookingIfsc || _saving) return;
    if (MockSession.panName.trim().isEmpty) {
      await _openVerifyPan();
      return;
    }
    if (!_runFullValidation()) return;

    final acct = _upiMode ? '' : _acct.text.replaceAll(' ', '');
    final ifsc = _upiMode ? '' : _ifsc.text.trim().toUpperCase().replaceAll(' ', '');
    final upi = _upiMode ? _upi.text.trim() : '';
    final bank = _upiMode ? '' : _bank!;
    final holder = MockSession.panName.trim().isNotEmpty
        ? personName(MockSession.panName.trim())
        : MockSession.displayName.trim();

    setState(() => _saving = true);
    try {
      if (MockSession.authToken.isNotEmpty) {
        if (holder.isEmpty) {
          if (mounted) {
            await _openVerifyPan();
          }
          return;
        }
        await ProfileApi.instance.updateBankDetail(
          authToken: MockSession.authToken,
          fullName: holder,
          bankName: bank,
          accountNumber: acct,
          ifsc: ifsc,
          upi: upi,
          payoutMethod: _upiMode ? 'upi' : 'bank',
        );
      } else {
        MockSession.savePayout(
          bankName: bank,
          account: acct,
          ifsc: ifsc,
          upi: upi,
        );
      }
      if (!mounted) return;
      setState(() => _editing = false);
      if (widget.onSaved != null) {
        widget.onSaved!();
        return;
      }
      if (widget.asSheet) {
        Navigator.pop(context, true);
      } else {
        showMintzerToast(context, S.e('Payout account updated'), kind: MintzerToastKind.success);
      }
    } on AuthApiException catch (e) {
      if (mounted) {
        showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
      }
    } catch (_) {
      if (mounted) {
        showMintzerToast(
          context,
          // l10n-missing
          'Couldn’t save payout account. Try again.',
          kind: MintzerToastKind.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openVerifyPan() async {
    final ok = await showKycSheet(context);
    if (ok && mounted) setState(() {});
  }

  Widget _methodChip({required String label, required bool selected, required VoidCallback onTap}) {
    return Material(
      color: selected ? const Color(0xFFF3F0FF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? MintzerColors.primary : const Color(0xFFE8EAED), width: selected ? 1.4 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: selected ? MintzerColors.primary : const Color(0xFF202124),
            ),
          ),
        ),
      ),
    );
  }

  bool get _looksReady {
    if (_upiMode) {
      return RegExp(r'^[a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,}$').hasMatch(_upi.text.trim());
    }
    final acct = _acct.text.replaceAll(' ', '');
    final confirm = _confirm.text.replaceAll(' ', '');
    final ifsc = _ifsc.text.trim().toUpperCase().replaceAll(' ', '');
    return RegExp(r'^\d{9,18}$').hasMatch(acct) &&
        confirm == acct &&
        _bank != null &&
        RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc) &&
        !_lookingIfsc;
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final name = MockSession.panName.isEmpty ? S.e('Complete KYC first') : personName(MockSession.panName);

    final savedUpiOnly = MockSession.bankAccount.trim().isEmpty && MockSession.upiId.trim().isNotEmpty;
    if (!_editing && MockSession.payoutDone && (MockSession.bankAccount.trim().isNotEmpty || savedUpiOnly)) {
      final acct = MockSession.bankAccount.trim();
      final last4 = acct.length >= 4 ? acct.substring(acct.length - 4) : acct;
      final bank = MockSession.bankName.trim().isNotEmpty
          ? MockSession.bankName.trim()
          : (_bank ?? S.e('Bank'));
      final ifsc = MockSession.bankIfsc.trim().toUpperCase();
      final upi = MockSession.upiId.trim();
      final summary = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.asSheet) ...[
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFDADCE0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                 Expanded(
                  child: Text(S.e('Payout account'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF5F6368)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCEEAD6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: Color(0xFF188038)),
                    const SizedBox(width: 6),
                     Expanded(
                      child: Text(S.e('Saved for Mintzer payouts'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF188038))),
                    ),
                    TextButton(
                      onPressed: () {
                        _acct.text = MockSession.bankAccount;
                        _confirm.text = MockSession.bankAccount;
                        _ifsc.text = MockSession.bankIfsc.trim().toUpperCase();
                        _upi.text = MockSession.upiId;
                        final savedIfsc = MockSession.bankIfsc.trim().toUpperCase();
                        _bank = savedIfsc.isEmpty ? null : (MockSession.bankName.trim().isEmpty ? null : MockSession.bankName.trim());
                        setState(() {
                          _editing = true;
                          _upiMode = savedUpiOnly;
                        });
                        if (_ifsc.text.trim().isNotEmpty) {
                          _onIfscChanged(_ifsc.text);
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: MintzerColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      child: Text(S.e('Change')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (savedUpiOnly) ...[
                  Text(S.e('UPI'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5F6368))),
                  const SizedBox(height: 4),
                  Text(upi, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                ] else ...[
                  Row(
                    children: [
                      _BankMark(name: bank),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(bank, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('••••••••$last4', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                  if (ifsc.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('${S.t('ifsc')}  $ifsc', style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 8),
                  Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // l10n-missing
          const Text(
            'Payouts go to this account within 48 working hours after invoice approval (bank holidays don’t count).',
            style: TextStyle(fontSize: 12, color: Color(0xFF9AA0A6), height: 1.35),
          ),
        ],
      );
      if (!widget.asSheet) return summary;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: SingleChildScrollView(child: summary),
      );
    }

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.asSheet) ...[
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFDADCE0), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
               Expanded(
                child: Text(S.e('Payout account'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF5F6368)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (widget.showStep)
             Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(S.e('Step 2 of 2'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MintzerColors.primary)),
            ),
        ],
        Text(
          _upiMode
              // l10n-missing
              ? 'Your Mintzer earnings will be sent to this UPI ID.'
              // l10n-missing
              : 'Your Mintzer earnings will be sent to this bank account.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368), height: 1.35),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _methodChip(label: S.e('Bank account'), selected: !_upiMode, onTap: () => setState(() => _upiMode = false))),
            const SizedBox(width: 8),
            Expanded(child: _methodChip(label: S.e('UPI'), selected: _upiMode, onTap: () => setState(() => _upiMode = true))),
          ],
        ),
        const SizedBox(height: 14),
        // Locked PAN name
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.e('Account holder name'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: MockSession.panName.isEmpty ? _openVerifyPan : null,
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: MockSession.panName.isEmpty ? MintzerColors.primary : const Color(0xFF202124),
                        ),
                      ),
                    ),
                  ),
                  if (MockSession.panName.isEmpty)
                    TextButton(
                      onPressed: _openVerifyPan,
                      style: TextButton.styleFrom(
                        foregroundColor: MintzerColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      child: Text(S.e('Verify PAN')),
                    )
                  else ...[
                    const Icon(Icons.check_circle, size: 18, color: Color(0xFF188038)),
                    const SizedBox(width: 4),
                    // l10n-missing
                    const Text('Verified with PAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF188038))),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                MockSession.panName.isEmpty
                    ? S.e('Payout name comes from your PAN. Tap Verify PAN.')
                    // l10n-missing
                    : 'Name must match your PAN. You cannot edit this.',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_upiMode) ...[
          Text(S.e('UPI ID'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
          const SizedBox(height: 6),
          TextField(
            controller: _upi,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF202124)),
            decoration: softInputDecoration(
              hint: S.e('name@upi'),
              errorText: _upiErr,
            ),
            onChanged: _validateUpiLive,
          ),
        ] else ...[
        Text(S.t('acct_no'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
        const SizedBox(height: 6),
        TextField(
          controller: _acct,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF202124)),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(18),
          ],
          decoration: softInputDecoration(
            hint: S.e('Enter account number'),
            errorText: _acctErr,
          ),
          onChanged: _validateAcctLive,
        ),
        const SizedBox(height: 12),
        // l10n-missing
        const Text('Confirm account number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
        const SizedBox(height: 6),
        TextField(
          controller: _confirm,
          keyboardType: TextInputType.number,
          obscureText: true,
          obscuringCharacter: '•',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF202124)),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(18),
          ],
          decoration: softInputDecoration(
            hint: S.e('Re-enter account number'),
            errorText: _confirmErr,
          ),
          onChanged: _validateConfirmLive,
        ),
        const SizedBox(height: 12),
        // l10n-missing
        const Text('IFSC code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
        const SizedBox(height: 6),
        TextField(
          controller: _ifsc,
          textCapitalization: TextCapitalization.characters,
          maxLength: 11,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.4, color: Color(0xFF202124)),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            _UpperCaseFormatter(),
          ],
          decoration: softInputDecoration(
            hint: S.e('e.g. HDFC0001234'),
            errorText: _ifscErr,
          ).copyWith(counterText: ''),
          onChanged: _onIfscChanged,
        ),
        if (_lookingIfsc) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(color: MintzerColors.primary, minHeight: 3),
        ],
        if (_bank != null && RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(_ifsc.text.trim().toUpperCase())) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCEEAD6)),
            ),
            child: Row(
              children: [
                _BankMark(name: _bank!),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_bank!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      if (_branch != null)
                        Text(_branch!, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                    ],
                  ),
                ),
                 Column(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Color(0xFF188038)),
                    SizedBox(height: 2),
                    Text(S.e('Bank found'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF188038))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
           Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 14, color: Color(0xFF9AA0A6)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  S.e('We match IFSC to your bank so payouts reach the right account.'),
                  style: TextStyle(fontSize: 11, color: Color(0xFF9AA0A6), height: 1.35),
                ),
              ),
            ],
          ),
        ],
        ],
        const SizedBox(height: 18),
        FilledButton(
          // Always tappable so mismatch / empty errors surface (not only when “ready”)
          onPressed: (_lookingIfsc || _saving) ? null : _save,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            backgroundColor: _looksReady ? MintzerColors.primary : const Color(0xFF9B87FF),
            disabledBackgroundColor: const Color(0xFFE8EAED),
            disabledForegroundColor: const Color(0xFF9AA0A6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                )
              : Text(
                  _editing && MockSession.payoutDone ? S.e('Update payout account') : 'Save payout account',
                ),
        ),
        const SizedBox(height: 10),
         Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 13, color: Color(0xFF9AA0A6)),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                S.e('Used only for Mintzer payouts'),
                style: TextStyle(fontSize: 11, color: Color(0xFF9AA0A6)),
              ),
            ),
          ],
        ),
      ],
    );

    if (!widget.asSheet) return body;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SingleChildScrollView(child: body),
    );
  }
}

class _BankMark extends StatelessWidget {
  const _BankMark({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'B';
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(letter, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: MintzerColors.primary)),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text.toUpperCase();
    return TextEditingValue(text: t, selection: newValue.selection);
  }
}
