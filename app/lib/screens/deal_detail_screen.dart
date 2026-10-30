import 'dart:async';

import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../api/placements_api.dart';
import '../config/app_config.dart';
import '../l10n/s.dart';
import '../mock/session.dart';
import '../models/deal.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/brand_mark.dart';
import '../widgets/deal_image_gallery.dart';
import '../widgets/image_alert_popup.dart';
import '../widgets/kyc_sheet.dart';
import '../widgets/mintzer_dialogs.dart';
import '../widgets/mintzer_toast.dart';
import '../widgets/money_summary_card.dart';
import '../widgets/payout_account_sheet.dart';
import '../widgets/product_image_cache.dart';
import '../widgets/report_chip.dart';
import '../widgets/swipe_to_accept.dart';
import '../util/external_links.dart';
import 'place_order_screen.dart';

/// Deal detail — agreed premium clarity (Payment summary · Before you order · rich swipe).
class DealDetailScreen extends StatefulWidget {
  const DealDetailScreen({super.key, required this.deal});

  final MockDeal deal;

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  int _swipeGen = 0;
  bool _accepting = false;
  DealDetailLive? _prefetched;
  Future<DealDetailLive>? _prefetchFuture;
  late final DateTime _openedAt;
  bool _viewReported = false;
  bool _dealPopupShown = false;
  MockDeal? _priced;

  MockDeal get deal => _priced ?? widget.deal;

