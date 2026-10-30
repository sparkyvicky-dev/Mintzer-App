import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/auth_api.dart';
import '../api/placements_api.dart';
import '../config/app_config.dart';
import '../l10n/s.dart';
import '../live/orders_repository.dart';
import '../mock/sample_deals.dart';
import '../mock/session.dart';
import '../mock/session_store.dart';
import '../models/deal.dart';
import '../theme/app_theme.dart';
import '../util/external_links.dart';
import '../util/notification_permission.dart';
import '../util/format.dart';
import '../widgets/brand_mark.dart';
import '../widgets/mintzer_dialogs.dart';
import '../widgets/mintzer_toast.dart';
import '../widgets/product_thumb.dart';
import 'in_app_shop_screen.dart';
import 'order_success_screen.dart';

/// Place order — ChatGPT SS match (centered pay/earn · compact logos · visible OID border).
class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key, required this.deal});

  final MockDeal deal;

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  static const _startSec = MockSession.placementMinutes * 60;
  int _sec = 0;
  Timer? _timer;
  final _oid = TextEditingController();
  late bool _instructionsOpen;
  bool _expiryHandled = false;
  bool _warnedFive = false;
  bool _warnedOne = false;
  bool _submitting = false;

  bool get _useLive =>
      AppConfig.useLiveAcceptApi &&
      MockSession.authToken.isNotEmpty &&
      MockSession.activeAcceptOrderId != null;

  List<({String label, String value, bool copyable})> get _addressRows {
    final rows = _baseAddressRows;
    final code = (widget.deal.couponCode ?? '').trim();
    if (code.isEmpty) return rows;
    return [
      ...rows,
      (label: 'Coupon', value: code, copyable: true),
    ];
  }

  List<({String label, String value, bool copyable})> get _baseAddressRows {
    final addr = MockSession.placementAddress;
    if (addr != null) {
      return addr.copyRows(
        gst: widget.deal.gst,
        storeId: widget.deal.storeId,
        gstNumber: MockSession.placementGstNumber,
      );
    }
    final gst = widget.deal.gst;
    final fk = widget.deal.storeId == 'flipkart';
    return [
      for (final a in kMockAddress)
        if (a.label != 'Company' && a.label != 'GST No.' && a.label != 'GSTIN')
          (label: a.label, value: a.value, copyable: a.label != 'Phone' && a.label != 'Mobile number'),
      if (gst) ...[
        for (final a in kMockAddress)
          if (a.label == 'GST No.' || a.label == 'GSTIN')
            (label: 'GSTIN', value: a.value, copyable: true),
        for (final a in kMockAddress)
          if (a.label == 'Company')
            (label: 'Company', value: a.value, copyable: false),
      ],
    ].where((r) {
      // Drop Amazon-only / Flipkart-only mock rows for the other store.
      if (fk && (r.label.startsWith('Area,') || r.label == 'Town/City' || r.label == 'Full name')) {
        return false;
      }
      if (!fk && widget.deal.storeId == 'amazon' && r.label == 'Location') return false;
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _instructionsOpen = !MockSession.placeInstructionsSeen;
    if (MockSession.placementEndsAt == null && MockSession.activeDeal.value != null) {
      // Rebuild from the open accept's created time — never hand a fresh 15‑min window.
      final open = MockSession.orders.value.where(MockSession.isOpenPlacementOrder).toList();
      if (open.isNotEmpty) {
        MockSession.resumePlacementFromOrder(open.first);
      } else if (MockSession.activeAcceptOrderId == null) {
        MockSession.placementEndsAt =
            DateTime.now().add(const Duration(minutes: MockSession.placementMinutes));
      } else {
        MockSession.expireOpenPlacement();
      }
    }
    // Do not invent a fresh 15:00 when the placement was just cleared / expired.
    final left = MockSession.placementSecLeft;
    if (MockSession.placementEndsAt != null) {
      _sec = left > 0 ? left : 0;
    } else if (MockSession.activeDeal.value != null && MockSession.activeAcceptOrderId == null) {
      _sec = _startSec; // mock-only accept
    } else {
      _sec = left;
    }
    if (_sec <= 60) {
      _warnedFive = true;
      _warnedOne = true;
    } else if (_sec <= 300) {
      _warnedFive = true;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _expiryHandled) return;
      // Cleared by successful submit — do not treat as expiry.
      if (MockSession.placementEndsAt == null) {
        _timer?.cancel();
        return;
      }
      final left = MockSession.placementSecLeft;
      setState(() => _sec = left);
      if (left > 0 && left <= 60 && !_warnedOne) {
        _warnedOne = true;
        MintzerToasts.timerOneMin(context);
      } else if (left > 60 && left <= 300 && !_warnedFive) {
        _warnedFive = true;
        MintzerToasts.timerFiveMin(context);
      }
      if (left <= 0) _handleExpired();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NotificationPermission.maybeAskSecondChance(context);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _oid.dispose();
    super.dispose();
  }

  String get _clock {
    final m = (_sec ~/ 60).toString().padLeft(2, '0');
    final s = (_sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _danger => _sec < 120;

  bool get _oidLooksOk {
    final t = _oid.text.trim();
    return t.length >= 8 && RegExp(r'^[A-Za-z0-9\-]{8,}$').hasMatch(t);
  }

  Future<void> _openStore() async {
    final d = widget.deal;
    final url = (d.productUrl != null && d.productUrl!.isNotEmpty)
        ? d.productUrl!
        : storeFallbackUrl(d.storeId);
    final mode = MockSession.shopMode;
    if (mode == 'inapp') {
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => InAppShopScreen(
            url: url,
            deal: d,
            addressRows: _addressRows,
            onChangeAddress: _changeAddress,
            onConfirmOrderId: (oid) async {
              if (!mounted) return false;
              _oid.text = oid.trim();
              setState(() {});
              await _submit();
              return _expiryHandled;
            },
            onRequestCancel: () {
              if (mounted) {
                // ignore: unawaited_futures
                _cancelPlacement();
              }
            },
            onExpired: () {
              if (mounted) _handleExpired();
            },
            onShopModeChanged: () {
              if (mounted) setState(() {});
            },
          ),
        ),
      );
      return;
    }
    await openExternalUrl(
      context,
      url,
      // l10n-missing
      failTitle: 'Couldn’t open ${d.storeLabel}',
    );
  }

  void _changeShopMode() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (c) {
        S.watch(c);
        return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             ListTile(title: Text(S.e('Order mode'), style: TextStyle(fontWeight: FontWeight.w800))),
            ListTile(
              title: Text(S.t('store_app')),
              trailing: MockSession.shopMode != 'inapp' ? const Icon(Icons.check, color: MintzerColors.primary) : null,
              onTap: () {
                MockSession.shopMode = 'external';
                // ignore: unawaited_futures
                SessionStore.save();
                Navigator.pop(c);
                setState(() {});
              },
            ),
            ListTile(
              title: Text(S.t('inside_mz')),
              trailing: MockSession.shopMode == 'inapp' ? const Icon(Icons.check, color: MintzerColors.primary) : null,
              onTap: () {
                MockSession.shopMode = 'inapp';
                // ignore: unawaited_futures
                SessionStore.save();
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

  Future<void> _copy(String v) async {
    await Clipboard.setData(ClipboardData(text: v));
    if (!mounted) return;
    MintzerToasts.copied(context);
  }

  Future<void> _copyAll() async {
    final rows = _addressRows;
    final want = {
      'Name',
      'Full name',
      'Pincode',
      'Location',
      'Flat, House no., Building',
      'Flat, House no., Building, Company',
      'Area, Street, Sector, Village',
      'Landmark',
      'City',
      'Town/City',
      if (widget.deal.gst) 'GSTIN',
    };
    final lines = <String>[
      for (final r in rows)
        if (r.copyable && want.contains(r.label) && r.value.isNotEmpty) '${r.label}: ${r.value}',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    MintzerToasts.deliveryCopied(context, gst: widget.deal.gst);
  }

  Future<void> _pasteOid() async {
    final data = await Clipboard.getData('text/plain');
    final t = (data?.text ?? '').trim().replaceAll(RegExp(r'\s+'), '');
    if (t.isEmpty) {
      if (!mounted) return;
      showMintzerToast(context, S.e('Nothing to paste'), kind: MintzerToastKind.warn, icon: Icons.content_paste_off_rounded);
      return;
    }
    setState(() => _oid.text = t);
  }

  void _onOidChanged(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\s+'), '');
    if (cleaned != raw) {
      _oid.value = TextEditingValue(text: cleaned, selection: TextSelection.collapsed(offset: cleaned.length));
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_sec <= 0) {
      MintzerToasts.timerExpired(context);
      return;
    }
    final oid = _oid.text.trim();
    if (!_oidLooksOk) {
      showMintzerToast(context, S.e('Enter a valid store Order ID'), kind: MintzerToastKind.warn);
      return;
    }

    if (_useLive) {
      setState(() => _submitting = true);
      try {
        await PlacementsApi.instance.updateOrderId(
          authToken: MockSession.authToken,
          acceptOrderId: MockSession.activeAcceptOrderId!,
          storeOrderId: oid,
        );
        _timer?.cancel();
        _expiryHandled = true;
        final order = MockSession.submitOrder(deal: widget.deal, orderId: oid);
        // Refresh live list in background.
        // ignore: unawaited_futures
        OrdersRepository.instance.refreshFromLiveApi();
        if (!mounted) return;
        MintzerToasts.orderSubmitted(context);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => OrderSuccessScreen(order: order)),
          (r) => r.settings.name == '/main',
        );
      } on AuthApiException catch (e) {
        if (mounted) {
          showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
        }
      } catch (_) {
        if (mounted) {
          showMintzerToast(context, S.e('Couldn’t submit Order ID. Try again.'), kind: MintzerToastKind.danger);
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    _timer?.cancel();
    _expiryHandled = true;
    final order = MockSession.submitOrder(deal: widget.deal, orderId: oid);
    MintzerToasts.orderSubmitted(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => OrderSuccessScreen(order: order)),
      (r) => r.settings.name == '/main',
    );
  }

  void _handleExpired() {
    if (_expiryHandled || !mounted) return;
    if (MockSession.placementEndsAt == null) return;
    _expiryHandled = true;
    _timer?.cancel();
    final acceptId = MockSession.activeAcceptOrderId;
    final token = MockSession.authToken;
    if (AppConfig.useLiveAcceptApi && token.isNotEmpty && acceptId != null) {
      // ignore: unawaited_futures
      PlacementsApi.instance.autoDeleteOrder(authToken: token, acceptOrderId: acceptId);
    }
    MockSession.clearPlacement();
    MintzerToasts.timerExpired(context);
    showMintzerDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        S.watch(c);
        return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.e('Time’s up'),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
          ),
          const SizedBox(height: 8),
          const Text(
            // l10n-missing
            'This placement expired. Accept the deal again from Home if you still want it.',
            style: TextStyle(fontSize: 14, color: Color(0xFF5F6368), height: 1.4),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(c);
                MockSession.tabIndex.value = 0;
                Navigator.of(context).popUntil((r) => r.settings.name == '/main' || r.isFirst);
              },
              style: FilledButton.styleFrom(
                backgroundColor: MintzerColors.primary,
                minimumSize: const Size(0, 44),
              ),
              child: Text(S.e('Back to Home'), style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
      },
    );
  }

  Future<void> _cancelPlacement() async {
    final confirmed = await showMintzerDialog<bool>(
      context: context,
      builder: (c) {
        S.watch(c);
        return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.t('cancel_this'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
          ),
          const SizedBox(height: 8),
          Text(
            S.e('You’ll lose this placement and can accept another deal from Home.'),
            style: TextStyle(fontSize: 14, color: Color(0xFF5F6368), height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(c, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: const Color(0xFF202124),
                    side: const BorderSide(color: Color(0xFFDADCE0)),
                  ),
                  child: Text(S.e('Keep going'), style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: const Color(0xFFD93025),
                  ),
                  child: Text(S.e('Cancel order'), style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      );
      },
    );
    if (confirmed != true || !mounted) return;

    if (_useLive) {
      final acceptId = MockSession.activeAcceptOrderId;
      if (acceptId == null) {
        // Nothing to cancel on server — clear local strip.
      } else {
        try {
          await PlacementsApi.instance.cancelOrder(
            authToken: MockSession.authToken,
            acceptOrderId: acceptId,
            reason: 'User cancelled from Place order',
          );
        } on AuthApiException catch (e) {
          // Soft-deleted / already gone — still clear Place order locally.
          final gone = e.statusCode == 404 ||
              e.message.toLowerCase().contains('order not found') ||
              e.message.toLowerCase().contains('already be cancelled') ||
              e.message.toLowerCase().contains('already be canceled');
          if (!gone) {
            if (mounted) {
              showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
            }
            return;
          }
        } catch (_) {
          if (mounted) {
            showMintzerToast(context, S.e('Couldn’t cancel. Try again.'), kind: MintzerToastKind.danger);
          }
          return;
        }
      }
    }

    _timer?.cancel();
    _expiryHandled = true;
    MockSession.clearPlacement();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _changeAddress() {
    if (_useLive || MockSession.placementAddress != null) {
      showMintzerToast(
        context,
        S.e('Address is assigned for this deal'),
        // l10n-missing
        subtitle: 'Contact support if you need a change',
        kind: MintzerToastKind.info,
        icon: Icons.home_work_outlined,
      );
      return;
    }
    final gst = widget.deal.gst;
    showMintzerDialog<void>(
      context: context,
      builder: (c) {
        S.watch(c);
        return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.e('Change delivery address?'),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
          ),
          const SizedBox(height: 8),
          Text(
            gst
                // l10n-missing
                ? 'Keep the same Company and GSTIN shown here, or invoice verification may fail.'
                // l10n-missing
                : 'Same pincode. Weekly limit from admin.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368), height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(c),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: const Color(0xFF202124),
                    side: const BorderSide(color: Color(0xFFDADCE0)),
                  ),
                  child: Text(S.e('Not now'), style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(c);
                    showMintzerToast(
                      context,
                      S.e('New address ready'),
                      // l10n-missing
                      subtitle: 'Copy the lines again',
                      kind: MintzerToastKind.info,
                      icon: Icons.home_work_outlined,
                    );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: MintzerColors.primary,
                  ),
                  child: Text(S.t('continue'), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      );
      },
    );
  }

  void _showPlaceHelp(BuildContext context) {
    final d = widget.deal;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (c) {
        S.watch(c);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(S.e('How Place order works'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  // l10n-missing
                  'Finish on ${d.storeLabel} before the timer ends, then paste the Order ID here.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368), height: 1.4),
                ),
                const SizedBox(height: 14),
                _helpTip(S.e('1'), 'Open the product with our link only — don’t search manually.'),
                _helpTip(
                  '2',
                  d.storeId == 'flipkart'
                      // l10n-missing
                      ? 'Copy each line into the Flipkart field with the same title (Location, Flat, Pincode…). For Mobile number, use your own.'
                      : d.storeId == 'amazon'
                          ? S.e('Copy each line into the Amazon field with the same title. For Mobile number, use your own.')
                          // l10n-missing
                          : 'Copy each address line into the matching store field. For Mobile number, use your own.',
                ),
                if (d.gst) _helpTip(S.e('GST'), 'Enter Company and GSTIN exactly as shown so your invoice can be verified.'),
                // l10n-missing
                _helpTip('3', 'After checkout, paste the ${d.storeLabel} Order ID and tap Confirm order.'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(c),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    backgroundColor: MintzerColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(S.e('Got it'), style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _helpTip(String mark, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFF3EEFF), shape: BoxShape.circle),
            child: Text(mark, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5B4BDB))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF202124), height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final d = widget.deal;
    final canConfirm = _oidLooksOk && _sec > 0;
    const border = Color(0xFFDADCE0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 4,
        title: Text(
          S.t('place_order'),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _cancelPlacement,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD93025),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            child: Text(S.t('cancel')),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: S.e('How Place order works'),
            onPressed: () => _showPlaceHelp(context),
            icon: const Icon(Icons.help_outline_rounded, size: 20),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: Tooltip(
                // l10n-missing
                message: 'Deal reserved for $_clock',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _danger ? const Color(0xFFFCE8E6) : const Color(0xFFF3EEFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 13, color: _danger ? const Color(0xFFD93025) : MintzerColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        _clock,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _danger ? const Color(0xFFD93025) : const Color(0xFF5B4BDB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: [
          // ── Product ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductThumb(deal: d, size: 76, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.25)),
                      const SizedBox(height: 4),
                      Text(
                        '${d.color} · ${d.variant} · ${S.t('qty')}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                      ),
                      const SizedBox(height: 8),
                      // Short logo chips (ChatGPT: ~line-height, not tall tiles)
                      Row(
                        children: [
                          _LogoChip(
                            mark: BrandMark(size: 14, asset: d.storeLogo, letter: d.storeLabel),
                            label: d.storeLabel,
                          ),
                          const SizedBox(width: 6),
                          _LogoChip(
                            mark: BrandMark(
                              size: 14,
                              asset: d.cardLogo,
                              anyCard: d.cardId == 'any',
                              letter: d.cardLabel,
                            ),
                            label: d.homeCardLabel,
                          ),
                        ],
                      ),
                      if (d.gst) ...[
                        const SizedBox(height: 8),
                        _Pill(
                          text: S.e('GST invoice required for payout'),
                          fill: MintzerColors.gstFill,
                          color: MintzerColors.gstText,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Full-width exact-variant strip (ChatGPT)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EEFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF5B4BDB)),
                            const SizedBox(width: 6),
                             Expanded(
                              child: Text(
                                S.e('Buy this exact model & storage'),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B4BDB)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── You pay | You earn — stretch + textAlign (true center in each half) ──
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        S.e('You pay at checkout'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF5F6368), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatInr(d.spend),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.1),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        d.discount > 0
                            // l10n-missing
                            ? '₹${d.discount} off at checkout'
                            : S.t('on_store', {'store': d.storeLabel}),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCEEAD6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        S.t('you_earn'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF137333), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatInr(d.earn),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.1, color: Color(0xFF188038)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        d.tdsAmount > 0
                            ? S.e('Profit after TDS')
                            // l10n-missing
                            : 'After the order',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF137333)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Instructions (kept) ──
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEDE7FF)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: _instructionsOpen,
                onExpansionChanged: (v) {
                  setState(() => _instructionsOpen = v);
                  if (!v) MockSession.placeInstructionsSeen = true;
                },
                tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                leading: const Icon(Icons.assignment_outlined, color: MintzerColors.primary, size: 22),
                title: Text(S.t('instructions'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                children: [
                  _rule(
                    1,
                    // l10n-missing
                    d.isInstantLink ? 'Use the Instant payment link below' : 'Use the product link below',
                    warn: d.isInstantLink
                        // l10n-missing
                        ? 'Open our payment page only. Pay with ${d.homeCardLabel} — same card shown on the deal.'
                        // l10n-missing
                        : 'Do not search manually on ${d.storeLabel}. Open the product link only.',
                  ),
                  _rule(
                    2,
                    // l10n-missing
                    'Buy the exact model',
                    // l10n-missing
                    body: 'Match model, variant, color and storage — Qty: 1.',
                  ),
                  _rule(
                    3,
                    // l10n-missing
                    'Pay using ${d.homeCardLabel}',
                    // l10n-missing
                    body: 'Use this card at checkout to get the deal offer.',
                  ),
                  if (d.gst)
                    _rule(
                      4,
                      S.e('GST invoice required for payout'),
                      // l10n-missing
                      body: 'Enter Company and GSTIN from Delivery details at checkout.',
                    ),
                  if (d.isInstantLink)
                    _rule(
                      d.gst ? 5 : 4,
                      // l10n-missing
                      'Instant payout',
                      // l10n-missing
                      body: 'After you finish, payout is within ${d.paymentHours} working hours.',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Step 1 ──
          _Step(
            n: 1,
            title: d.isInstantLink
                // l10n-missing
                ? 'Open Instant payment page'
                : S.t('open_product', {'store': d.storeLabel}),
            last: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  d.isInstantLink
                      // l10n-missing
                      ? 'Open our payment link, pay with ${d.homeCardLabel}, then finish like a normal deal.'
                      // l10n-missing
                      : 'Use this link to open the exact product. Do not search manually.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _openStore,
                  icon: Icon(MockSession.shopMode == 'inapp' ? Icons.phone_android_rounded : Icons.open_in_new_rounded, size: 18),
                  label: Text(
                    d.isInstantLink
                        // l10n-missing
                        ? 'Open payment page'
                        : (MockSession.shopMode == 'inapp'
                            // l10n-missing
                            ? 'Open inside Mintzer'
                            // l10n-missing
                            : 'Open on ${d.storeLabel}'),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: MintzerColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _changeShopMode,
                    style: TextButton.styleFrom(
                      foregroundColor: MintzerColors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    child: Text(
                      MockSession.shopMode == 'inapp'
                          // l10n-missing
                          ? 'Change to store app'
                          // l10n-missing
                          : 'Change to in-app browser',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _copy(d.productUrl ?? 'https://www.${d.storeId}.com/'),
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: Text(
                    d.isInstantLink
                        ? S.e('Copy payment link')
                        : S.t('copy_link'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5F6368),
                    side: const BorderSide(color: border),
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // ── Step 2 ──
          _Step(
            n: 2,
            title: d.gst
                ? S.e('Delivery & GST details')
                // l10n-missing
                : 'Delivery details',
            last: false,
            badge: d.gst
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: MintzerColors.gstFill,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: MintzerColors.gstBorder),
                    ),
                    child: Text(S.e('GST required'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: MintzerColors.gstText)),
                  )
                : null,
            child: _AddressBlock(
              gst: d.gst,
              storeId: d.storeId,
              rows: _addressRows,
              onCopy: _copy,
              onCopyAll: _copyAll,
              onChange: _changeAddress,
            ),
          ),

          // ── Step 3 — visible border on Order ID ──
          _Step(
            n: 3,
            // l10n-missing
            title: 'Enter ${d.storeLabel} Order ID',
            last: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  // l10n-missing
                  'Enter this only after your order is successfully placed.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35),
                ),
                const SizedBox(height: 10),
                // Explicit Container stroke — OutlineInputBorder alone can look invisible on M3
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canConfirm ? const Color(0xFF34A853) : const Color(0xFF9AA0A6),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _oid,
                    onChanged: _onOidChanged,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: d.storeId == 'amazon'
                          ? S.e('Amazon order ID · e.g. 402-1234567-1234567')
                          : d.storeId == 'flipkart'
                              // l10n-missing
                              ? 'Flipkart order ID · e.g. OD4321987654321'
                              // l10n-missing
                              : 'Enter store Order ID',
                      hintStyle: const TextStyle(fontWeight: FontWeight.w400, color: Color(0xFF9AA0A6), fontSize: 13),
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canConfirm) const Icon(Icons.check_circle, size: 20, color: Color(0xFF188038)),
                          TextButton.icon(
                            onPressed: _pasteOid,
                            icon: const Icon(Icons.content_paste_rounded, size: 15),
                            label: Text(S.e('Paste')),
                            style: TextButton.styleFrom(
                              foregroundColor: MintzerColors.primary,
                              visualDensity: VisualDensity.compact,
                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: canConfirm && !_submitting ? _submit : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    backgroundColor: MintzerColors.primary,
                    disabledBackgroundColor: const Color(0xFFE8EAED),
                    disabledForegroundColor: const Color(0xFF9AA0A6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text(S.e('Confirm order'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_outlined, size: 20, color: MintzerColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.e('What happens next?'),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.gst
                            // l10n-missing
                            ? 'After delivery, upload the GST invoice. We verify it, then pay earnings to your bank.'
                            : S.e('After delivery, upload the invoice. We verify it, then pay earnings to your bank.'),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rule(int n, String title, {String? body, String? warn}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFEDE7FF), shape: BoxShape.circle),
            child: Text('$n', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: MintzerColors.primary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                if (body != null) ...[
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35)),
                ],
                if (warn != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(color: const Color(0xFFFEF7E0), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE37400)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(warn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368), height: 1.35)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoChip extends StatelessWidget {
  const _LogoChip({required this.mark, required this.label});
  final Widget mark;
  final String label;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      height: 22,
      padding: const EdgeInsets.only(left: 3, right: 7),
      alignment: Alignment.center,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, height: 1)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.fill, required this.color});
  final String text;
  final Color fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.n,
    required this.title,
    required this.last,
    required this.child,
    this.badge,
  });

  final int n;
  final String title;
  final bool last;
  final Widget child;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 26,
              child: Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: MintzerColors.primary, shape: BoxShape.circle),
                    child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDD4FF),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                      if (badge != null) ...[const SizedBox(width: 6), badge!],
                    ],
                  ),
                  const SizedBox(height: 10),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  const _AddressBlock({
    required this.gst,
    required this.storeId,
    required this.rows,
    required this.onCopy,
    required this.onCopyAll,
    required this.onChange,
  });

  final bool gst;
  final String storeId;
  final List<({String label, String value, bool copyable})> rows;
  final ValueChanged<String> onCopy;
  final VoidCallback onCopyAll;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final displayRows = rows
        .map((r) => (r.label, r.value, r.copyable))
        .toList();

    final hint = storeId == 'flipkart'
        ? S.e('Titles match Flipkart checkout. Paste Location into Flipkart’s Location field, then Flat / Landmark / Pincode into the same-named fields.')
        : storeId == 'amazon'
            // l10n-missing
            ? 'Titles match Amazon checkout. Paste each line into the field with the same name.'
            // l10n-missing
            : 'Paste each line into the matching address field on the store.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gst)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              S.e('Use these exact details at checkout so your invoice can be verified.'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368), height: 1.35),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onCopyAll,
            icon: const Icon(Icons.copy_all_rounded, size: 16),
            label: Text(S.e('Copy all details')),
            style: TextButton.styleFrom(
              foregroundColor: MintzerColors.primary,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (displayRows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              S.e('No delivery address for this deal (Instant payment may not need one).'),
              style: TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35),
            ),
          )
        else
          for (final r in displayRows) _row(r.$1, r.$2, r.$3, onCopy),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
          child: Text(hint, style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368), height: 1.4)),
        ),
        InkWell(
          onTap: onChange,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF5B4BDB)),
                const SizedBox(width: 8),
                 Expanded(
                  child: Text(
                    S.e('Change address'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5B4BDB)),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: Color(0xFF5B4BDB)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, bool copyable, ValueChanged<String> onCopy) {
    final coupon = label == 'Coupon';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: coupon ? const Color(0xFFEDE7FF) : const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: coupon ? const Color(0xFFDDD4FF) : const Color(0xFFE8EAED)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 92,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: coupon ? const Color(0xFF5B4BDB) : const Color(0xFF9AA0A6),
                  fontWeight: coupon ? FontWeight.w700 : FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: coupon
                      ? FontWeight.w800
                      : (copyable ? FontWeight.w700 : FontWeight.w600),
                  color: coupon
                      ? const Color(0xFF5B4BDB)
                      : (copyable ? const Color(0xFF202124) : const Color(0xFF5F6368)),
                ),
              ),
            ),
            if (copyable)
              TextButton(
                onPressed: () => onCopy(value),
                style: TextButton.styleFrom(
                  foregroundColor: MintzerColors.primary,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                child: Text(S.t('copy')),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
