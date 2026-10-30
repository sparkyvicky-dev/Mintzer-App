import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/s.dart';
import '../config/app_config.dart';
import '../live/order_mapper.dart';
import '../live/orders_repository.dart';
import '../mock/session.dart';
import '../models/mock_order.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/mintzer_toast.dart';
import 'order_detail_screen.dart';

/// Wallet — ChatGPT visual + locked rules: Total earned · Pending · Excel · date range · no withdraw.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with WidgetsBindingObserver {
  String _filter = 'all';
  DateTimeRange? _range;
  bool _loading = false;
  bool _loadedOnce = false;
  int _lastTab = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MockSession.orders.addListener(_refresh);
    MockSession.tabIndex.addListener(_onShellTab);
    _loadLive();
  }

  void _onShellTab() {
    if (MockSession.tabIndex.value == 2 && _lastTab != 2) {
      // ignore: unawaited_futures
      _loadLive(silent: _loadedOnce);
    }
    _lastTab = MockSession.tabIndex.value;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && MockSession.tabIndex.value == 2) {
      // ignore: unawaited_futures
      _loadLive(silent: true);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadLive({bool silent = false}) async {
    if (!AppConfig.useLiveOrdersApi || MockSession.authToken.isEmpty) return;
    if (_loading) return;
    final showSpinner = !silent && !_loadedOnce;
    if (showSpinner && mounted) setState(() => _loading = true);
    await OrdersRepository.instance.refreshFromLiveApi();
    if (mounted) {
      setState(() {
        _loading = false;
        _loadedOnce = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MockSession.orders.removeListener(_refresh);
    MockSession.tabIndex.removeListener(_onShellTab);
    super.dispose();
  }

  /// Wallet = paid / canceled always; pending once past bare Accept (placement).
  /// Prefer store Order ID when present; do not drop rows that only have Mintzer ORD.
  bool _inWallet(MockOrder o) {
    if (o.paid || o.canceled) return true;
    if (o.liveRail == RailStep.placement) return false;
    // After confirm / tracking+ : show with store id or Mintzer ORD.
    return o.ongoing && (o.hasStoreOrderId || o.mintzerId.trim().isNotEmpty);
  }

  List<MockOrder> get _walletOrders =>
      MockSession.orders.value.where(_inWallet).toList();

  int get _earned =>
      _walletOrders.where((o) => o.paid && !o.canceled).fold(0, (s, o) => s + o.deal.earn);

  int get _pending =>
      _walletOrders.where((o) => o.ongoing).fold(0, (s, o) => s + o.deal.earn);

  List<MockOrder> get _txs {
    final list = _walletOrders.where((o) {
      if (_filter == 'paid') return o.paid;
      if (_filter == 'pending') return o.ongoing;
      if (_filter == 'canceled') return o.canceled;
      return true;
    }).where((o) {
      final r = _range;
      if (r == null) return true;
      final d = DateTime(o.created.year, o.created.month, o.created.day);
      final start = DateTime(r.start.year, r.start.month, r.start.day);
      final end = DateTime(r.end.year, r.end.month, r.end.day);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList()
      ..sort((a, b) => b.created.compareTo(a.created));
    return list;
  }

  String get _rangeLabel {
    final r = _range;
    // l10n-missing
    if (r == null) return 'All time';
    String f(DateTime d) => '${d.day}/${d.month}/${d.year}';
    return '${f(r.start)} – ${f(r.end)}';
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _range ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: MintzerColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _exportExcel() async {
    final txs = _txs;
    if (txs.isEmpty) {
      showMintzerToast(context, S.e('Nothing to export'), kind: MintzerToastKind.warn);
      return;
    }
    // l10n-missing
    final buf = StringBuffer('Order ref,Product,Return amount,You earned,Status,Date\n');
    for (final o in txs) {
      final status = o.canceled ? S.t('canceled') : o.paid ? S.t('paid') : S.t('pending');
      final earn = o.canceled ? 0 : o.deal.earn;
      final returned = o.canceled ? 0 : o.bankReturnAmount;
      final date = '${o.created.day} ${_mon(o.created.month)} ${o.created.year}';
      buf.writeln('${o.mintzerId},"${o.deal.name}",$returned,$earn,$status,$date');
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    showMintzerToast(
      context,
      // l10n-missing
      'Excel ready',
      // l10n-missing
      subtitle: '${txs.length} rows copied',
      kind: MintzerToastKind.success,
      icon: Icons.table_chart_outlined,
    );
  }

  static String _mon(int m) =>
       [S.e('Jan'), S.e('Feb'), S.e('Mar'), S.e('Apr'), S.e('May'), S.e('Jun'), S.e('Jul'), S.e('Aug'), S.e('Sep'), S.e('Oct'), S.e('Nov'), S.e('Dec')][m - 1];

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final earned = _earned;
    final pending = _pending;
    final txs = _txs;
    final name = () {
      final pan = MockSession.panName.trim();
      if (pan.isNotEmpty) return pan.split(' ').first;
      final display = MockSession.displayName.trim();
      if (display.isNotEmpty) return display.split(' ').first;
      return S.t('hi_there');
    }();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: MintzerColors.primary,
          onRefresh: _loadLive,
          child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(S.t('wallet'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF202124))),
                ),
                if (_loading && !_loadedOnce)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: MintzerColors.primary),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // l10n-missing
            Text('Hi, $name · your earnings overview', style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      icon: Icons.account_balance_wallet_rounded,
                      iconBg: const Color(0xFFEDE7FF),
                      iconColor: MintzerColors.primary,
                      label: S.t('total_earned'),
                      amount: formatInr(earned),
                      amountColor: const Color(0xFF188038),
                      sub: S.e('Successfully credited to your account'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      icon: Icons.schedule_rounded,
                      iconBg: const Color(0xFFFEF7E0),
                      iconColor: const Color(0xFFE37400),
                      label: S.t('pending'),
                      amount: formatInr(pending),
                      amountColor: const Color(0xFFE37400),
                      sub: S.e('Will be credited after order completion'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  // l10n-missing
                  child: const Text('Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  tooltip: S.t('download_excel'),
                  onPressed: _exportExcel,
                  icon: const Icon(Icons.download_rounded, color: MintzerColors.primary),
                ),
                TextButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(_rangeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: TextButton.styleFrom(
                    foregroundColor: MintzerColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                if (_range != null)
                  IconButton(
                    tooltip: S.e('Clear dates'),
                    onPressed: () => setState(() => _range = null),
                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF5F6368)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in [
                    ('all', S.t('all')),
                    ('paid', S.t('paid')),
                    ('pending', S.t('pending')),
                    ('canceled', S.t('canceled')),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: f.$2,
                        selected: _filter == f.$1,
                        onTap: () => setState(() => _filter = f.$1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (txs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Text(S.e('No earnings yet'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF5F6368))),
                    const SizedBox(height: 6),
                    // l10n-missing
                    const Text('Place a deal to see credits here.', style: TextStyle(fontSize: 13, color: Color(0xFF9AA0A6))),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => MockSession.goToHomeTab(),
                      style: FilledButton.styleFrom(backgroundColor: MintzerColors.primary),
                      child: Text(S.e('Browse deals')),
                    ),
                  ],
                ),
              )
            else
              ...txs.map((o) => _TxRow(order: o)),
          ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.amount,
    required this.amountColor,
    required this.sub,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String amount;
  final Color amountColor;
  final String sub;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: amountColor)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF9AA0A6), height: 1.3)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Material(
      color: selected ? const Color(0xFFF3EEFF) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? MintzerColors.primary.withValues(alpha: 0.35) : const Color(0xFFE8EAED)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? MintzerColors.primary : const Color(0xFF3C4043),
            ),
          ),
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.order});
  final MockOrder order;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final status = order.canceled
        ? (S.t('canceled'), const Color(0xFF5F6368), const Color(0xFFF1F3F4))
        : order.paid
            ? (S.t('paid'), const Color(0xFF188038), const Color(0xFFE6F4EA))
            : (S.t('pending'), const Color(0xFFE37400), const Color(0xFFFEF7E0));
    final earn = order.canceled ? 0 : order.deal.earn;
    final returned = order.canceled ? 0 : order.bankReturnAmount;
    final date = '${order.created.day} ${_WalletScreenState._mon(order.created.month)} ${order.created.year}';
    final img = order.deal.imageAsset;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(order: order)),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8EAED)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: img == null
                      ? const Icon(Icons.shopping_bag_outlined, color: Color(0xFF9AA0A6))
                      : Image.asset(img, fit: BoxFit.contain),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.deal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(order.displayOrderId, style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
                      Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: status.$3, borderRadius: BorderRadius.circular(99)),
                      child: Text(status.$1, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: status.$2)),
                    ),
                    const SizedBox(height: 6),
                    // Same line: bank return + profit — no extra row height.
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: formatInr(returned > 0 ? returned : earn),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF202124),
                            ),
                          ),
                          if (earn > 0 && returned > earn)
                            TextSpan(
                              text: ' · +${formatInr(earn)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF188038),
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF9AA0A6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