  bool get _useLiveAccept =>
      AppConfig.useLiveAcceptApi &&
      AppConfig.useLiveDealsApi &&
      MockSession.authToken.isNotEmpty &&
      widget.deal.liveNumericId != null;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    ProductImageCache.warmUrls(deal.allImageUrls, context: context, limit: 8);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeDealPopup(deal));
    if (_useLiveAccept) {
      _prefetchFuture = PlacementsApi.instance
          .fetchDealDetail(dealId: widget.deal.liveNumericId!, userId: MockSession.userId)
          .then((d) {
        _prefetched = d;
        if (d.pricedDeal != null && mounted) {
          setState(() => _priced = d.pricedDeal);
          ProductImageCache.warmUrls(d.pricedDeal!.allImageUrls, context: context, limit: 8);
          _maybeDealPopup(d.pricedDeal!);
        }
        return d;
      });
    }
  }

  @override
  void dispose() {
    _reportViewIfNeeded();
    super.dispose();
  }

  void _maybeDealPopup(MockDeal d) {
    if (_dealPopupShown || !mounted) return;
    final image = (d.popupImage ?? '').trim();
    if (image.isEmpty) return;
    _dealPopupShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showImageAlertPopup(context, imageUrl: image, link: d.popupUrl);
    });
  }

  void _reportViewIfNeeded() {
    if (_viewReported) return;
    final id = deal.liveNumericId;
    if (id == null || MockSession.authToken.isEmpty) return;
    final dwell = DateTime.now().difference(_openedAt).inSeconds;
    if (dwell < 15) return;
    _viewReported = true;
    unawaited(
      AuthApi.instance.reportDealView(
        authToken: MockSession.authToken,
        dealId: id,
        dwellSeconds: dwell,
      ),
    );
  }

  Future<bool> _accept() async {
    if (_accepting) return false;
    if (MockSession.activeDeal.value != null) {
      if (!mounted) return false;
      await showBlockedAcceptDialog(
        context,
        onContinueOrder: () {
          MockSession.goToOrdersTab();
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      );
      return false;
    }
    if (!MockSession.kycDone) {
      final ok = await showKycSheet(context);
      if (ok != true || !mounted) return false;
    }
    if (!MockSession.payoutDone) {
      final ok = await showPayoutSheet(context, stepOfTwo: true);
      if (ok != true || !mounted) return false;
    }
    if (!MockSession.shopModeAsked) {
      final mode = await showShopModeDialog(context);
      if (mode == null || !mounted) return false;
      MockSession.shopMode = mode;
      MockSession.shopModeAsked = true;
    }
    if (deal.gst && mounted) {
      final ok = await showGstAlertDialog(context);
      if (!ok || !mounted) return false;
    }

    if (_useLiveAccept) {
      return _acceptLive();
    }

    MockSession.reserveDeal(deal);
    if (!mounted) return false;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => PlaceOrderScreen(deal: deal)),
    );
    return true;
  }

  Future<bool> _acceptLive() async {
    setState(() => _accepting = true);
    try {
      final dealId = deal.liveNumericId!;
      DealDetailLive detail;
      try {
        detail = _prefetched ??
            await (_prefetchFuture ??
                PlacementsApi.instance.fetchDealDetail(dealId: dealId, userId: MockSession.userId));
        _prefetched = detail;
      } catch (_) {
        detail = await PlacementsApi.instance.fetchDealDetail(dealId: dealId, userId: MockSession.userId);
      }

      // Resume existing open placement for this deal if any.
      if (detail.acceptOrderId != null && detail.address != null) {
        final liveDeal = detail.pricedDeal ?? deal;
        MockSession.reserveDeal(
          liveDeal,
          acceptOrderId: detail.acceptOrderId,
          address: detail.address,
          gstNumber: detail.gstNumber,
        );
        if (!mounted) return false;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => PlaceOrderScreen(deal: liveDeal)),
        );
        return true;
      }

      final isInstant = deal.isInstantLink || detail.isPineLab;
      if (!isInstant && detail.address == null) {
        if (mounted) {
          showMintzerToast(
            context,
            S.e('No delivery address available for this deal. Try again later.'),
            kind: MintzerToastKind.warn,
          );
        }
        return false;
      }

      final amount = detail.sellingPrice > 0 ? detail.sellingPrice : deal.spend;
      final result = await PlacementsApi.instance.acceptOrder(
        authToken: MockSession.authToken,
        dealId: dealId,
        orderAmount: amount,
        addressId: isInstant ? null : detail.address?.addressId,
      );

      // Prefer panel-priced deal for Place order You pay / You earn.
      final liveDeal = detail.pricedDeal ?? deal;
      MockSession.reserveDeal(
        liveDeal,
        acceptOrderId: result.acceptOrderId,
        endsAt: result.reservedEndsAt,
        address: detail.address,
        gstNumber: detail.gstNumber,
      );

      _viewReported = true; // don't schedule follow-ups after Accept
      unawaited(
        AuthApi.instance.cancelDealViewFollowups(
          authToken: MockSession.authToken,
          dealId: dealId,
        ),
      );

      if (!mounted) return false;
      // Navigate first — ask notifications on Place order (don't block after swipe).
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => PlaceOrderScreen(deal: liveDeal)),
      );
      return true;
    } on AuthApiException catch (e) {
      if (mounted) {
        showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
      }
      return false;
    } catch (e) {
      if (mounted) {
        showMintzerToast(context, S.e('Couldn’t accept deal. Try again.'), kind: MintzerToastKind.danger);
      }
      return false;
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  String? get _urgencyLabel {
    final u = deal.urgency;
    if (u == null) return null;
    if (u.kind == 'slots' && deal.slotsLeft != null) {
      final n = deal.slotsLeft!;
      return n == 1 ? S.e('Only 1 deal left') : 'Only $n deals left';
    }
    if (u.kind == 'hot') {
      // l10n-missing
      return 'Hot deal';
    }
    return u.label;
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final urgency = _urgencyLabel;
    final needsCardApply = deal.cardId != 'any';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 0,
        leading: const BackButton(),
        title: Text(S.t('deal_detail'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ReportChip(
              onTap: () => openSupportWhatsApp(
                context,
                // l10n-missing
                preset: 'Hi Mintzer, issue with deal: ${deal.name}',
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          DealImageGallery(
            deal: deal,
            height: 240,
            autoPlay: true,
            showGst: true,
            showDots: true,
            showCount: true,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          ),
          const SizedBox(height: 12),
          // Product
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      deal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCEEAD6)),
                    ),
                    child: Text(
                      S.t('earn_rupee', {'n': formatInr(deal.earn).replaceFirst('₹', '')}),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: MintzerColors.earnGreen, height: 1.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${deal.color} · ${deal.variant} · ${S.t('qty')}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: MintzerColors.primary),
                  const SizedBox(width: 4),
                   Expanded(
                    child: Text(
                      S.e('Buy this exact variant'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MintzerColors.primary),
                    ),
                  ),
                ],
              ),
              if (urgency != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    urgency,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE37400)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Buy on / Pay using
          Row(
            children: [
              Expanded(
                child: _BuyChip(
                  label: S.e('Buy on'),
                  value: deal.storeLabel,
                  mark: BrandMark(size: 28, asset: deal.storeLogo, letter: deal.storeLabel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BuyChip(
                  // l10n-missing
                  label: 'Pay using',
                  value: deal.homeCardLabel,
                  mark: BrandMark(size: 28, asset: deal.cardLogo, anyCard: deal.cardId == 'any', letter: deal.cardLabel),
                ),
              ),
            ],
          ),
          if (needsCardApply) ...[
            const SizedBox(height: 8),
            _CompactApplyBanner(deal: deal),
          ],
          const SizedBox(height: 12),
          MoneySummaryCard(deal: deal),
          if (deal.gst) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: MintzerColors.gstFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MintzerColors.gstBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 18, color: MintzerColors.gstText),
                  const SizedBox(width: 8),
                   Expanded(
                    child: Text(
                      S.e('GST invoice needed. At checkout, enter the Company and GST No. shown in the delivery address.'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MintzerColors.gstText, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (deal.isInstantLink) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0D6FF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 18, color: MintzerColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      // l10n-missing
                      'Instant · Open our payment link, pay with ${deal.homeCardLabel}, finish like a normal deal. Paid within ${deal.paymentHours} working hours.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5B4BDB), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _BeforeYouOrder(deal: deal),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: MintzerColors.primary),
                const SizedBox(width: 8),
                 Expanded(
                  child: Text(
                    S.e('Accept only if you can place this order now.'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5B4BDB), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 88),
        ],
      ),
      bottomNavigationBar: Material(
        color: Colors.white,
        elevation: 10,
        shadowColor: Colors.black26,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: _accepting ? 0.55 : 1,
                  child: IgnorePointer(
                    ignoring: _accepting,
                    child: SwipeToAccept(
                      key: ValueKey(_swipeGen),
                      onAccepted: () async {
                        if (_accepting) return;
                        final ok = await _accept();
                        if (!ok && mounted) setState(() => _swipeGen++);
                      },
                    ),
                  ),
                ),
                if (_accepting)
                  const Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.6, color: MintzerColors.primary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuyChip extends StatelessWidget {
  const _BuyChip({required this.label, required this.value, required this.mark});
  final String label;
  final String value;
  final Widget mark;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        children: [
          mark,
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9AA0A6))),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFFB0B3B8)),
        ],
      ),
    );
  }
}

