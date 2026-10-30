import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/s.dart';
import '../api/auth_api.dart';
import '../api/profile_api.dart';
import '../config/app_config.dart';
import '../live/must_test_shapes.dart';
import '../mock/session.dart';
import '../mock/session_store.dart';
import '../push/push_bootstrap.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/contact_us_sheet.dart';
import '../widgets/edit_account_sheet.dart';
import '../widgets/kyc_sheet.dart';
import '../widgets/lang_rail.dart';
import '../widgets/mintzer_toast.dart';
import '../util/external_links.dart';
import '../util/notification_permission.dart';
import '../util/play_in_app_review.dart';
import 'faq_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'payout_details_screen.dart';
import 'tickets_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

/// Profile — tight hierarchy (critique 20 Sep 2026): less chrome, full-width rows, quiet colors.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  bool _loading = false;

  String get _code {
    final c = MockSession.referralCode.trim();
    if (c.isNotEmpty) return c;
    final d = MockSession.phoneDigits.replaceAll(RegExp(r'\D'), '');
    if (d.length >= 4) return 'MZ${d.substring(d.length - 4)}';
    return '';
  }
  int _lastTab = -1;

  String get _name {
    final n = MockSession.profileDisplayName;
    if (n.isNotEmpty) return n;
    return MockSession.displayName.trim().isNotEmpty
        ? MockSession.displayName.trim()
        : S.e('Mintzer member');
  }
  String get _phone => MockSession.phoneDisplay;
  String get _letter => _name.isEmpty || _name == 'Mintzer member' ? 'M' : _name[0].toUpperCase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MockSession.tabIndex.addListener(_onShellTab);
    _loadLive();
  }

  void _onShellTab() {
    if (MockSession.tabIndex.value == 3 && _lastTab != 3) {
      // ignore: unawaited_futures
      _loadLive();
    }
    _lastTab = MockSession.tabIndex.value;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && MockSession.tabIndex.value == 3) {
      // ignore: unawaited_futures
      _loadLive();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MockSession.tabIndex.removeListener(_onShellTab);
    super.dispose();
  }

  Future<void> _loadLive() async {
    if (MockSession.authToken.isEmpty) return;
    if (_loading) return;
    setState(() => _loading = true);
    await ProfileApi.instance.refreshProfileIntoSession(authToken: MockSession.authToken);
    await ProfileApi.instance.refreshBankIntoSession(authToken: MockSession.authToken);
    await ProfileApi.instance.refreshReferralIntoSession(authToken: MockSession.authToken);
    if (mounted) setState(() => _loading = false);
  }

  Widget _avatarFace() {
    final url = MockSession.profilePictureUrl.trim();
    if (!MockSession.useLetterAvatar && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Text(
            _letter,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MintzerColors.primary),
          ),
        ),
      );
    }
    if (MockSession.useLetterAvatar) {
      return Text(_letter, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MintzerColors.primary));
    }
    return const Icon(Icons.person_rounded, size: 28, color: MintzerColors.primary);
  }

  Future<void> _showKycVerifiedSheet() async {
    final name = MockSession.panName.trim().isNotEmpty
        ? personName(MockSession.panName.trim())
        : MockSession.profileDisplayName;
    final pan = MockSession.panNumber.trim();
    final masked = pan.length >= 4
        ? '${pan.substring(0, 2).toUpperCase()}****${pan.substring(pan.length - 4).toUpperCase()}'
        : (pan.isEmpty ? S.t('kyc_ok') : pan.toUpperCase());

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (c) {
        S.watch(c);
        return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFE6F4EA), shape: BoxShape.circle),
                    child: const Icon(Icons.verified_rounded, color: Color(0xFF188038), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(S.e('KYC verified'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8EAED)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.t('name_on_pan'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
                    const SizedBox(height: 4),
                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text(S.t('help_acct_1'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
                    const SizedBox(height: 4),
                    Text(masked, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                S.e('Name is locked to your PAN. Payouts use this identity.'),
                style: TextStyle(fontSize: 12, color: Color(0xFF9AA0A6), height: 1.35),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(c),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  backgroundColor: MintzerColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(S.e('Done')),
              ),
            ],
          ),
        ),
      );
      },
    );
  }

  void _photoSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (c) {
        S.watch(c);
        return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(S.t('photo_title'), style: const TextStyle(fontWeight: FontWeight.w800))),
            ListTile(
              leading: const Icon(Icons.photo_outlined, color: MintzerColors.primary),
              title: Text(S.t('photo_use')),
              onTap: () async {
                Navigator.pop(c);
                final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
                if (!mounted || file == null) return;
                if (MockSession.authToken.isNotEmpty) {
                  try {
                    await ProfileApi.instance.updateProfileImage(
                      authToken: MockSession.authToken,
                      file: File(file.path),
                    );
                    if (!mounted) return;
                    setState(() {});
                    showMintzerToast(context, S.t('photo_updated'), kind: MintzerToastKind.success, icon: Icons.photo_outlined);
                  } on AuthApiException catch (e) {
                    if (!mounted) return;
                    showMintzerToast(context, e.message, kind: MintzerToastKind.warn);
                  } catch (_) {
                    if (!mounted) return;
                    showMintzerToast(context, S.e('Couldn’t upload photo'), kind: MintzerToastKind.warn);
                  }
                } else {
                  MockSession.useLetterAvatar = false;
                  setState(() {});
                  showMintzerToast(context, S.t('photo_updated'), kind: MintzerToastKind.info, icon: Icons.photo_outlined);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: MintzerColors.primary),
              title: Text(S.t('photo_remove')),
              onTap: () async {
                MockSession.useLetterAvatar = true;
                await SessionStore.save();
                if (!mounted) return;
                Navigator.pop(c);
                setState(() {});
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
      },
    );
  }
  Future<void> _editAccount() async {
    await showEditAccountSheet(context);
    if (mounted) setState(() {});
  }

  void _openNotificationPrefs() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (c) {
        S.watch(c);
        return StatefulBuilder(
          builder: (context, setModal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(title: Text(S.t('notifications'), style: const TextStyle(fontWeight: FontWeight.w800))),
                    SwitchListTile(
                      title: Text(S.e('Push notifications')),
                      // l10n-missing
                      subtitle: const Text('Master switch'),
                      value: MockSession.pushMaster,
                      activeThumbColor: MintzerColors.primary,
                      onChanged: (v) async {
                        if (v) {
                          final ok = await NotificationPermission.enableFromProfile(context);
                          if (!context.mounted) return;
                          setModal(() {
                            MockSession.pushMaster = ok;
                            setState(() {});
                          });
                          await SessionStore.save();
                          if (MockSession.authToken.isNotEmpty) {
                            try {
                              await AuthApi.instance.saveV3PushPrefs(
                                authToken: MockSession.authToken,
                                master: MockSession.pushMaster,
                                deals: MockSession.pushDeals,
                                orders: MockSession.pushOrders,
                                payments: MockSession.pushPayments,
                              );
                            } catch (_) {}
                          }
                          if (!ok) {
                            showMintzerToast(
                              context,
                              S.e('Notifications still off in system settings'),
                              kind: MintzerToastKind.warn,
                            );
                          }
                        } else {
                          setModal(() {
                            MockSession.pushMaster = false;
                            setState(() {});
                          });
                          await SessionStore.save();
                          if (MockSession.authToken.isNotEmpty) {
                            try {
                              await AuthApi.instance.saveV3PushPrefs(
                                authToken: MockSession.authToken,
                                master: false,
                                deals: MockSession.pushDeals,
                                orders: MockSession.pushOrders,
                                payments: MockSession.pushPayments,
                              );
                            } catch (_) {}
                          }
                        }
                      },
                    ),
                    SwitchListTile(
                      title: Text(S.e('Deal alerts')),
                      value: MockSession.pushMaster && MockSession.pushDeals,
                      activeThumbColor: MintzerColors.primary,
                      onChanged: !MockSession.pushMaster
                          ? null
                          : (v) async {
                                setModal(() {
                                  MockSession.pushDeals = v;
                                  setState(() {});
                                });
                                await SessionStore.save();
                                if (MockSession.authToken.isNotEmpty) {
                                  try {
                                    await AuthApi.instance.saveV3PushPrefs(
                                      authToken: MockSession.authToken,
                                      master: MockSession.pushMaster,
                                      deals: MockSession.pushDeals,
                                      orders: MockSession.pushOrders,
                                      payments: MockSession.pushPayments,
                                    );
                                  } catch (_) {}
                                }
                              },
                    ),
                    SwitchListTile(
                      title: Text(S.e('Order updates')),
                      value: MockSession.pushMaster && MockSession.pushOrders,
                      activeThumbColor: MintzerColors.primary,
                      onChanged: !MockSession.pushMaster
                          ? null
                          : (v) async {
                                setModal(() {
                                  MockSession.pushOrders = v;
                                  setState(() {});
                                });
                                await SessionStore.save();
                                if (MockSession.authToken.isNotEmpty) {
                                  try {
                                    await AuthApi.instance.saveV3PushPrefs(
                                      authToken: MockSession.authToken,
                                      master: MockSession.pushMaster,
                                      deals: MockSession.pushDeals,
                                      orders: MockSession.pushOrders,
                                      payments: MockSession.pushPayments,
                                    );
                                  } catch (_) {}
                                }
                              },
                    ),
                    SwitchListTile(
                      title: Text(S.e('Payment & wallet')),
                      value: MockSession.pushMaster && MockSession.pushPayments,
                      activeThumbColor: MintzerColors.primary,
                      onChanged: !MockSession.pushMaster
                          ? null
                          : (v) async {
                                setModal(() {
                                  MockSession.pushPayments = v;
                                  setState(() {});
                                });
                                await SessionStore.save();
                                if (MockSession.authToken.isNotEmpty) {
                                  try {
                                    await AuthApi.instance.saveV3PushPrefs(
                                      authToken: MockSession.authToken,
                                      master: MockSession.pushMaster,
                                      deals: MockSession.pushDeals,
                                      orders: MockSession.pushOrders,
                                      payments: MockSession.pushPayments,
                                    );
                                  } catch (_) {}
                                }
                              },
                    ),
                    ListTile(
                      title: Text(S.e('Notification inbox')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(c);
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NotificationsScreen())).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                    ),
                    if (kDebugMode)
                      ListTile(
                        title: Text(S.e('Copy FCM token (debug)')),
                        subtitle: Text(
                          () {
                            final t = PushBootstrap.lastToken;
                            // l10n-missing
                            if (t == null || t.isEmpty) return 'No token yet';
                            if (t.length <= 24) return t;
                            return '${t.substring(0, 24)}…';
                          }(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () async {
                          final t = await PushBootstrap.readStoredToken();
                          if (t == null || !context.mounted) return;
                          await Clipboard.setData(ClipboardData(text: t));
                          if (!context.mounted) return;
                          showMintzerToast(context, S.e('FCM token copied'), kind: MintzerToastKind.success);
                        },
                      ),
                    if (kDebugMode)
                      ListTile(
                        // l10n-missing
                        title: const Text('Load must-test orders (debug)'),
                        // l10n-missing
                        subtitle: const Text('Tracking · Invoice · Paid from Hostinger export'),
                        onTap: () async {
                          Navigator.pop(c);
                          final n = await MustTestShapes.loadIntoSession();
                          if (!context.mounted) return;
                          MockSession.tabIndex.value = 1;
                          showMintzerToast(
                            context,
                            n > 0
                                // l10n-missing
                                ? 'Loaded $n must-test orders → Orders tab'
                                // l10n-missing
                                : 'Could not load must-test shapes',
                            kind: n > 0 ? MintzerToastKind.success : MintzerToastKind.warn,
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final kycPending = !MockSession.kycDone;
    final payoutPending = !MockSession.payoutDone;
    final unread = MockSession.notifications.value.where((n) => n.unread).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Text(S.t('profile'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _photoSheet,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFEDE7FF),
                        child: _avatarFace(),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(color: MintzerColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: MockSession.phoneDigits));
                          if (!context.mounted) return;
                          MintzerToasts.copied(context, S.e('Phone copied'));
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_phone, style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF9AA0A6)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _editAccount,
                  style: TextButton.styleFrom(
                    foregroundColor: MintzerColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  child: Text(S.e('Edit')),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _ReferStrip(
              code: _code,
              onCopy: () async {
                if (_code.isEmpty) {
                  // l10n-missing
                  showMintzerToast(context, 'Invite code not ready yet', kind: MintzerToastKind.warn);
                  return;
                }
                await Clipboard.setData(ClipboardData(text: _code));
                if (!context.mounted) return;
                MintzerToasts.copied(context, S.e('Invite code copied'));
              },
              onShare: () {
                if (_code.isEmpty) {
                  // l10n-missing
                  showMintzerToast(context, 'Invite code not ready yet', kind: MintzerToastKind.warn);
                  return;
                }
                SharePlus.instance.share(
                  ShareParams(
                    // l10n-missing
                    text:
                        'Join Mintzer with my code $_code — earn on Flipkart & Amazon card deals. https://play.google.com/store/apps/details?id=com.mintzer',
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            _Section(
              title: S.t('account'),
              children: [
                _NavRow(
                  title: S.e('Account details'),
                  trailing: Text(S.e('Edit'), style: TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                  onTap: _editAccount,
                ),
                _NavRow(
                  title: S.t('kyc'),
                  trailing: Text(
                    kycPending ? S.t('kyc_pending') : S.t('kyc_ok'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kycPending ? const Color(0xFFE37400) : const Color(0xFF188038),
                    ),
                  ),
                  onTap: () async {
                    if (MockSession.kycDone) {
                      await _showKycVerifiedSheet();
                      return;
                    }
                    final ok = await showKycSheet(context);
                    if (mounted && ok) setState(() {});
                  },
                ),
                _NavRow(
                  title: S.t('payout_details'),
                  trailing: Text(
                    payoutPending ? S.e('Not set up') : S.t('snack_saved'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: payoutPending ? const Color(0xFF5F6368) : const Color(0xFF188038),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PayoutDetailsScreen())).then((_) {
                      if (mounted) setState(() {});
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            _Section(
              title: S.e('Preferences'),
              children: [
                _NavRow(
                  title: S.t('apply_cards'),
                  // l10n-missing
                  trailing: const Text('Partner', style: TextStyle(fontSize: 12, color: Color(0xFF9AA0A6))),
                  onTap: () => openPartnerCards(context),
                ),
                _NavRow(
                  title: S.t('language'),
                  trailing: Text(MockSession.languageLabel, style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
                  onTap: _openLanguage,
                ),
                _NavRow(
                  title: S.t('appearance'),
                  trailing: Text(_themeTrail(), style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
                  onTap: _openAppearance,
                ),
                _NavRow(
                  title: S.t('notifications'),
                  trailing: unread > 0
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: MintzerColors.primary, shape: BoxShape.circle),
                        )
                      : Text(
                          MockSession.pushMaster ? S.e('On') : 'Off',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9AA0A6)),
                        ),
                  onTap: _openNotificationPrefs,
                ),
              ],
            ),
            const SizedBox(height: 12),

            _Section(
              // l10n-missing
              title: 'Help & Support',
              children: [
                _NavRow(
                  title: S.e('Help Center'),
                  trailing: Text(S.t('faq'), style: const TextStyle(fontSize: 12, color: Color(0xFF9AA0A6))),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FaqScreen()));
                  },
                ),
                _NavRow(
                  title: S.t('my_tickets'),
                  trailing: Text(
                    _ticketsTrail(),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TicketsScreen())).then((_) {
                      if (mounted) setState(() {});
                    });
                  },
                ),
                _NavRow(
                  title: S.t('contact'),
                  trailing: const Text(
                    'WhatsApp',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF128C7E)),
                  ),
                  onTap: () => showContactUsSheet(context),
                ),
                _NavRow(
                  title: S.e('Video tutorials'),
                  // l10n-missing
                  trailing: const Text('YouTube', style: TextStyle(fontSize: 12, color: Color(0xFF9AA0A6))),
                  onTap: () {
                    openTutorials(context);
                  },
                ),
                _NavRow(
                  // l10n-missing
                  title: 'Rate Mintzer',
                  trailing: Text(S.e('Play'), style: TextStyle(fontSize: 12, color: Color(0xFF9AA0A6))),
                  onTap: () => PlayInAppReview.openPlayListing(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _Section(
              // l10n-missing
              title: 'Legal',
              children: [
                // l10n-missing
                _NavRow(title: 'Terms of Service', onTap: () => openTerms(context)),
                _NavRow(title: S.e('Privacy Policy'), onTap: () => openPrivacy(context)),
              ],
            ),
            const SizedBox(height: 16),

            TextButton(
              onPressed: _logout,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5F6368),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: Text(S.t('logout')),
            ),
            TextButton(
              onPressed: _deleteAccount,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD93025),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              child: Text(S.t('delete_account')),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Mintzer · v${AppConfig.versionLabel}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ticketsTrail() {
    final open = MockSession.tickets.value.where((t) => t.status.isOpen).length;
    if (open == 0) return S.t('none');
    // l10n-missing
    return '$open open';
  }

  String _themeTrail() {
    switch (MockSession.themeMode.value) {
      case ThemeMode.dark:
        return S.t('dark');
      case ThemeMode.system:
        return S.e('System');
      case ThemeMode.light:
        return S.t('light');
    }
  }

  void _openLanguage() {
    showModalBottomSheet<void>(
      context: context,
      builder: (c) {
        S.watch(c);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(S.t('language'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                LangRail(
                  language: MockSession.language,
                  onChanged: (code) {
                    MockSession.language = code;
                    SessionStore.save();
                    if (mounted) setState(() {});
                    Navigator.pop(c);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAppearance() {
    showModalBottomSheet<void>(
      context: context,
      builder: (c) {
        S.watch(c);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(S.t('appearance'), style: const TextStyle(fontWeight: FontWeight.w800))),
              for (final e in [
                (ThemeMode.light, S.t('light')),
                (ThemeMode.dark, S.t('dark')),
                (ThemeMode.system, S.e('System')),
              ])
                ListTile(
                  title: Text(e.$2),
                  trailing: MockSession.themeMode.value == e.$1
                      ? const Icon(Icons.check, color: MintzerColors.primary)
                      : null,
                  onTap: () {
                    MockSession.themeMode.value = e.$1;
                    setState(() {});
                    Navigator.pop(c);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _deleteAccount() {
    final blocked = MockSession.hasActiveOrder;
    showDialog<void>(
      context: context,
      builder: (c) {
        S.watch(c);
        return AlertDialog(
        title: Text(
          blocked
              ? S.e('Can’t delete account yet')
              : S.t('delete_q'),
        ),
        content: Text(
          blocked
              // l10n-missing
              ? 'You have an order in progress. Please finish or cancel it before deleting your account.'
              // l10n-missing
              : 'This permanently removes your Mintzer account. You won’t be able to log in again with this number.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(blocked ? S.t('ok') : S.t('cancel'))),
          if (!blocked)
            TextButton(
              onPressed: () async {
                Navigator.pop(c);
                if (MockSession.authToken.isNotEmpty) {
                  try {
                    final err = await ProfileApi.instance.deleteAccount(
                      authToken: MockSession.authToken,
                    );
                    if (!mounted) return;
                    if (err != null) {
                      showMintzerToast(context, err, kind: MintzerToastKind.warn);
                      return;
                    }
                  } on AuthApiException catch (e) {
                    if (!mounted) return;
                    showMintzerToast(context, e.message, kind: MintzerToastKind.warn);
                    return;
                  } catch (_) {
                    if (!mounted) return;
                    showMintzerToast(context, S.e('Couldn’t delete account'), kind: MintzerToastKind.warn);
                    return;
                  }
                }
                await PushBootstrap.clearSyncMarker();
                await SessionStore.clearAuth();
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/account-deleted', (_) => false);
              },
              child: Text(S.t('delete_account'), style: const TextStyle(color: Color(0xFFD93025))),
            ),
        ],
        );
      },
    );
  }

  void _logout() {
    showDialog<void>(
      context: context,
      builder: (c) {
        S.watch(c);
        return AlertDialog(
        title: Text(S.e('Log out?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(S.t('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(c);
              final token = MockSession.authToken;
              if (token.isNotEmpty) {
                await ProfileApi.instance.logout(authToken: token);
              }
              await PushBootstrap.clearSyncMarker();
              await SessionStore.clearAuth();
              MockSession.tabIndex.value = 0;
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: Text(S.t('logout'), style: const TextStyle(color: Color(0xFFD93025))),
          ),
        ],
        );
      },
    );
  }
}

class _ReferStrip extends StatelessWidget {
  const _ReferStrip({required this.code, required this.onCopy, required this.onShare});
  final String code;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: MintzerColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.t('refer_h'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(S.e('Per friend'), style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 11)),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 12)),
                    const SizedBox(width: 6),
                    const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: onShare,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            child: Text(S.t('share_wa_short')),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF9AA0A6), letterSpacing: 0.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFF1F3F4)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.title, required this.onTap, this.trailing});
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF202124)))),
            if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9AA0A6)),
          ],
        ),
      ),
    );
  }
}
