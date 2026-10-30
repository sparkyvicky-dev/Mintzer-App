import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../api/auth_api.dart';
import '../api/logistics_api.dart';
import '../api/order_writes_api.dart';
import '../api/placements_api.dart';
import '../config/app_config.dart';
import '../live/order_mapper.dart';
import '../l10n/s.dart';
import '../live/orders_repository.dart';
import '../live/tickets_repository.dart';
import '../mock/session.dart';
import '../models/deal.dart';
import '../models/mock_order.dart';
import '../models/mock_ticket.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../util/couriers.dart';
import '../util/play_in_app_review.dart';
import '../util/delivery_call.dart';
import '../widgets/brand_mark.dart';
import '../widgets/delivery_call_card.dart';
import '../widgets/mintzer_dialogs.dart';
import '../widgets/mintzer_toast.dart';
import '../widgets/product_thumb.dart';
import '../widgets/raise_ticket_sheet.dart';
import 'ticket_detail_screen.dart';

/// Order detail — one journey, one expanded stage. Agreed polish (20 Sep).
/// Keeps locked: Confirmation label, purple until Paid → green, money meanings.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.order,
    this.launchCancel = false,
    this.launchEditOfd = false,
  });

  final MockOrder order;
  final bool launchCancel;
  /// Open the OTP and last-4 form. Used by the Rescheduled line on My Orders.
  final bool launchEditOfd;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late MockOrder _order;
  late final TextEditingController _track;
  late final TextEditingController _otp;
  late final TextEditingController _last4;
  late final TextEditingController _oid;
  late final AnimationController _pulse;
  late final ScrollController _scroll;
  late final String _cheer;
  final GlobalKey _currentKey = GlobalKey();

  bool _busy = false;
  String? _busyLabel;
  Timer? _poll;
  /// While editing Order ID / tracking / OFD, ignore live refreshes that would jump the timeline.
  int? _holdStep;

  static const _cheers = [
    'cheer1',
    'cheer2',
    'cheer3',
    'cheer4',
  ];

  static const _stepKeys = [
    'step_placed',
    'step_tracking',
    'step_ofd',
    'step_confirm',
    'step_invoice',
    'step_payment',
    'step_paid',
  ];

  String _stepName(int i) => S.t(_stepKeys[i.clamp(0, _stepKeys.length - 1)]);

  static const _stepIcons = [
    Icons.shopping_bag_outlined,
    Icons.local_shipping_outlined,
    Icons.inventory_2_outlined,
    Icons.home_outlined,
    Icons.description_outlined,
    Icons.schedule,
    Icons.check_circle_outline,
  ];

  MockOrder get o => _order;
  bool get canEdit => !o.paid && !o.canceled;
  bool _moreOpen = false;

  List<_MoreAction> get _moreActions {
    if (!canEdit) return const [];
    return const [_MoreAction.note, _MoreAction.cancel];
  }

  void _closeMore() {
    if (!_moreOpen) return;
    setState(() => _moreOpen = false);
  }

  void _pickMore(_MoreAction action) {
    _closeMore();
    switch (action) {
      case _MoreAction.note:
        _addNote();
      case _MoreAction.cancel:
        _cancel();
    }
  }
  MockDeal get d => o.deal;

  /// From Mintzer = admin Total receive / mintzer_payout. Never You pay + profit.
  int get _fromMintzer => o.bankReturnAmount;

  bool get _isLive => o.liveRail != null;

  bool get _useLiveWrites =>
      AppConfig.useLiveOrdersApi &&
      AppConfig.useLiveAcceptApi &&
      MockSession.authToken.isNotEmpty &&
      o.liveAcceptOrderId != null;

  /// Payout destination — profile / order fields only. Never invent HDFC ••••4321.
  String get _bankLabel {
    final name = o.bankName.isNotEmpty ? o.bankName : MockSession.bankName.trim();
    final last4 = o.accountLast4.isNotEmpty
        ? o.accountLast4
        : (MockSession.bankAccount.length >= 4
            ? MockSession.bankAccount.substring(MockSession.bankAccount.length - 4)
            : '');
    if (name.isEmpty && last4.isEmpty) return '';
    if (last4.isEmpty) return name;
    if (name.isEmpty) return '••••$last4';
    return '$name ••••$last4';
  }

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    WidgetsBinding.instance.addObserver(this);
    MockSession.orders.addListener(_onOrdersUpdated);
    MockSession.tickets.addListener(_onTicketsUpdated);
    _track = TextEditingController(text: o.tracking);
    _otp = TextEditingController(text: o.otp);
    _last4 = TextEditingController(text: o.phoneLast4);
    _oid = TextEditingController(text: o.orderId == '—' ? '' : o.orderId);
    _scroll = ScrollController();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat(reverse: true);

    if (o.step == 5 && !o.paid) {
      if (o.cheerVisit < 1) {
        o.cheerVisit = 1;
      } else if (o.cheerVisit < 4) {
        o.cheerVisit++;
      }
    }
    final idx = (o.cheerVisit <= 0 ? 1 : o.cheerVisit).clamp(1, 4) - 1;
    _cheer = _cheers[idx];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.launchCancel && o.ongoing && mounted) _cancel();
      if (widget.launchEditOfd && o.ongoing && mounted) {
        _beginEdit(2);
      } else if (_scroll.hasClients && _scroll.offset > 0) {
        // Stay at top on open — GlobalKey on Payment was yanking scroll down.
        _scroll.jumpTo(0);
      }
      if (o.paid && mounted) {
        PlayInAppReview.maybeAskAfterPayout(context);
      }
      // Pull latest admin status (Delivered / Verified / Paid).
      // ignore: unawaited_futures
      _refreshLiveQuiet();
      // ignore: unawaited_futures
      TicketsRepository.instance.refreshFromLiveApi();
      // ignore: unawaited_futures
      LogisticsApi.instance.refreshIntoCouriers();
    });
    if (AppConfig.useLiveOrdersApi &&
        MockSession.authToken.isNotEmpty &&
        (o.liveAcceptOrderId != null || o.liveRail != null) &&
        !o.paid &&
        !o.canceled) {
      _poll = Timer.periodic(const Duration(seconds: 8), (_) {
        if (!mounted || _busy || o.paid || o.canceled) return;
        // ignore: unawaited_futures
        _refreshLiveQuiet();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ignore: unawaited_futures
      _refreshLiveQuiet();
    }
  }

  Future<void> _refreshLiveQuiet() async {
    if (!AppConfig.useLiveOrdersApi || MockSession.authToken.isEmpty) return;
    if (o.liveAcceptOrderId == null && o.liveRail == null) return;
    if (_busy || _holdStep != null) return;
    await OrdersRepository.instance.refreshFromLiveApi();
  }

  void _onOrdersUpdated() {
    if (_busy || _holdStep != null) return;
    final id = _order.liveAcceptOrderId;
    if (id == null) return;
    MockOrder? fresh;
    for (final x in MockSession.orders.value) {
      if (x.liveAcceptOrderId == id) {
        fresh = x;
        break;
      }
    }
    if (fresh == null || identical(fresh, _order)) return;
    if (!mounted) return;
    setState(() {
      _order = fresh!;
      if (_track.text.trim().isEmpty && _order.tracking.isNotEmpty) {
        _track.text = _order.tracking;
      }
      if (_otp.text.trim().isEmpty && _order.otp.isNotEmpty) {
        _otp.text = _order.otp;
      }
      if (_last4.text.trim().isEmpty && _order.phoneLast4.isNotEmpty) {
        _last4.text = _order.phoneLast4;
      }
      if (_oid.text.trim().isEmpty && _order.hasStoreOrderId) {
        _oid.text = _order.orderId;
      }
    });
    // Live refresh must not yank scroll to the Payment stage.
  }

  void _beginEdit(int step) {
    _holdStep = step;
    o.editFields[step] = true;
    o.step = step;
    setState(() {});
    // Soft scroll only after user taps Edit — never on open.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEditTarget());
  }

  void _endEditHold() {
    _holdStep = null;
  }

  void _scrollToEditTarget() {
    if (_holdStep == null) return;
    final ctx = _currentKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
    );
  }

  void _onTicketsUpdated() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    MockSession.orders.removeListener(_onOrdersUpdated);
    MockSession.tickets.removeListener(_onTicketsUpdated);
    _pulse.dispose();
    _scroll.dispose();
    _track.dispose();
    _otp.dispose();
    _last4.dispose();
    _oid.dispose();
    super.dispose();
  }

  void _bump() {
    MockSession.updateOrder(o);
    setState(() {});
    // Don't auto-scroll after saves — user stays where they were.
  }

  Future<void> _withBusy(String label, Future<void> Function() fn) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _busyLabel = label;
    });
    try {
      await fn();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = null;
        });
      }
    }
  }

  Future<void> _saveTrackingLive(String tracking, String courier) async {
    final label = MintzerCouriers.normalize(courier);
    try {
      await OrderWritesApi.instance.updateTrackingId(
        authToken: MockSession.authToken,
        acceptOrderId: o.liveAcceptOrderId!,
        trackingId: tracking,
        courier: label,
      );
      o.tracking = tracking;
      o.courier = label;
      o.editFields[1] = false;
      if (o.step < 2) o.step = 2;
      o.liveRail = RailStep.ofd;
      o.nextAction = nextActionLabel(RailStep.ofd);
      _endEditHold();
      _bump();
      // ignore: unawaited_futures
      OrdersRepository.instance.refreshFromLiveApi();
      if (mounted) {
        showMintzerToast(context, S.e('Tracking saved'), kind: MintzerToastKind.success);
      }
    } on AuthApiException catch (e) {
      if (mounted) showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
      rethrow;
    } catch (_) {
      if (mounted) {
        // l10n-missing
        showMintzerToast(context, 'Couldn’t save tracking. Try again.', kind: MintzerToastKind.danger);
      }
      rethrow;
    }
  }

  Future<void> _saveOfdLive(String otp, String last4) async {
    try {
      await OrderWritesApi.instance.updateOutForDelivery(
        authToken: MockSession.authToken,
        acceptOrderId: o.liveAcceptOrderId!,
        deliveryOtp: otp,
        mobileLast4: last4,
      );
      o.otp = otp;
      o.phoneLast4 = last4;
      o.editFields[2] = false;
      // OTP saved → Confirmation wait until admin marks Delivered.
      o.step = 3;
      o.liveRail = RailStep.confirmation;
      o.nextAction = nextActionLabel(RailStep.confirmation);
      _endEditHold();
      _bump();
      // ignore: unawaited_futures
      OrdersRepository.instance.refreshFromLiveApi();
      if (mounted) {
        showMintzerToast(context, S.e('Delivery details saved'), kind: MintzerToastKind.success);
      }
    } on AuthApiException catch (e) {
      if (mounted) showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
      rethrow;
    } catch (_) {
      if (mounted) {
        // l10n-missing
        showMintzerToast(context, 'Couldn’t save OTP. Try again.', kind: MintzerToastKind.danger);
      }
      rethrow;
    }
  }

  static const _maxInvoiceBytes = 10 * 1024 * 1024;

  Future<File?> _pickInvoiceFile() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                o.deal.isInstantLink
                    ? S.e('Upload payment screenshot')
                    : S.t('upload_inv'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              // l10n-missing
              subtitle: const Text('JPG, PNG or PDF · max 10 MB', style: TextStyle(fontSize: 12)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: MintzerColors.primary),
              title: Text(S.e('Take photo'), style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(c, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: MintzerColors.primary),
              // l10n-missing
              title: const Text('Choose photo', style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(c, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: MintzerColors.primary),
              title: Text(S.e('Choose PDF'), style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(c, 'pdf'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return null;

    if (choice == 'camera' || choice == 'gallery') {
      try {
        final picker = ImagePicker();
        final x = await picker.pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 62,
          maxWidth: 1600,
        );
        if (x == null) return null;
        return File(x.path);
      } on PlatformException {
        if (mounted) {
          showMintzerToast(
            context,
            choice == 'camera'
                ? S.e('Camera permission is needed to take a photo')
                // l10n-missing
                : 'Couldn’t open photos',
            kind: MintzerToastKind.warn,
          );
        }
        return null;
      }
    }

    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (!mounted) return null;
    if (files.isEmpty) return null;
    final path = files.first.path;
    if (path == null || path.isEmpty) return null;
    return File(path);
  }

  Future<void> _uploadInvoice() async {
    final file = await _pickInvoiceFile();
    if (file == null || !mounted) return;

    final len = await file.length();
    if (!mounted) return;
    if (len <= 0) {
      showMintzerToast(context, S.e('Couldn’t read that file'), kind: MintzerToastKind.warn);
      return;
    }
    if (len > _maxInvoiceBytes) {
      // l10n-missing
      showMintzerToast(context, 'File too large · max 10 MB', kind: MintzerToastKind.warn);
      return;
    }

    final lower = file.path.toLowerCase();
    final okExt = lower.endsWith('.pdf') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
    if (!okExt) {
      showMintzerToast(context, S.e('Use JPG, PNG or PDF'), kind: MintzerToastKind.warn);
      return;
    }

    final gst = o.deal.gst;
    // l10n-missing
    await _withBusy(gst ? 'Uploading GST invoice…' : 'Uploading invoice…', () async {
      if (_useLiveWrites) {
        try {
          await OrderWritesApi.instance.updateInvoiceDelivery(
            authToken: MockSession.authToken,
            acceptOrderId: o.liveAcceptOrderId!,
            file: file,
          );
          o.invoiceStatus = 'verifying';
          o.invoiceRejectReason = '';
          o.liveRail = RailStep.invoiceVerifying;
          o.nextAction = nextActionLabel(RailStep.invoiceVerifying);
          if (mounted) MintzerToasts.invoiceUploaded(context);
          _bump();
          // ignore: unawaited_futures
          OrdersRepository.instance.refreshFromLiveApi();
        } on AuthApiException catch (e) {
          if (mounted) showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
        } catch (_) {
          if (mounted) {
            showMintzerToast(context, S.e('Couldn’t upload invoice. Try again.'), kind: MintzerToastKind.danger);
          }
        }
        return;
      }
      o.invoiceStatus = 'verifying';
      o.invoiceRejectReason = '';
      if (mounted) MintzerToasts.invoiceUploaded(context);
      _bump();
    });
  }

  /// Guess courier from tracking ID. Empty = unknown (do not invent a default).
  String _detectCourier(String t) => MintzerCouriers.detect(t);

  Future<String?> _pickCourier(String current) async {
    // ignore: unawaited_futures
    LogisticsApi.instance.refreshIntoCouriers();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        final selected = MintzerCouriers.normalize(current);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: const Color(0xFFDADCE0), borderRadius: BorderRadius.circular(2)),
                ),
                 Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(S.e('Select courier'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      // l10n-missing
                      'Pick the partner on your tracking SMS / store app',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9AA0A6)),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.55),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _courierOptions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F3F4)),
                    itemBuilder: (_, i) {
                      final c = _courierOptions[i];
                      final on = c == selected;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        leading: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: on ? const Color(0xFFF3EEFF) : const Color(0xFFF7F7F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.local_shipping_rounded,
                            size: 18,
                            color: on ? MintzerColors.primary : const Color(0xFF5F6368),
                          ),
                        ),
                        title: Text(
                          c,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                            color: const Color(0xFF202124),
                          ),
                        ),
                        trailing: on
                            ? const Icon(Icons.check_circle, color: MintzerColors.primary, size: 22)
                            : const Icon(Icons.circle_outlined, color: Color(0xFFDADCE0), size: 22),
                        onTap: () => Navigator.pop(ctx, c),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const _courierOptions = MintzerCouriers.options;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final ticket = MockSession.ticketForMockOrder(o);

    final more = _moreActions;
    return PopScope(
      canPop: !_moreOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _moreOpen) _closeMore();
      },
      child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(S.t('order_detail'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _report,
            child: Text(S.t('report_issue'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          if (o.ongoing)
            IconButton(
              onPressed: () => setState(() => _moreOpen = !_moreOpen),
              icon: const Icon(Icons.more_vert, color: Color(0xFF202124)),
            ),
        ],
      ),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _productHeader(),
          if (canEdit || o.listNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            _noteEntry(),
          ],
          if (o.canceled) ...[
            const SizedBox(height: 12),
            _noteChip(o.note.startsWith('Cancel:') ? o.note.replaceFirst('Cancel: ', '${S.t('canceled')} · ') : S.t('canceled')),
            if (ticket != null) ...[
              const SizedBox(height: 10),
              _ticketBtn(ticket),
            ],
          ] else ...[
            if (ticket != null) ...[
              const SizedBox(height: 10),
              _ticketBtn(ticket),
            ],
            const SizedBox(height: 12),
            _EarnCompact(deal: d),
            if (deliveryCallReady(o) && o.editFields[2] != true) ...[
              const SizedBox(height: 12),
              DeliveryCallCard(order: o, onReschedule: () => _beginEdit(2)),
            ],
            const SizedBox(height: 16),
            for (var i = 0; i < kOrderSteps.length; i++) _stepRow(i),
            if (o.paid) ...[
              const SizedBox(height: 8),
              _paidCard(),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  MockSession.goToWalletTab();
                  Navigator.of(context).popUntil((r) => r.settings.name == '/main');
                },
                child: Text(S.e('View transaction')),
              ),
            ],
          ],
        ],
      ),
        ),
        ),
        if (_moreOpen && o.ongoing && more.isNotEmpty) ...[
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _closeMore(),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + kToolbarHeight + 4,
            right: 8,
            child: _MoreMenu(
              actions: more,
              noteLabel: o.listNote.isEmpty && !o.note.startsWith('Cancel:') ? S.t('add_note') : S.t('edit_note'),
              onPick: _pickMore,
            ),
          ),
        ],
      ],
      ),
    );
  }

  Widget _productHeader() {
    final status = o.canceled
        ? (S.t('canceled'), const Color(0xFF5F6368), const Color(0xFFF1F3F4))
        : o.paid
            ? (S.t('paid'), const Color(0xFF188038), const Color(0xFFE6F4EA))
            : (
                _stepName(o.step.clamp(0, kOrderSteps.length - 1)),
                MintzerColors.primary,
                const Color(0xFFF3EEFF),
              );
    // l10n-missing
    final storeId = o.hasStoreOrderId ? o.orderId : 'Order ID pending';
    // l10n-missing
    final storeIdLabel = '${d.storeLabel} order id';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductThumb(deal: d, size: 72, radius: 12, padding: 6),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            d.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF202124),
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status.$3,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.$1,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: status.$2,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        BrandMark(size: 18, asset: d.storeLogo, letter: d.storeLabel),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            d.storeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3C4043)),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text('·', style: TextStyle(color: Color(0xFFDADCE0), fontWeight: FontWeight.w800)),
                        ),
                        BrandMark(
                          size: 18,
                          asset: d.cardLogo,
                          anyCard: d.cardId == 'any',
                          letter: d.cardLabel,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            d.homeCardLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _orderedMetaLine(),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6), height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _idTile(
                    label: S.e('Mintzer order id'),
                    value: o.mintzerId,
                    primary: true,
                  ),
                ),
                Container(width: 1, height: 36, color: const Color(0xFFE8EAED)),
                const SizedBox(width: 12),
                Expanded(
                  child: _idTile(label: storeIdLabel, value: storeId, primary: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _idTile({required String label, required String value, required bool primary}) {
    final copyable = value != '—' && value != 'Order ID pending';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9AA0A6), height: 1.2),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: copyable ? const Color(0xFF202124) : const Color(0xFF9AA0A6),
                  height: 1.2,
                ),
              ),
            ),
            if (copyable)
              InkWell(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (!mounted) return;
                  if (primary) {
                    MintzerToasts.orderIdCopied(context);
                  } else {
                    showMintzerToast(
                      context,
                      S.e('Order ID copied'),
                      kind: MintzerToastKind.info,
                      icon: Icons.description_outlined,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.copy_rounded, size: 14, color: MintzerColors.primary),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) {
     final m = [S.e('Jan'), S.e('Feb'), S.e('Mar'), S.e('Apr'), S.e('May'), S.e('Jun'), S.e('Jul'), S.e('Aug'), S.e('Sep'), S.e('Oct'), S.e('Nov'), S.e('Dec')];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  String _orderedMetaLine() {
    final variant = d.variant.trim();
    final color = d.color.trim();
    final date = _fmtDate(o.created);
    final bits = <String>[
      if (color.isNotEmpty) color,
      if (variant.isNotEmpty && variant != color) variant,
    ];
    final left = bits.isEmpty ? S.e('Any variant') : bits.join(' · ');
    // l10n-missing
    return '$left · Ordered on $date';
  }

  Widget _noteEntry() {
    final note = o.listNote;
    if (note.isEmpty) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: canEdit ? _addNote : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.sticky_note_2_outlined, size: 18, color: MintzerColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.t('add_note'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      Text(
                        S.t('note_p'),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368), height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canEdit ? _addNote : null,
        borderRadius: BorderRadius.circular(8),
        child: _noteChip(note),
      ),
    );
  }

  Widget _noteChip(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '📝 $text',
        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF5F6368), height: 1.3),
      ),
    );
  }

  Widget _ticketBtn(MockTicket ticket) {
    final face = ticket.inboxFace;
    final unread = ticket.unread == true;
    final preview = ticket.previewLine;
    final pillBg = switch (face) {
      TicketInboxFace.resolved => const Color(0xFFE6F4EA),
      TicketInboxFace.supportReplied || TicketInboxFace.yourReplyNeeded => const Color(0xFFFEF7E0),
      TicketInboxFace.waitingForSupport => const Color(0xFFEDE7FF),
    };
    final pillFg = switch (face) {
      TicketInboxFace.resolved => const Color(0xFF188038),
      TicketInboxFace.supportReplied || TicketInboxFace.yourReplyNeeded => const Color(0xFFE37400),
      TicketInboxFace.waitingForSupport => MintzerColors.primary,
    };
    final statusLabel = switch (face) {
      TicketInboxFace.waitingForSupport => S.e('Open'),
      // l10n-missing
      TicketInboxFace.supportReplied => 'Support replied',
      // l10n-missing
      TicketInboxFace.yourReplyNeeded => 'Your reply',
      TicketInboxFace.resolved => S.t('st_resolved'),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => TicketDetailScreen(ticket: ticket)))
              .then((_) {
            if (mounted) setState(() {});
          });
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: unread ? const Color(0xFFF7F4FF) : Colors.white,
            border: Border.all(color: unread ? const Color(0xFFD6CBFF) : const Color(0xFFE8EAED)),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ticket.shortNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: MintzerColors.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              // l10n-missing
                              'Ticket ${ticket.shortNumber}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF202124),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              statusLabel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: pillFg),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ticket.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), fontWeight: FontWeight.w500),
                      ),
                      if (preview != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6), height: 1.25),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA0A6)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepRow(int i) {
    final paidDone = o.paid;
    final done = i < o.step || (paidDone && (i <= o.step || i == 6));
    final current = !paidDone && !o.canceled && i == o.step;
    final color = paidDone ? const Color(0xFF188038) : MintzerColors.primary;

    if (!current) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  _dot(i, done: done, current: false, paidDone: paidDone, color: color, small: true),
                  if (i < kOrderSteps.length - 1)
                    Container(
                      width: 2,
                      height: 12,
                      margin: const EdgeInsets.only(top: 2),
                      color: done ? color.withValues(alpha: 0.45) : const Color(0xFFE8EAED),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1, bottom: 6),
                child: done
                    ? _collapsedDone(i)
                    : Text(
                        _stepName(i),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF9AA0A6)),
                      ),
              ),
            ),
          ],
        ),
      );
    }

    return KeyedSubtree(
      // Only attach GlobalKey while user is editing — attaching it to Payment on
      // open made Flutter jump scroll to keep the key visible.
      key: _holdStep == i ? _currentKey : ValueKey('step-$i'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  _dot(i, done: false, current: true, paidDone: paidDone, color: color, small: false),
                  if (i < kOrderSteps.length - 1)
                    Container(
                      width: 3,
                      height: 48,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(99)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF7B61FF), Color(0xFFDDD4FF), Color(0xFFE8EAED)],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MintzerColors.primary.withValues(alpha: 0.22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stepName(i),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MintzerColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(_currentHint(i), style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368), height: 1.35)),
                    const SizedBox(height: 10),
                    _currentBody(i),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _currentHint(int i) {
    return switch (i) {
      0 => S.e('Add tracking details once the order ships.'),
      // l10n-missing
      1 => 'Paste tracking — pick courier or let ID detect it.',
      // l10n-missing
      2 => 'Enter last 4 digits of delivery number and Delivery OTP.',
      3 => S.t('working_day'),
      4 => o.invoiceStatus == 'verifying'
          ? (o.deal.isInstantLink
              // l10n-missing
              ? 'Verifying payment screenshot… usually within 1 working day.'
              : (o.deal.gst
                  ? S.e('Verifying GST invoice… usually within 1 working day.')
                  // l10n-missing
                  : 'Invoice under review — usually within 1 working day.'))
          : o.invoiceStatus == 'rejected'
              // l10n-missing
              ? 'Fix the issue below, then re-upload. Your deal stays open.'
              : o.deal.isInstantLink
                  // l10n-missing
                  ? 'Upload the payment screenshot from Instant checkout.'
                  : o.deal.gst
                      ? S.e('Upload the GST invoice from the store to continue.')
                      : S.t('desc4'),
      // l10n-missing
      5 => 'Usually within 48 working hours · bank holidays don’t count.',
      _ => S.t('desc6'),
    };
  }

  Widget _collapsedDone(int i) {
    final summary = switch (i) {
      0 => _fmtDate(o.created),
      1 => o.tracking.isEmpty
          ? S.e('Tracking saved')
          : o.tracking,
      2 => S.e('Delivery details added ✓'),
      // l10n-missing
      3 => 'Confirmed',
      4 => o.invoiceStatus == 'verified'
          ? (o.deal.gst
              // l10n-missing
              ? 'GST invoice verified ✓'
              : S.t('inv_ok'))
          : S.e('Invoice uploaded'),
      // l10n-missing
      5 => 'Payout sent',
      6 => S.t('paid'),
      _ => '',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${_stepName(i)} ✓',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: o.paid ? const Color(0xFF188038) : const Color(0xFF5F6368),
              ),
            ),
            if (i <= 2 && canEdit) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _beginEdit(i),
                child: Text(
                  S.e('Edit'),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: MintzerColors.primary),
                ),
              ),
            ],
          ],
        ),
        if (summary.isNotEmpty)
          Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6)),
          ),
      ],
    );
  }

  Widget _dot(int i, {required bool done, required bool current, required bool paidDone, required Color color, required bool small}) {
    final size = current ? 24.0 : (small ? 16.0 : 20.0);
    final iconSize = current ? 13.0 : (small ? 9.0 : 11.0);

    if (done) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: paidDone ? 1 : 0.85), shape: BoxShape.circle),
        child: Icon(Icons.check, size: iconSize, color: Colors.white),
      );
    }
    if (current) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = _pulse.value;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              shape: BoxShape.circle,
              border: Border.all(color: MintzerColors.primary, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: MintzerColors.primary.withValues(alpha: 0.18 - t * 0.1),
                  blurRadius: 0,
                  spreadRadius: 3 + t * 3.5,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Icon(_stepIcons[i], size: iconSize, color: MintzerColors.primary),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDADCE0), width: 1.5),
      ),
      child: Icon(_stepIcons[i], size: iconSize, color: const Color(0xFFB0B3B8)),
    );
  }

  Widget _currentBody(int i) {
    if (_busy) {
      return Row(
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 10),
          Text(
            _busyLabel ?? S.e('Saving…'), style:  TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      );
    }

    if (i == 0) {
      final editing = o.editFields[0] == true;
      if (editing) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _oid,
              onTap: () => _holdStep ??= 0,
              decoration: InputDecoration(labelText: S.t('order_id'), isDense: true, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            _cta(S.t('save_oid'), () => _withBusy('Saving…', () async {
              final v = _oid.text.trim();
              if (v.isEmpty) {
                MintzerToasts.fieldNeeded(context, S.e('Enter Order ID'));
                return;
              }
              if (_useLiveWrites) {
                try {
                  await PlacementsApi.instance.updateOrderId(
                    authToken: MockSession.authToken,
                    acceptOrderId: o.liveAcceptOrderId!,
                    storeOrderId: v,
                  );
                  o.orderId = v;
                  o.editFields[0] = false;
                  if (o.step < 1) o.step = 1;
                  _endEditHold();
                  _bump();
                  // ignore: unawaited_futures
                  OrdersRepository.instance.refreshFromLiveApi();
                  if (mounted) {
                    showMintzerToast(context, S.e('Order ID saved'), kind: MintzerToastKind.success);
                  }
                } on AuthApiException catch (e) {
                  if (mounted) {
                    showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
                  }
                } catch (_) {
                  if (mounted) {
                    showMintzerToast(
                      context,
                      S.e('Couldn’t save Order ID. Try again.'),
                      kind: MintzerToastKind.danger,
                    );
                  }
                }
                return;
              }
              o.orderId = v;
              o.editFields[0] = false;
              if (o.step < 1) o.step = 1;
              _endEditHold();
              _bump();
            })),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _savedInline(S.t('order_id'), o.orderId, onEdit: canEdit ? () => _beginEdit(0) : null),
          const SizedBox(height: 10),
          _cta(S.e('Continue to tracking'), () async {
            _endEditHold();
            o.step = 1;
            _bump();
          }),
        ],
      );
    }

    if (i == 1) {
      final normalized = MintzerCouriers.normalize(o.courier);
      final known = _courierOptions.contains(normalized) ? normalized : null;
      final courierLabel = known ?? (normalized.isEmpty ? '' : normalized);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.t('courier'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368)),
          ),
          const SizedBox(height: 6),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE8EAED)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                _holdStep ??= 1;
                final picked = await _pickCourier(courierLabel);
                if (picked != null && mounted) {
                  setState(() => o.courier = picked);
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EEFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_shipping_outlined, size: 20, color: MintzerColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courierLabel.isEmpty ? S.e('Select courier') : courierLabel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: courierLabel.isEmpty ? const Color(0xFF9AA0A6) : const Color(0xFF202124),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            courierLabel.isEmpty
                                ? S.e('Required · auto-fills from tracking ID when possible')
                                // l10n-missing
                                : 'Tap to change',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF5F6368)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _track,
            onTap: () => _holdStep ??= 1,
            onChanged: (v) {
              _holdStep ??= 1;
              final detected = _detectCourier(v);
              if (detected.isNotEmpty && detected != o.courier) {
                setState(() => o.courier = detected);
              }
            },
            decoration: InputDecoration(
              labelText: S.t('tracking_id'),
              hintText: S.e('Paste tracking ID from SMS / store'),
              hintStyle: const TextStyle(color: Color(0xFF9AA0A6), fontWeight: FontWeight.w400),
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            S.e('Courier fills in when the ID looks like Ekart / Blue Dart / Xpressbees. Change if wrong.'),
            style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6), height: 1.35),
          ),
          const SizedBox(height: 10),
          _cta(S.t('save_tracking'), () => _withBusy('Saving…', () async {
            final t = _track.text.trim();
            if (t.isEmpty) {
              MintzerToasts.fieldNeeded(context, S.e('Enter tracking ID'));
              return;
            }
            final detected = _detectCourier(t);
            if (detected.isNotEmpty) {
              o.courier = detected;
            }
            o.courier = MintzerCouriers.normalize(o.courier);
            if (o.courier.isEmpty) {
              // l10n-missing
              MintzerToasts.fieldNeeded(context, 'Select a courier');
              return;
            }
            if (_useLiveWrites) {
              try {
                await _saveTrackingLive(t, o.courier);
                _endEditHold();
              } catch (_) {}
              return;
            }
            o.tracking = t;
            o.editFields[1] = false;
            if (o.step < 2) o.step = 2;
            _endEditHold();
            _bump();
          })),
        ],
      );
    }

    if (i == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _last4,
            onTap: () => _holdStep ??= 2,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: S.e('Last 4 digits of delivery number'),
              hintText: S.t('last4_ph'),
              isDense: true,
              border: const OutlineInputBorder(),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _otp,
            onTap: () => _holdStep ??= 2,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: S.t('del_otp'),
              hintText: S.e('6+ digit OTP from courier SMS'),
              hintStyle: const TextStyle(color: Color(0xFF9AA0A6), fontWeight: FontWeight.w400),
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          _cta(S.e('Confirm delivery details'), () => _withBusy('Saving…', () async {
            final last4 = _last4.text.trim();
            final otp = _otp.text.trim();
            if (last4.length != 4) {
              // l10n-missing
              MintzerToasts.fieldNeeded(context, 'Enter last 4 digits');
              return;
            }
            if (otp.length < 4) {
              MintzerToasts.fieldNeeded(context, S.t('snack_need_otp'));
              return;
            }
            if (_useLiveWrites) {
              try {
                await _saveOfdLive(otp, last4);
                _endEditHold();
              } catch (_) {}
              return;
            }
            o.phoneLast4 = last4;
            o.otp = otp;
            o.editFields[2] = false;
            if (o.step < 3) o.step = 3;
            _endEditHold();
            _bump();
          })),
        ],
      );
    }

    if (i == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF7F7FA), borderRadius: BorderRadius.circular(8)),
            child: Text(
              S.e('This may take up to 1 working day.'),
              style: TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35),
            ),
          ),
          if (!_isLive && AppConfig.showSimulateControls) ...[
            const SizedBox(height: 10),
            _ctaOutlined(S.t('sim_delivered'), () async {
              o.step = 4;
              _bump();
            }),
          ],
        ],
      );
    }

    if (i == 4) {
      final gst = o.deal.gst;
      if (o.invoiceStatus == 'verifying') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusPill(
              const Color(0xFFEDE7FF),
              const Color(0xFF5B4BDB),
              gst ? S.e('Verifying GST invoice…') : 'Invoice under review',
            ),
            const SizedBox(height: 8),
            // l10n-missing
            const Text('Usually within 1 working day.', style: TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
            if (!_isLive && AppConfig.showSimulateControls) ...[
              const SizedBox(height: 10),
              _ctaOutlined(S.t('sim_reject'), () async {
                o.invoiceStatus = 'rejected';
                o.invoiceRejectReason = gst
                    ? S.e('GST details don’t match the Company / GST No. on the delivery address.')
                    // l10n-missing
                    : 'Invoice is blurry. Upload a clear image showing the order ID and amount.';
                _bump();
              }),
              const SizedBox(height: 6),
              _ctaOutlined(S.t('sim_approve'), () async {
                o.invoiceStatus = 'verified';
                o.step = 5;
                o.paymentTimerSec = 48 * 3600;
                if (o.cheerVisit < 1) o.cheerVisit = 1;
                _bump();
              }),
            ],
          ],
        );
      }
      if (o.invoiceStatus == 'rejected') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusPill(const Color(0xFFFCE8E6), const Color(0xFFD93025), S.t('inv_not')),
            const SizedBox(height: 8),
            Text(
              o.invoiceRejectReason.isEmpty
                  ? S.e('Invoice couldn’t be verified. Re-upload a corrected file.')
                  : o.invoiceRejectReason,
              style: const TextStyle(fontSize: 12, color: Color(0xFFD93025), height: 1.35),
            ),
            const SizedBox(height: 6),
            const Text(
              // l10n-missing
              'You can re-upload a corrected invoice — this deal stays open.',
              style: TextStyle(fontSize: 11, color: Color(0xFF5F6368), height: 1.35),
            ),
            const SizedBox(height: 10),
            _cta(
              gst
                  ? S.e('Re-upload GST invoice')
                  : (o.deal.isInstantLink
                      // l10n-missing
                      ? 'Re-upload screenshot'
                      : S.t('reupload_inv')),
              _uploadInvoice,
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (gst) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: MintzerColors.gstFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MintzerColors.gstBorder),
              ),
              child:  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.e('Before uploading'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: MintzerColors.gstText)),
                  SizedBox(height: 6),
                  // l10n-missing
                  Text('✓ Company & GST No. match the delivery address', style: TextStyle(fontSize: 11, color: Color(0xFF00796B), height: 1.35)),
                  // l10n-missing
                  Text('✓ Order ID, seller, product & amount visible', style: TextStyle(fontSize: 11, color: Color(0xFF00796B), height: 1.35)),
                  Text(S.e('✓ Invoice is clear (JPG, PNG or PDF)'), style: TextStyle(fontSize: 11, color: Color(0xFF00796B), height: 1.35)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ] else
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              // l10n-missing
              child: Text('JPG, PNG or PDF · max 10 MB', style: TextStyle(fontSize: 11, color: Color(0xFF9AA0A6))),
            ),
          _cta(
            gst
                ? S.e('Upload GST invoice')
                : (o.deal.isInstantLink
                    ? S.e('Upload payment screenshot')
                    : S.t('upload_inv')),
            _uploadInvoice,
            icon: Icons.upload_rounded,
          ),
        ],
      );
    }

    if (i == 5) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soft info card — matches collage Payment stage (not a countdown).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD6E0FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.t(_cheer), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5B4BDB))),
                const SizedBox(height: 6),
                // l10n-missing
                const Text('Payout on the way', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF202124))),
                if (_fromMintzer > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    // l10n-missing
                    'From Mintzer ${formatInr(_fromMintzer)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
                  ),
                  const SizedBox(height: 2),
                  // l10n-missing
                  const Text(
                    'Bank transfer to your payout account',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                  ),
                ],
                if (d.cashback > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    // l10n-missing
                    'Bank cashback ${formatInr(d.cashback)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF202124)),
                  ),
                  const SizedBox(height: 2),
                  // l10n-missing
                  const Text(
                    'Credited to your card/account according to the bank statements.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                  ),
                ],
                if (d.earn > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    // l10n-missing
                    'Your earnings ${formatInr(d.earn)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF188038)),
                  ),
                ],
                if (_bankLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    // l10n-missing
                    'to $_bankLabel',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368)),
                  ),
                ],
                const SizedBox(height: 6),
                const Text(
                  // l10n-missing
                  'Usually within 48 working hours · bank holidays don’t count',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5B4BDB)),
                ),
              ],
            ),
          ),
          if (!_isLive && AppConfig.showSimulateControls) ...[
            const SizedBox(height: 10),
            _ctaOutlined(S.t('sim_paid'), () async {
              o.paid = true;
              o.step = 6;
              o.invoiceStatus = 'verified';
              o.bankName = o.bankName.isEmpty ? MockSession.bankName : o.bankName;
              o.accountLast4 = o.accountLast4.isEmpty
                  ? (MockSession.bankAccount.length >= 4
                      ? MockSession.bankAccount.substring(MockSession.bankAccount.length - 4)
                      : '')
                  : o.accountLast4;
              o.utr = o.utr.isEmpty ? 'UTR${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}' : o.utr;
              o.paidOn ??= DateTime.now();
              _bump();
              await PlayInAppReview.maybeAskAfterPayout(context);
            }),
          ],
        ],
      );
    }

    if (i == 6 && o.paid) return _paidCard();
    return const SizedBox.shrink();
  }

  Widget _paidCard() {
    // Date only — never phone clock. Hide until API / simulate sets paidOn.
    final paidOn = o.paidOn;
    final paidOnLabel = paidOn == null ? null : _fmtDate(paidOn);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCEEAD6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_fromMintzer > 0) ...[
            _moneyLine(
              title: S.t('from_mz'),
              // l10n-missing
              sub: 'Credited to your bank',
              value: formatInr(_fromMintzer),
              emphasize: true,
            ),
          ],
          if (d.cashback > 0) ...[
            const SizedBox(height: 8),
            _moneyLine(
              title: S.e('Bank cashback'),
              // l10n-missing — locked deal money footer wording
              sub: 'Credited to your card/account according to the bank statements.',
              value: formatInr(d.cashback),
            ),
          ],
          if (d.earn > 0) ...[
            const SizedBox(height: 8),
            Text(
              // l10n-missing
              'Your earnings ${formatInr(d.earn)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF188038)),
            ),
          ],
          if (_bankLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            _kv(S.t('account'), _bankLabel),
          ],
          const SizedBox(height: 4),
          _kv(S.t('utr'), o.utr.isEmpty ? S.t('utr_pending') : o.utr),
          if (paidOnLabel != null) ...[
            const SizedBox(height: 4),
            _kv(S.e('Paid on'), paidOnLabel),
          ],
        ],
      ),
    );
  }

  Widget _moneyLine({
    required String title,
    required String sub,
    required String value,
    bool emphasize = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: emphasize ? const Color(0xFFCEEAD6) : const Color(0xFFE8EAED)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF202124))),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasize ? 16 : 14,
              fontWeight: FontWeight.w900,
              color: emphasize ? const Color(0xFF188038) : const Color(0xFF202124),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 64, child: Text(k, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)))),
        Expanded(
          child: Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF188038))),
        ),
      ],
    );
  }

  Widget _savedInline(String label, String value, {VoidCallback? onEdit}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (onEdit != null)
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              S.e('Edit'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _statusPill(Color bg, Color fg, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _cta(String label, Future<void> Function() onTap, {IconData? icon}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 160, maxWidth: 280),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy ? null : () => onTap(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ctaOutlined(String label, Future<void> Function() onTap) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 160, maxWidth: 280),
        child: SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: _busy ? null : () => onTap(),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Future<void> _report() async {
    final existing = MockSession.ticketForMockOrder(o);
    if (existing != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TicketDetailScreen(ticket: existing)),
      );
      if (mounted) setState(() {});
      return;
    }
    final t = await showRaiseTicketSheet(context, o);
    if (t != null && mounted) {
      MintzerToasts.ticketOpened(context, t.id);
      setState(() {});
    }
  }

  void _addNote() async {
    if (!canEdit) {
      showMintzerToast(context, S.e('Order settled'), subtitle: 'No more edits on this order', kind: MintzerToastKind.warn);
      return;
    }
    final initial = o.note.startsWith('Cancel:') ? '' : o.note;
    final saved = await showNoteDialog(context, initial: initial);
    if (saved == null || !mounted) return;
    o.note = saved;
    MockSession.rememberOrderNote(o.id, saved);
    _bump();
  }

  String _cancelLabel(String reason) => switch (reason) {
        'Store canceled' => S.t('o_store'),
        'Marketplace canceled' => S.t('mkt_canceled'),
        'Price higher than deal' => S.t('price_higher'),
        'Out of stock' => S.t('oos'),
        _ => S.e(reason),
      };

  Future<void> _cancel() async {
    final fallback = [
      'Store canceled',
      'Marketplace canceled',
      'Price higher than deal',
      'Out of stock',
      'Changed mind — will not complete order',
    ];
    var reasons = List<String>.from(fallback);
    if (_useLiveWrites) {
      final remote = await OrderWritesApi.instance.fetchCancelReasons(
        authToken: MockSession.authToken,
      );
      if (remote.isNotEmpty) reasons = remote;
    }
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (c) {
        S.watch(c);
        return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(S.t('cancel_this'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            ...reasons.map(
              (r) => ListTile(
                title: Text(_cancelLabel(r)),
                onTap: () async {
                  Navigator.pop(c);
                  await _confirmCancel(r);
                },
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(c), child: Text(S.t('keep_order'))),
          ],
        ),
      );
      },
    );
  }

  Future<void> _confirmCancel(String reason) async {
    if (_useLiveWrites) {
      await _withBusy(
        S.e('Canceling…'),
        () async {
        try {
          await OrderWritesApi.instance.cancelOrder(
            authToken: MockSession.authToken,
            acceptOrderId: o.liveAcceptOrderId!,
            reason: reason,
          );
          MockSession.cancelOrder(o, reason);
          // ignore: unawaited_futures
          OrdersRepository.instance.refreshFromLiveApi();
          if (!mounted) return;
          showMintzerToast(context, S.t('snack_ocancel'), kind: MintzerToastKind.warn, icon: Icons.cancel_outlined);
          Navigator.of(context).pop();
        } on AuthApiException catch (e) {
          // Already soft-deleted / cancelled on server — finish locally.
          final gone = e.statusCode == 404 ||
              e.message.toLowerCase().contains('order not found') ||
              e.message.toLowerCase().contains('already be cancelled') ||
              e.message.toLowerCase().contains('already be canceled');
          if (gone) {
            MockSession.cancelOrder(o, reason);
            // ignore: unawaited_futures
            OrdersRepository.instance.refreshFromLiveApi();
            if (!mounted) return;
            showMintzerToast(context, S.t('snack_ocancel'), kind: MintzerToastKind.warn, icon: Icons.cancel_outlined);
            Navigator.of(context).pop();
          } else if (mounted) {
            showMintzerToast(context, e.message, kind: MintzerToastKind.danger);
          }
        } catch (_) {
          if (mounted) {
            showMintzerToast(context, S.e('Couldn’t cancel. Try again.'), kind: MintzerToastKind.danger);
          }
        }
      });
      return;
    }
    MockSession.cancelOrder(o, reason);
    setState(() {});
    showMintzerToast(context, S.t('snack_ocancel'), kind: MintzerToastKind.warn, icon: Icons.cancel_outlined);
    Navigator.of(context).pop();
  }
}

