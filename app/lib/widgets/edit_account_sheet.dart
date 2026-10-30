import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/s.dart';
import '../api/auth_api.dart';
import '../api/profile_api.dart';
import '../mock/session.dart';
import '../mock/session_store.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import 'mintzer_toast.dart';

/// Edit account details — photo · name rules · change phone (live OTP when signed in).
Future<void> showEditAccountSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) {
      S.watch(ctx);
      return const _EditAccountBody();
    },
  );
}

class _EditAccountBody extends StatefulWidget {
  const _EditAccountBody();

  @override
  State<_EditAccountBody> createState() => _EditAccountBodyState();
}

class _EditAccountBodyState extends State<_EditAccountBody> {
  late final TextEditingController _name;
  late bool _useLetter;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _useLetter = MockSession.useLetterAvatar;
    final initial = MockSession.panName.isNotEmpty
        ? personName(MockSession.panName)
        : (MockSession.displayName.isNotEmpty ? personName(MockSession.displayName) : MockSession.profileDisplayName);
    _name = TextEditingController(text: initial == 'there' ? '' : initial);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _nameLocked => MockSession.kycDone && MockSession.panName.isNotEmpty;
  bool get _live => MockSession.authToken.isNotEmpty;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!_nameLocked) {
        final n = _name.text.trim();
        if (_live && n.isNotEmpty) {
          await ProfileApi.instance.updateDisplayName(
            authToken: MockSession.authToken,
            name: n,
          );
        } else {
          MockSession.displayName = n;
        }
      }
      MockSession.useLetterAvatar = _useLetter;
      await SessionStore.save();
      if (!mounted) return;
      Navigator.pop(context);
      showMintzerToastOn(
        messenger,
        S.e('Account details saved'),
        kind: MintzerToastKind.success,
        icon: Icons.check_circle_rounded,
      );
    } on AuthApiException catch (e) {
      if (mounted) showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
    } catch (_) {
      if (mounted) {
        // l10n-missing
        showMintzerToast(context, 'Couldn’t save. Try again.', kind: MintzerToastKind.danger);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    if (_live) {
      try {
        await ProfileApi.instance.updateProfileImage(
          authToken: MockSession.authToken,
          file: File(file.path),
        );
        MockSession.useLetterAvatar = false;
        await SessionStore.save();
        if (mounted) setState(() => _useLetter = false);
        if (mounted) {
          showMintzerToast(context, S.t('photo_updated'), kind: MintzerToastKind.success);
        }
      } on AuthApiException catch (e) {
        if (mounted) showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
      } catch (_) {
        if (mounted) {
          showMintzerToast(context, S.e('Couldn’t upload photo'), kind: MintzerToastKind.danger);
        }
      }
    } else {
      setState(() => _useLetter = false);
    }
  }

  Future<void> _changePhone() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (c) {
        S.watch(c);
        return const _ChangePhoneBody();
      },
    );
    if (ok == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final letter = MockSession.profileDisplayName.isEmpty
        ? '?'
        : MockSession.profileDisplayName[0].toUpperCase();
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
            Text(S.e('Account details'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFEDE7FF),
                    backgroundImage: (!_useLetter && MockSession.profilePictureUrl.trim().isNotEmpty)
                        ? NetworkImage(MockSession.profilePictureUrl.trim())
                        : null,
                    child: (_useLetter || MockSession.profilePictureUrl.trim().isEmpty)
                        ? Text(letter, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: MintzerColors.primary))
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: MintzerColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _pickPhoto,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              enabled: !_nameLocked,
              decoration: InputDecoration(
                labelText: S.t('addr_name'),
                helperText: _nameLocked ? S.e('Locked to your verified PAN name') : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(MockSession.phoneDisplay, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: _changePhone,
                    child: Text(S.e('Change'), style: TextStyle(fontWeight: FontWeight.w700, color: MintzerColors.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              // l10n-missing
              _live
                  ? 'We’ll send an OTP to the new number to confirm the change.'
                  : S.e('Sign in to change your phone number.'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6), height: 1.35),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(S.t('save')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePhoneBody extends StatefulWidget {
  const _ChangePhoneBody();

  @override
  State<_ChangePhoneBody> createState() => _ChangePhoneBodyState();
}

class _ChangePhoneBodyState extends State<_ChangePhoneBody> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  var _step = 0;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final d = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (d.length != 10) {
      showMintzerToast(context, S.t('login_phone_err'), kind: MintzerToastKind.warn);
      return;
    }
    if (d == MockSession.phoneDigits) {
      showMintzerToast(context, S.e('That’s already your number'), kind: MintzerToastKind.warn);
      return;
    }
    if (MockSession.authToken.isEmpty) {
      // l10n-missing
      showMintzerToast(context, 'Sign in to change phone', kind: MintzerToastKind.warn);
      return;
    }
    setState(() => _busy = true);
    try {
      await ProfileApi.instance.changePhoneSendOtp(
        authToken: MockSession.authToken,
        mobile: d,
      );
      if (!mounted) return;
      setState(() {
        _step = 1;
        _busy = false;
      });
      showMintzerToast(context, S.e('OTP sent'), kind: MintzerToastKind.info);
    } on AuthApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        // l10n-missing
        showMintzerToast(context, 'Couldn’t send OTP. Try again.', kind: MintzerToastKind.danger);
      }
    }
  }

  Future<void> _verify() async {
    final d = _phone.text.replaceAll(RegExp(r'\D'), '');
    final otp = _otp.text.trim();
    if (otp.length < 4) {
      showMintzerToast(context, S.e('Enter the OTP'), kind: MintzerToastKind.warn);
      return;
    }
    setState(() => _busy = true);
    try {
      await ProfileApi.instance.changePhoneVerify(
        authToken: MockSession.authToken,
        mobile: d,
        otp: otp,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      // l10n-missing
      showMintzerToastOn(messenger, 'Phone updated', kind: MintzerToastKind.success);
    } on AuthApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showMintzerToast(context, S.e('Couldn’t verify OTP. Try again.'), kind: MintzerToastKind.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(S.e('Change phone'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (_step == 0) ...[
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration:  InputDecoration(
                labelText: S.e('New number'),
                prefixText: '+91 ',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _sendOtp,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(S.e('Send OTP')),
            ),
          ] else ...[
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                // l10n-missing
                labelText: 'OTP',
                border: const OutlineInputBorder(),
                counterText: '',
                // l10n-missing
                helperText: 'Sent to +91 ${_phone.text}',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _verify,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(S.e('Verify & update')),
            ),
          ],
        ],
      ),
    );
  }
}
