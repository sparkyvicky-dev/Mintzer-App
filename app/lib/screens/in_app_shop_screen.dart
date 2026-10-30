import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../mock/session.dart';
import '../mock/session_store.dart';
import '../models/deal.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../util/shop_url.dart';
import '../widgets/mintzer_toast.dart';
import '../widgets/product_thumb.dart';

/// In-app store browser + Mintzer assist sheet (Deal · Delivery · Order ID).
/// Collapsed = max WebView. Expanded = copy address / paste Order ID without leaving Mintzer.
class InAppShopScreen extends StatefulWidget {
  const InAppShopScreen({
    super.key,
    required this.url,
    required this.deal,
    required this.addressRows,
    required this.onChangeAddress,
    required this.onConfirmOrderId,
    this.onRequestCancel,
    this.onExpired,
    this.onShopModeChanged,
  });

  final String url;
  final MockDeal deal;
  final List<({String label, String value, bool copyable})> addressRows;
  final VoidCallback onChangeAddress;

  /// Returns `true` when Order ID was accepted (live or mock). Screen pops on success.
  final Future<bool> Function(String storeOrderId) onConfirmOrderId;

  /// Parent clears placement + pops Place order. Call after closing this route.
  final VoidCallback? onRequestCancel;

  /// Parent runs same expiry path as Place order.
  final VoidCallback? onExpired;

  final VoidCallback? onShopModeChanged;

  @override
  State<InAppShopScreen> createState() => _InAppShopScreenState();
}

class _InAppShopScreenState extends State<InAppShopScreen> {
  late final WebViewController _controller;
  final _oid = TextEditingController();
  var _loading = true;
  var _sheetUp = false;
  var _tab = 0; // 0 Deal · 1 Delivery · 2 Order ID
  var _submitting = false;
  var _expiryFired = false;
  int _sec = 0;
  Timer? _tick;

  MockDeal get d => widget.deal;