class _CompactApplyBanner extends StatelessWidget {
  const _CompactApplyBanner({required this.deal});
  final MockDeal deal;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final label = deal.homeCardLabel;
    return Material(
      color: const Color(0xFFF3EEFF),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          openPartnerCards(context);
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  // l10n-missing
                  "Don't have $label? Apply now",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B4BDB)),
                ),
              ),
              const Icon(Icons.arrow_forward, size: 16, color: MintzerColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _BeforeYouOrder extends StatelessWidget {
  const _BeforeYouOrder({required this.deal});
  final MockDeal deal;

  static List<String> get _defaults => [
    S.e('Buy this exact variant (color & storage).'),
    S.e('Apply coupon at checkout if the deal requires it.'),
    S.e('Upload the store invoice after delivery.'),
  ];

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final hasDealRules = (deal.offerText?.trim().isNotEmpty ?? false) || deal.rules.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.e('Before you order'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final t in _defaults)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: MintzerColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (hasDealRules) ...[
          const SizedBox(height: 10),
          _DealInstructions(deal: deal),
        ],
      ],
    );
  }
}

/// Demo-style collapsible deal rules (`offerText` + `rules`).
class _DealInstructions extends StatelessWidget {
  const _DealInstructions({required this.deal});
  final MockDeal deal;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EAED)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Text(
            S.t('instructions'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
          ),
          children: [
            if (deal.offerText != null && deal.offerText!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  deal.offerText!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.4),
                ),
              ),
            for (final r in deal.rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.4)),
                    Expanded(
                      child: Text(r, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.4)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
