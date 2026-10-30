import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../config/app_config.dart';
import '../live/notifications_repository.dart';
import '../live/tickets_repository.dart';
import '../mock/session.dart';
import '../models/mock_ticket.dart';
import '../theme/app_theme.dart';
import '../widgets/mintzer_toast.dart';
import 'order_detail_screen.dart';
import 'ticket_detail_screen.dart';
import 'tickets_screen.dart';

/// In-app bell inbox — action-first, minimal, Mintzer terms.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = false;
  bool _bootstrapped = false;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    if (MockSession.notifications.value.isNotEmpty) _bootstrapped = true;
    _loadLive();
  }

  Future<void> _loadLive() async {
    if (!AppConfig.useLiveNotificationsApi || MockSession.authToken.isEmpty) {
      if (mounted) setState(() => _bootstrapped = true);
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);
    await NotificationsRepository.instance.refreshFromLiveApi(force: true);
    if (mounted) {
      setState(() {
        _loading = false;
        _bootstrapped = true;
      });
    }
  }

  MockTicket? _ticketFor(MockNotification n) {
    final ref = n.ref.trim();
    final needle = ref.replaceAll(RegExp(r'\D'), '');
    for (final t in MockSession.tickets.value) {
      if (ref.isNotEmpty && (t.id == ref || t.id == 'TKT-$needle')) return t;
      final nid = TicketsRepository.liveNumericId(t)?.toString();
      if (needle.isNotEmpty && nid == needle) return t;
    }
    // Fallback: body/title may still mention TKT- / ticket #
    final hay = '${n.title} ${n.body}';
    final m = RegExp(r'(?:TKT-|ticket[#:\s]+)(\d+)', caseSensitive: false).firstMatch(hay);
    if (m != null) {
      final id = m.group(1);
      for (final t in MockSession.tickets.value) {
        if (t.id == 'TKT-$id' || TicketsRepository.liveNumericId(t)?.toString() == id) {
          return t;
        }
      }
    }
    return null;
  }

  Future<void> _open(MockNotification n) async {
    await NotificationsRepository.instance.markOneReadLive(n);
    if (n.kind == NotificationKind.ticket) {
      if (AppConfig.useLiveTicketsApi && MockSession.authToken.isNotEmpty) {
        await TicketsRepository.instance.refreshFromLiveApi(force: true);
      }
      if (!mounted) return;
      final t = _ticketFor(n);
      if (t != null) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => TicketDetailScreen(ticket: t)),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TicketsScreen()),
        );
      }
      return;
    }
    if (n.kind == NotificationKind.payout) {
      MockSession.tabIndex.value = 2;
      if (mounted) Navigator.pop(context);
      return;
    }
    if (n.kind == NotificationKind.order) {
      final match = MockSession.orders.value.where((o) => o.orderId == n.ref || o.mintzerId == n.ref);
      if (!mounted) return;
      if (match.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(order: match.first)),
        );
      } else {
        MockSession.tabIndex.value = 1;
        if (mounted) Navigator.pop(context);
      }
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clearAll() async {
    if (_clearing) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        S.watch(c);
        return AlertDialog(
        title: Text(S.e('Clear all notifications?')),
        // l10n-missing
        content: const Text('This removes them from your inbox. New ones will still appear.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(S.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFD93025)),
            child: Text(S.e('Clear all')),
          ),
        ],
      );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _clearing = true);
    await NotificationsRepository.instance.clearAllLive();
    if (mounted) {
      setState(() => _clearing = false);
      // l10n-missing
      showMintzerToast(context, 'Inbox cleared', kind: MintzerToastKind.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Scaffold(
      backgroundColor: MintzerColors.background,
      body: SafeArea(
        child: ValueListenableBuilder<List<MockNotification>>(
          valueListenable: MockSession.notifications,
          builder: (context, list, _) {
            S.watch(context);
            final sorted = [...list]..sort((a, b) => b.created.compareTo(a.created));
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final today = sorted.where((n) => !n.created.isBefore(todayStart)).toList();
            final earlier = sorted.where((n) => n.created.isBefore(todayStart)).toList();
            final unread = sorted.where((n) => n.unread).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(S.t('notifications'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                              S.e('Tickets, orders and Mintzer payouts'),
                              style: TextStyle(fontSize: 12, color: Color(0xFF9AA0A6)),
                            ),
                          ],
                        ),
                      ),
                      if (_loading || _clearing)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: MintzerColors.primary),
                          ),
                        ),
                    ],
                  ),
                ),
                if (sorted.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Row(
                      children: [
                        if (unread > 0)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => NotificationsRepository.instance.markAllReadLive(),
                              icon: const Icon(Icons.done_all_rounded, size: 18),
                              label: Text(S.e('Mark all read')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MintzerColors.primary,
                                side: const BorderSide(color: Color(0xFFE0D6FF)),
                                backgroundColor: const Color(0xFFF7F4FF),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        if (unread > 0) const SizedBox(width: 10),
                        TextButton(
                          onPressed: _clearing ? null : _clearAll,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFD93025),
                            backgroundColor: const Color(0xFFFCE8E6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          child: Text(S.e('Clear all')),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Expanded(
                  child: RefreshIndicator(
                    color: MintzerColors.primary,
                    onRefresh: _loadLive,
                    child: !_bootstrapped
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: MintzerColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : sorted.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 80),
                                  _Empty(),
                                ],
                              )
                            : ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                                children: [
                                  if (today.isNotEmpty) ...[
                                    _SectionLabel(label: S.e('Today'), count: today.where((n) => n.unread).length),
                                    const SizedBox(height: 8),
                                    for (final n in today) ...[
                                      _NotifCard(n: n, onTap: () => _open(n)),
                                      const SizedBox(height: 8),
                                    ],
                                  ],
                                  if (earlier.isNotEmpty) ...[
                                    if (today.isNotEmpty) const SizedBox(height: 8),
                                     _SectionLabel(label: S.e('Earlier')),
                                    const SizedBox(height: 8),
                                    for (final n in earlier) ...[
                                      _NotifCard(n: n, onTap: () => _open(n)),
                                      const SizedBox(height: 8),
                                    ],
                                  ],
                                  const SizedBox(height: 16),
                                  _CaughtUp(),
                                ],
                              ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.count = 0});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF5F6368))),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: MintzerColors.primary, borderRadius: BorderRadius.circular(99)),
            child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ],
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.n, required this.onTap});
  final MockNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final style = _styleFor(n.kind);
    final tint = n.unread ? style.unreadBg : Colors.white;
    final border = n.unread ? style.unreadBorder : MintzerColors.line;

    return Material(
      color: tint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: style.iconBg, shape: BoxShape.circle),
                child: Icon(style.icon, size: 20, color: style.accent),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.25),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (n.unread)
                          const Padding(
                            padding: EdgeInsets.only(top: 4, right: 4),
                            child: Icon(Icons.circle, size: 8, color: MintzerColors.primary),
                          ),
                        Text(
                          _relative(n.created),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      style.label,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: style.accent, letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF5F6368), height: 1.35),
                    ),
                    if (n.meta != null && n.meta!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        n.meta!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 10),
                child: Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFB0B4B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindStyle {
  const _KindStyle({
    required this.label,
    required this.icon,
    required this.accent,
    required this.iconBg,
    required this.unreadBg,
    required this.unreadBorder,
  });
  final String label;
  final IconData icon;
  final Color accent;
  final Color iconBg;
  final Color unreadBg;
  final Color unreadBorder;
}