enum _MoreAction { note, cancel }

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.actions,
    required this.noteLabel,
    required this.onPick,
  });

  final List<_MoreAction> actions;
  final String noteLabel;
  final ValueChanged<_MoreAction> onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 188),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < actions.length; i++)
              InkWell(
                onTap: () => onPick(actions[i]),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, i == 0 ? 12 : 10, 16, i == actions.length - 1 ? 12 : 10),
                  child: Text(
                    actions[i] == _MoreAction.cancel ? S.e('Cancel order') : noteLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: actions[i] == _MoreAction.cancel ? const Color(0xFFD93025) : const Color(0xFF202124),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EarnCompact extends StatelessWidget {
  const _EarnCompact({required this.deal});
  final MockDeal deal;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final d = deal;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.e('EARNINGS'),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF5F6368), letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _cell(S.t('you_pay'), formatInr(d.spend))),
              Expanded(child: _cell(S.t('card_cb'), formatInr(d.cashback))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _cell(S.t('from_mz'), formatInr(d.walletFromMintzer))),
              Expanded(child: _cell(S.t('commission'), formatInr(d.commission), valueColor: MintzerColors.earnGreen)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Text(S.t('you_earn'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF188038))),
                const Spacer(),
                Text(formatInr(d.earn), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF188038))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF5F6368))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? const Color(0xFF202124))),
        ],
      ),
    );
  }
}