  @override
  void initState() {
    super.initState();
    _sec = MockSession.placementSecLeft;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = MockSession.placementSecLeft;
      setState(() => _sec = left);
      if (left <= 0 && !_expiryFired && MockSession.placementEndsAt != null) {
        _expiryFired = true;
        widget.onExpired?.call();
        if (mounted) Navigator.of(context).pop();
      }
    });
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            switch (classifyShopNavigation(request.url)) {
              case ShopNavigation.allowPage:
                return NavigationDecision.navigate;
              case ShopNavigation.openOutside:
                final uri = Uri.tryParse(request.url);
                if (uri != null) {
                  unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
                }
                return NavigationDecision.prevent;
              case ShopNavigation.block:
                return NavigationDecision.prevent;
            }
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              showMintzerToast(context, 'Page failed to load', kind: MintzerToastKind.warn);
            }
          },
        ),
      );
    if (classifyShopNavigation(widget.url) == ShopNavigation.allowPage) {
      _controller.loadRequest(Uri.parse(widget.url));
    } else {
      _loading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showMintzerToast(context, 'This store link can’t be opened', kind: MintzerToastKind.warn);
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _oid.dispose();
    super.dispose();
  }

  String get _clock {
    final m = (_sec ~/ 60).toString().padLeft(2, '0');
    final s = (_sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _danger => _sec > 0 && _sec < 120;
  bool get _expired => _sec <= 0;

  bool get _oidOk {
    final t = _oid.text.trim();
    return t.length >= 8 && RegExp(r'^[A-Za-z0-9\-]{8,}$').hasMatch(t);
  }

  Future<void> _copy(String v) async {
    await Clipboard.setData(ClipboardData(text: v));
    if (!mounted) return;
    MintzerToasts.copied(context);
  }

  Future<void> _copyAll() async {
    final lines = <String>[
      for (final r in widget.addressRows)
        if (r.copyable && r.value.trim().isNotEmpty) '${r.label}: ${r.value.trim()}',
    ];
    if (lines.isEmpty) {
      showMintzerToast(context, 'Nothing to copy', kind: MintzerToastKind.warn);
      return;
    }
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    MintzerToasts.deliveryCopied(context, gst: d.gst);
  }

  Future<void> _pasteOid({bool force = false}) async {
    if (!force && _oid.text.trim().isNotEmpty) return;
    final data = await Clipboard.getData('text/plain');
    final t = (data?.text ?? '').trim().replaceAll(RegExp(r'\s+'), '');
    if (t.isEmpty) {
      if (!mounted) return;
      showMintzerToast(
        context,
        'Nothing to paste',
        subtitle: 'Copy the Order ID from ${d.storeLabel} first',
        kind: MintzerToastKind.warn,
        icon: Icons.content_paste_off_rounded,
      );
      return;
    }
    setState(() => _oid.text = t);
    if (!mounted) return;
    showMintzerToast(context, 'Pasted', kind: MintzerToastKind.info, icon: Icons.content_paste_rounded);
  }

  Future<void> _confirm() async {
    if (_submitting || _expired) {
      if (_expired) MintzerToasts.timerExpired(context);
      return;
    }
    final oid = _oid.text.trim();
    if (!_oidOk) {
      showMintzerToast(context, 'Enter a valid ${d.storeLabel} Order ID', kind: MintzerToastKind.warn);
      return;
    }
    setState(() => _submitting = true);
    try {
      final ok = await widget.onConfirmOrderId(oid);
      // Parent navigates to success on ok — do not pop here.
      if (!ok && mounted) setState(() => _submitting = false);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openSheet({int? tab}) {
    setState(() {
      _sheetUp = true;
      if (tab != null) _tab = tab;
    });
  }

  void _closeSheet() => setState(() => _sheetUp = false);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Place order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          if (widget.onRequestCancel != null)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                widget.onRequestCancel?.call();
              },
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFD93025))),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _danger || _expired ? const Color(0xFFFCE8E6) : const Color(0xFFFEF7E0),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: _danger || _expired ? const Color(0xFFD93025) : const Color(0xFFE37400),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expired ? '0:00' : _clock,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: _danger || _expired ? const Color(0xFFD93025) : const Color(0xFFE37400),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF5F6368)),
            onSelected: (v) {
              if (v == 'external') {
                MockSession.shopMode = 'external';
                // ignore: unawaited_futures
                SessionStore.save();
                Navigator.of(context).pop();
                widget.onShopModeChanged?.call();
                showMintzerToast(context, 'Switched to store app', kind: MintzerToastKind.info);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'external', child: Text('Open in store app instead')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView fills; sheet overlays bottom
          Positioned.fill(
            child: Column(
              children: [
                if (_loading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: MintzerColors.primary,
                    backgroundColor: Color(0xFFEDE7FF),
                  ),
                Expanded(
                  flex: _sheetUp ? 38 : 100,
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_sheetUp)
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(color: Color(0x38000000)),
                          ),
                        ),
                    ],
                  ),
                ),
                // Spacer for sheet height so webview shrinks
                if (_sheetUp) const Expanded(flex: 62, child: SizedBox.shrink()),
                if (!_sheetUp) SizedBox(height: 132 + bottom),
              ],
            ),
          ),

          // Assist sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              height: _sheetUp ? MediaQuery.sizeOf(context).height * 0.58 : (132 + bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(color: Color(0x29000000), blurRadius: 24, offset: Offset(0, -6)),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDADCE0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  if (!_sheetUp) ...[
                    _peek(bottom),
                    _collapsedDock(),
                    SizedBox(height: bottom > 0 ? bottom : 4),
                  ] else ...[
                    _sheetHeader(),
                    _tabs(),
                    Expanded(child: _tabBody()),
                    SizedBox(height: bottom > 0 ? bottom : 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _peek(double bottom) {
    return InkWell(
      onTap: () => _openSheet(tab: 1),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You earn after this order',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5F6368)),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatInr(d.earn),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF188038),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'You pay ${formatInr(d.spend)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9AA0A6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Material(
              color: MintzerColors.primary,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: const Color(0x667B61FF),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _openSheet(tab: 1),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _collapsedDock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await _pasteOid(force: true);
                setState(() {});
              },
              child: Container(
                height: 44,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8EAED)),
                ),
                child: Text(
                  _oid.text.trim().isEmpty ? 'Tap to paste Order ID' : _oid.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _oid.text.trim().isEmpty ? const Color(0xFF9AA0A6) : const Color(0xFF202124),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: _oidOk && !_submitting && !_expired ? _confirm : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 10, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text('Order help', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
          IconButton(
            tooltip: 'Back to ${d.storeLabel}',
            onPressed: _closeSheet,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEDE7FF),
              foregroundColor: MintzerColors.primary,
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    const labels = ['Deal', 'Delivery', 'Order ID'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Material(
                color: _tab == i ? Colors.white : const Color(0xFFF8F9FA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                  side: BorderSide(
                    color: _tab == i ? MintzerColors.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => setState(() => _tab = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _tab == i ? MintzerColors.primary : const Color(0xFF5F6368),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabBody() {
    return switch (_tab) {
      0 => _dealPanel(),
      1 => _deliveryPanel(),
      _ => _orderIdPanel(),
    };
  }

  Widget _dealPanel() {
    final bits = <String>[
      if (d.color.trim().isNotEmpty) d.color.trim(),
      if (d.variant.trim().isNotEmpty) d.variant.trim(),
      d.storeLabel,
      d.homeCardLabel,
      'Qty 1',
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductThumb(deal: d, size: 52, radius: 10, padding: 4),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.25)),
                  const SizedBox(height: 4),
                  Text(bits.join(' · '), style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _moneyCell(label: 'You pay', value: formatInr(d.spend), earn: false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _moneyCell(label: 'You earn', value: formatInr(d.earn), earn: true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF7E0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Before you buy',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFE37400)),
              ),
              const SizedBox(height: 4),
              Text(
                d.rules.isNotEmpty
                    ? d.rules.take(3).join(' · ')
                    : 'Exact model · same color/storage · pay with the listed card · no substitutes.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _moneyCell({required String label, required String value, required bool earn}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: earn ? const Color(0xFFE6F4EA) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: earn ? const Color(0xFF188038) : const Color(0xFF5F6368),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: earn ? const Color(0xFF188038) : const Color(0xFF202124),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryPanel() {
    final rows = widget.addressRows;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      children: [
        const Text('Delivery address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          'Copy each line into ${d.storeLabel} checkout above.',
          style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No delivery address for this deal.',
              style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
            ),
          )
        else
          for (final r in rows) _addrRow(r),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            onPressed: rows.isEmpty ? null : _copyAll,
            child: const Text('Copy all address lines', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        TextButton(
          onPressed: widget.onChangeAddress,
          child: const Text('Change address', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _addrRow(({String label, String value, bool copyable}) r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE8EAED))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(
                r.label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9AA0A6)),
              ),
            ),
            Expanded(
              child: Text(
                r.value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.35),
              ),
            ),
            if (r.copyable && r.value.trim().isNotEmpty)
              IconButton(
                onPressed: () => _copy(r.value),
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEDE7FF),
                  foregroundColor: MintzerColors.primary,
                  minimumSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.copy_rounded, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _orderIdPanel() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      children: [
        Text(
          'Submit ${d.storeLabel} Order ID',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'After you place the order on ${d.storeLabel}, paste the Order ID here.',
          style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35),
        ),
        const SizedBox(height: 14),
        Text(
          '${d.storeLabel} order id',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _oid,
          onTap: () => _pasteOid(force: true),
          onChanged: (raw) {
            final cleaned = raw.replaceAll(RegExp(r'\s+'), '');
            if (cleaned != raw) {
              _oid.value = TextEditingValue(
                text: cleaned,
                selection: TextSelection.collapsed(offset: cleaned.length),
              );
            }
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: 'Tap to paste Order ID',
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8EAED)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8EAED)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: MintzerColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'One tap pastes from clipboard when empty',
          style: TextStyle(fontSize: 11, color: Color(0xFF9AA0A6)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _oidOk && !_submitting && !_expired ? _confirm : null,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Confirm order', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}