_KindStyle _styleFor(NotificationKind k) => switch (k) {
      NotificationKind.ticket =>  _KindStyle(
          label: S.e('Ticket'),
          icon: Icons.chat_bubble_outline_rounded,
          accent: MintzerColors.primary,
          iconBg: Color(0xFFEDE7FF),
          unreadBg: Color(0xFFF7F4FF),
          unreadBorder: Color(0xFFE0D6FF),
        ),
      NotificationKind.order => const _KindStyle(
          // l10n-missing
          label: 'Order',
          icon: Icons.local_shipping_outlined,
          accent: Color(0xFF1A73E8),
          iconBg: Color(0xFFE8F0FE),
          unreadBg: Color(0xFFF3F8FF),
          unreadBorder: Color(0xFFD2E3FC),
        ),
      NotificationKind.payout => _KindStyle(
          label: S.t('help_payout'),
          icon: Icons.currency_rupee_rounded,
          accent: const Color(0xFF188038),
          iconBg: const Color(0xFFE6F4EA),
          unreadBg: const Color(0xFFF0F9F2),
          unreadBorder: const Color(0xFFCEEAD6),
        ),
      NotificationKind.deal =>  _KindStyle(
          label: S.e('Deal'),
          icon: Icons.local_offer_outlined,
          accent: Color(0xFFC5221F),
          iconBg: Color(0xFFFCE8E6),
          unreadBg: Color(0xFFFEF3F2),
          unreadBorder: Color(0xFFFAD2CF),
        ),
      NotificationKind.system => _KindStyle(
          label: S.t('mintzer'),
          icon: Icons.notifications_none_rounded,
          accent: const Color(0xFF5F6368),
          iconBg: const Color(0xFFF1F3F4),
          unreadBg: const Color(0xFFF8F9FA),
          unreadBorder: MintzerColors.line,
        ),
    };

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 48, color: Color(0xFFDADCE0)),
            const SizedBox(height: 14),
            Text(S.t('caught_up'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            // l10n-missing
            const Text(
              'We’ll notify you here about tickets,\norders and Mintzer payouts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF9AA0A6), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaughtUp extends StatelessWidget {
  const _CaughtUp();

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 22, color: Color(0xFFDADCE0)),
          const SizedBox(height: 6),
          Text(S.t('caught_up'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9AA0A6))),
          const SizedBox(height: 2),
          // l10n-missing
          const Text(
            'We’ll notify you when there’s something new.',
            style: TextStyle(fontSize: 11, color: Color(0xFFB0B4B8)),
          ),
        ],
      ),
    );
  }
}

String _relative(DateTime at) {
  final d = DateTime.now().difference(at);
  // l10n-missing
  if (d.inSeconds < 60) return 'Just now';
  // l10n-missing
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return S.t('rel_h', {'n': '${d.inHours}'});
  // l10n-missing
  if (d.inDays == 1) return 'Yesterday';
  if (d.inDays < 7) return S.t('rel_d', {'n': '${d.inDays}'});
  return '${at.day}/${at.month}';
}
