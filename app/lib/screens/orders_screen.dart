import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../l10n/s.dart';
import '../live/orders_repository.dart';
import '../mock/session.dart';
import '../models/deal.dart';
import '../models/mock_order.dart';
import '../models/mock_ticket.dart';
import '../theme/app_theme.dart';
import '../util/delivery_call.dart';
import '../util/format.dart';
import '../widgets/delivery_call_card.dart';
import '../widgets/product_thumb.dart';
import '../widgets/mintzer_dialogs.dart';
import '../widgets/mintzer_toast.dart';
import 'order_detail_screen.dart';
import 'place_order_screen.dart';

/// ChatGPT Orders list preview — compact cards, 4-stage line, action-first.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with WidgetsBindingObserver {
  String _tab = 'ongoing';
  final _search = TextEditingController();
  /// `all` | `flipkart` | `amazon`
  String _storeFilter = 'all';
  /// `newest` | `oldest` | `action`
  String _sort = 'newest';
  bool _loadingLive = false;
  bool _loadedOnce = false;
  int _lastTab = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MockSession.orders.addListener(_refresh);
    MockSession.activeDeal.addListener(_refresh);
    MockSession.tabIndex.addListener(_onShellTab);
    _loadLiveOrders();
  }

  void _onShellTab() {
    if (MockSession.tabIndex.value == 1 && _lastTab != 1) {
      // ignore: unawaited_futures
      _loadLiveOrders(silent: _loadedOnce);
    }
    _lastTab = MockSession.tabIndex.value;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && MockSession.tabIndex.value == 1) {
      // ignore: unawaited_futures
      _loadLiveOrders(silent: _loadedOnce);
    }
  }

  Future<void> _loadLiveOrders({bool silent = false}) async {
    if (!AppConfig.useLiveOrdersApi) return;
    final showSpinner = !silent && !_loadedOnce;
    if (showSpinner && mounted) setState(() => _loadingLive = true);
    // Keep last orders visible while refreshing — don't wipe thumbs to blank.

    if (MockSession.authToken.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingLive = false;
          _loadedOnce = true;
        });
        if (!silent) {
          showMintzerToast(
            context,
            S.e('Log in to see your real orders'),
            kind: MintzerToastKind.info,
          );
        }
      }
      return;
    }

    final ok = await OrdersRepository.instance.refreshFromLiveApi();
    if (!mounted) return;
    setState(() {
      _loadingLive = false;
      _loadedOnce = true;
    });
    if (!ok && !silent) {
      showMintzerToast(
        context,
        S.e('Couldn’t load orders. Pull to retry.'),
        kind: MintzerToastKind.warn,
      );
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MockSession.orders.removeListener(_refresh);
    MockSession.activeDeal.removeListener(_refresh);
    MockSession.tabIndex.removeListener(_onShellTab);
    _search.dispose();
    super.dispose();
  }

  bool get _filterActive => _storeFilter != 'all' || _sort != 'newest';

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        var store = _storeFilter;
        var sort = _sort;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            S.watch(ctx);
            Widget chip(String label, bool selected, VoidCallback select) {
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setSheet(select),
                  selectedColor: const Color(0xFFEDE7FF),
                  checkmarkColor: MintzerColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? MintzerColors.primary : const Color(0xFF5F6368),
                  ),
                  side: BorderSide(color: selected ? MintzerColors.primary : const Color(0xFFE8EAED)),
                  backgroundColor: Colors.white,
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.paddingOf(ctx).bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(S.e('Filter & sort'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Text(S.t('store'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
                  const SizedBox(height: 8),
                  Wrap(
                    children: [
                      chip(S.t('all_stores'), store == 'all', () => store = 'all'),
                      chip('Flipkart', store == 'flipkart', () => store = 'flipkart'),
                      chip('Amazon', store == 'amazon', () => store = 'amazon'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(S.e('Sort'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
                  const SizedBox(height: 8),
                  Wrap(
                    children: [
                      chip(S.t('newest_first'), sort == 'newest', () => sort = 'newest'),
                      chip(S.t('oldest_first'), sort == 'oldest', () => sort = 'oldest'),
                      chip(S.t('needs_first'), sort == 'action', () => sort = 'action'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _storeFilter = store;
                        _sort = sort;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(S.t('apply')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<MockOrder> _applyFilters(List<MockOrder> raw) {
    final q = _search.text.trim().toLowerCase();
    var list = raw.where((o) {
      if (_storeFilter != 'all' && o.deal.storeId != _storeFilter) return false;
      if (q.isEmpty) return true;
      return o.orderId.toLowerCase().contains(q) ||
          o.mintzerId.toLowerCase().contains(q) ||
          o.deal.name.toLowerCase().contains(q) ||
          o.tracking.toLowerCase().contains(q) ||
          o.deal.storeLabel.toLowerCase().contains(q) ||
          o.note.toLowerCase().contains(q);
    }).toList();

    int actionRank(MockOrder o) => o.needsUserAction ? 0 : 1;
    list.sort((a, b) {
      if (_sort == 'action') {
        final c = actionRank(a).compareTo(actionRank(b));
        if (c != 0) return c;
      }
      if (_sort == 'oldest') return a.created.compareTo(b.created);
      return b.created.compareTo(a.created);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final all = MockSession.orders.value;
    final acceptId = MockSession.activeAcceptOrderId;
    final placementOrders = all.where((o) => o.ongoing && MockSession.isOpenPlacementOrder(o)).toList();

    bool hideAsDup(MockOrder o) {
      if (MockSession.isOpenPlacementOrder(o)) return true;
      if (acceptId != null && o.liveAcceptOrderId == acceptId) return true;
      return false;
    }

    final ongoing = _applyFilters(all.where((o) => o.ongoing && !hideAsDup(o)).toList());
    final completed = _applyFilters(all.where((o) => o.completed).toList());
    final list = _tab == 'ongoing' ? ongoing : completed;
    final placementDeal = MockSession.activeDeal.value;
    final showPlacement = _tab == 'ongoing' && (placementDeal != null || placementOrders.isNotEmpty);
    final placementCount = showPlacement ? 1 : 0;

    void openPlacement([MockOrder? fromOrder]) {
      if (fromOrder != null) MockSession.resumePlacementFromOrder(fromOrder);
      final deal = MockSession.activeDeal.value ?? fromOrder?.deal ?? placementDeal;
      if (deal == null) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PlaceOrderScreen(deal: deal)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(S.t('my_orders'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF202124))),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: _filterActive ? const Color(0xFFEDE7FF) : const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: _openFilterSheet,
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.tune_rounded,
                    color: MintzerColors.primary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: S.t('search_orders'),
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9AA0A6)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9AA0A6), size: 20),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: MintzerColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Tab(
                  label: S.t('ongoing'),
                  badge: ongoing.length + placementCount,
                  selected: _tab == 'ongoing',
                  onTap: () => setState(() => _tab = 'ongoing'),
                ),
                const SizedBox(width: 20),
                _Tab(
                  label: S.t('completed'),
                  selected: _tab == 'completed',
                  onTap: () => setState(() => _tab = 'completed'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EAED)),
          if (_loadingLive) const LinearProgressIndicator(minHeight: 2, color: MintzerColors.primary),
          Expanded(
            child: RefreshIndicator(
              color: MintzerColors.primary,
              onRefresh: _loadLiveOrders,
              child: list.isEmpty && !showPlacement
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _OrdersEmpty(
                          loading: _loadingLive && !_loadedOnce,
                          filtered: _search.text.trim().isNotEmpty || _filterActive,
                          completed: _tab == 'completed',
                          onBrowse: MockSession.goToHomeTab,
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      children: [
                        if (showPlacement)
                          _PlacementCard(
                            deal: placementDeal ??
                                (placementOrders.isNotEmpty ? placementOrders.first.deal : null),
                            onContinue: () => openPlacement(
                              placementDeal != null
                                  ? null
                                  : (placementOrders.isNotEmpty ? placementOrders.first : null),
                            ),
                          ),
                        ...list.map(
                          (o) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OrderCard(
                              order: o,
                              ticket: MockSession.ticketForMockOrder(o),
                              onMore: o.ongoing
                                  ? () => _openOngoingMenu(context, o)
                                  : null,
                              onOpen: () {
                                if (MockSession.isOpenPlacementOrder(o)) {
                                  openPlacement(o);
                                  return;
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => OrderDetailScreen(order: o),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersEmpty extends StatelessWidget {
  const _OrdersEmpty({
    required this.loading,
    required this.filtered,
    required this.completed,
    required this.onBrowse,
  });

  final bool loading;
  final bool filtered;
  final bool completed;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    if (loading) {
      return  SizedBox(
        height: 240,
        child: Center(
          child: Text(
            S.e('Loading orders…'),
            style: TextStyle(color: MintzerColors.muted),
          ),
        ),
      );
    }
    final title = filtered
        // l10n-missing
        ? 'No orders match'
        : completed
            ? S.t('no_completed')
            // l10n-missing
            : 'No orders yet';
    final sub = filtered
        // l10n-missing
        ? 'Try another search or filter.'
        : completed
            ? S.e('Paid and canceled orders show up here.')
            // l10n-missing
            : 'Accept a deal, place the order, and it lands here.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 72, 28, 24),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFFBDC1C6)),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF202124))),
          const SizedBox(height: 6),
          Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF5F6368))),
          if (!filtered && !completed) ...[
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: MintzerColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onBrowse,
              child: Text(S.e('Browse deals'), style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap, this.badge});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 0),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? MintzerColors.primary : const Color(0xFF5F6368),
                    ),
                  ),
                  if (badge != null && badge! > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: MintzerColors.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 2.5,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: selected ? MintzerColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlacementCard extends StatelessWidget {
  const _PlacementCard({required this.deal, required this.onContinue});
  final MockDeal? deal;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final d = deal;
    if (d == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE8EAED)),
        ),
        child: InkWell(
          onTap: onContinue,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    Text(
                      S.t('earn_rupee', {'n': formatInr(d.earn).replaceFirst('₹', '')}),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MintzerColors.earnGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // l10n-missing
                Text('${d.storeLabel} · Finish checkout', style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                const SizedBox(height: 12),
                _ActionStrip(
                  title: S.e('Action required'),
                  cta: S.t('continue'),
                  onTap: onContinue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _openOngoingMenu(BuildContext context, MockOrder order) {
  showModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.white,
    builder: (ctx) {
      S.watch(ctx);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(
                order.listNote.isEmpty ? S.t('add_note') : S.t('edit_note'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(S.t('note_p')),
              onTap: () async {
                Navigator.pop(ctx);
                final initial = order.note.startsWith('Cancel:') ? '' : order.note;
                final saved = await showNoteDialog(context, initial: initial);
                if (saved == null) return;
                order.note = saved;
                MockSession.rememberOrderNote(order.id, saved);
                MockSession.orders.value = List<MockOrder>.from(MockSession.orders.value);
              },
            ),
            ListTile(
              title: Text(
                S.e('Cancel order'),
                style: const TextStyle(color: Color(0xFFD93025), fontWeight: FontWeight.w700),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderDetailScreen(order: order, launchCancel: true),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onOpen, this.onMore, this.ticket});
  final MockOrder order;
  final VoidCallback onOpen;
  final VoidCallback? onMore;
  final MockTicket? ticket;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final d = order.deal;
    final idLine = order.storeOrderLine;

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8EAED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductThumb(deal: d, size: 64),
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
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF202124), height: 1.25),
                              ),
                            ),
                            if (!order.canceled) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: MintzerColors.earnFill,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  S.t('earn_rupee', {'n': formatInr(d.earn).replaceFirst('₹', '')}),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MintzerColors.earnGreen),
                                ),
                              ),
                            ],
                            if (onMore != null)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onMore,
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 4, top: 2, bottom: 2),
                                  child: Icon(Icons.more_vert, size: 22, color: Color(0xFF202124)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _MintzerIdRow(mintzerId: order.mintzerId),
                        const SizedBox(height: 3),
                        Text(idLine, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                        const SizedBox(height: 2),
                        Text(
                          // l10n-missing
                          'Ordered on ${_fmtDate(order.created)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6)),
                        ),
                        if (order.listNote.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '📝 ${order.listNote}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF5F6368), height: 1.3),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ListStageRail(order: order),
              if (deliveryCallReady(order))
                DeliveryCallListButton(
                  order: order,
                  onReschedule: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OrderDetailScreen(order: order, launchEditOfd: true),
                      ),
                    );
                  },
                ),
              if (order.ongoing) ...[
                const SizedBox(height: 12),
                if (order.needsUserAction)
                  _ActionStrip(
                    title: S.e('Action required'),
                    cta: order.actionCtaShort,
                    onTap: onOpen,
                  )
                else
                  Text(
                    order.statusLine,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368)),
                  ),
              ],
              if (ticket != null && ticket!.status != TicketStatus.closed) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0D6FF)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        ticket!.shortNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: MintzerColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          // l10n-missing
                          'Ticket · ${ticket!.subject}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368)),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16, color: Color(0xFF9AA0A6)),
                    ],
                  ),
                ),
              ],
              if (order.canceled)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    order.note.startsWith('Cancel:')
                        ? '${S.t('canceled')} · ${order.note.replaceFirst('Cancel: ', '')}'
                        : S.t('canceled'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD93025)),
                  ),
                ),
              if (order.paid && !order.canceled)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: MintzerColors.earnGreen),
                      const SizedBox(width: 6),
                      Text(S.t('completed_tag'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MintzerColors.earnGreen)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
     final m = [S.e('Jan'), S.e('Feb'), S.e('Mar'), S.e('Apr'), S.e('May'), S.e('Jun'), S.e('Jul'), S.e('Aug'), S.e('Sep'), S.e('Oct'), S.e('Nov'), S.e('Dec')];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

/// 4 stages for list cards: Ordered · Shipped · Delivered · Verified
/// Verified only after invoice is submitted / verifying — never while upload is due.
class _ListStageRail extends StatelessWidget {
  const _ListStageRail({required this.order});
  final MockOrder order;

  List<String> get _labels => [S.e('Ordered'), S.e('Shipped'), S.e('Delivered'), S.e('Verified')];

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final paid = order.paid && !order.canceled;
    final (completedThrough, current) = order.listStage;

    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 14, left: 2, right: 2),
                color: (paid || i <= completedThrough || (current != null && i <= current))
                    ? MintzerColors.primary.withValues(alpha: 0.45)
                    : const Color(0xFFE8EAED),
              ),
            ),
          _StageDot(
            label: _labels[i],
            done: paid || i <= completedThrough,
            current: !paid && !order.canceled && current != null && i == current,
          ),
        ],
      ],
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.label, required this.done, required this.current});
  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final Color ring;
    final Color fill;
    if (done || current) {
      ring = current ? MintzerColors.primary : MintzerColors.primary.withValues(alpha: 0.55);
      fill = current ? MintzerColors.primary : MintzerColors.primary.withValues(alpha: 0.85);
    } else {
      ring = const Color(0xFFDADCE0);
      fill = Colors.white;
    }

    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: (done || current) ? fill : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: ring, width: current ? 2.5 : 1.5),
          ),
          child: done && !current
              ? const Icon(Icons.check, size: 8, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: current ? FontWeight.w700 : FontWeight.w500,
            color: current ? MintzerColors.primary : (done ? const Color(0xFF5F6368) : const Color(0xFF9AA0A6)),
          ),
        ),
      ],
    );
  }
}

class _MintzerIdRow extends StatelessWidget {
  const _MintzerIdRow({required this.mintzerId});
  final String mintzerId;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Row(
      children: [
        Text('${S.t('mintzer')} ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
        Text(
          mintzerId,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF202124), letterSpacing: 0.2),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: mintzerId));
            if (context.mounted) {
              MintzerToasts.orderIdCopied(context);
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.copy_rounded, size: 14, color: MintzerColors.primary),
          ),
        ),
      ],
    );
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({
    required this.title,
    required this.cta,
    required this.onTap,
  });

  final String title;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Material(
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 18, color: MintzerColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MintzerColors.primary)),
              const Spacer(),
              Flexible(
                child: Text(
                  cta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MintzerColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
