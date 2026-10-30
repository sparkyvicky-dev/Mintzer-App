import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../config/app_config.dart';
import '../live/tickets_repository.dart';
import '../mock/session.dart';
import '../models/mock_ticket.dart';
import '../theme/app_theme.dart';
import '../widgets/help_ticket_sheet.dart';
import 'ticket_detail_screen.dart';

/// My tickets — inbox-style list (Open / Resolved).
class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  int _tab = 0; // 0 open · 1 resolved
  bool _loading = false;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    // Already have tickets (e.g. after login prefetch) — don't flash empty.
    if (MockSession.tickets.value.isNotEmpty) _bootstrapped = true;
    _loadLive();
  }

  Future<void> _loadLive() async {
    if (!AppConfig.useLiveTicketsApi || MockSession.authToken.isEmpty) {
      if (mounted) setState(() => _bootstrapped = true);
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);
    await TicketsRepository.instance.refreshFromLiveApi(force: true);
    if (mounted) {
      setState(() {
        _loading = false;
        _bootstrapped = true;
      });
    }
  }

  Future<void> _newTicket() async {
    await showHelpTicketSheet(context);
    await _loadLive();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Scaffold(
      backgroundColor: MintzerColors.background,
      body: SafeArea(
        child: ValueListenableBuilder<List<MockTicket>>(
          valueListenable: MockSession.tickets,
          builder: (context, list, _) {
            S.watch(context);
            final open = list.where((t) => t.status.isOpen).toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            final done = list.where((t) => t.status.isDone).toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            final shown = _tab == 0 ? open : done;

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
                            Text(S.t('my_tickets'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 1),
                            Text(
                              S.e('Track your support requests'),
                              style: TextStyle(fontSize: 12, color: Color(0xFF9AA0A6)),
                            ),
                          ],
                        ),
                      ),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: MintzerColors.primary),
                          ),
                        ),
                      TextButton(
                        onPressed: _newTicket,
                        style: TextButton.styleFrom(
                          foregroundColor: MintzerColors.primary,
                          backgroundColor: const Color(0xFFF0EDF8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        child: Text(S.e('+ New ticket')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _Segment(
                    openCount: _bootstrapped ? open.length : null,
                    resolvedCount: _bootstrapped ? done.length : null,
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
                const SizedBox(height: 12),
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
                        : shown.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.45,
                                child: _Empty(
                                  openTab: _tab == 0,
                                  onNew: _newTicket,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                            itemCount: shown.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final t = shown[i];
                              return _TicketCard(
                                ticket: t,
                                onTap: () {
                                  MockSession.markTicketRead(t);
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => TicketDetailScreen(ticket: t),
                                        ),
                                      )
                                      .then((_) {
                                    if (mounted) {
                                      setState(() {});
                                      // ignore: unawaited_futures
                                      _loadLive();
                                    }
                                  });
                                },
                              );
                            },
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

class _Segment extends StatelessWidget {
  const _Segment({
    required this.openCount,
    required this.resolvedCount,
    required this.index,
    required this.onChanged,
  });

  final int? openCount;
  final int? resolvedCount;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _SegBtn(label: S.e('Open'), count: openCount, selected: index == 0, onTap: () => onChanged(0))),
          Expanded(child: _SegBtn(label: S.t('st_resolved'), count: resolvedCount, selected: index == 1, onTap: () => onChanged(1))),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({required this.label, required this.count, required this.selected, required this.onTap});
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? MintzerColors.primary : const Color(0xFF5F6368),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? MintzerColors.primary : const Color(0xFFDADCE0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : const Color(0xFF5F6368),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});
  final MockTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final face = ticket.inboxFace;
    final unread = ticket.unread && face == TicketInboxFace.supportReplied;
    final tint = unread ? const Color(0xFFF7F4FF) : Colors.white;
    final border = unread ? const Color(0xFFE0D6FF) : MintzerColors.line;
    final preview = ticket.previewLine;

    return Material(
      color: tint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unread) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 5, right: 6),
                      child: Icon(Icons.circle, size: 8, color: MintzerColors.primary),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.25),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(face: face, unread: unread),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${ticket.id} · ${ticket.categoryLabel}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6), fontWeight: FontWeight.w500),
              ),
              if (ticket.orderId.isNotEmpty) ...[
                const SizedBox(height: 4),
                // l10n-missing
                Text(
                  'Order ${ticket.orderId}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                face.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: unread
                      ? MintzerColors.primary
                      : face == TicketInboxFace.waitingForSupport
                          ? const Color(0xFFE37400)
                          : face == TicketInboxFace.resolved
                              ? const Color(0xFF188038)
                              : MintzerColors.primary,
                ),
              ),
              if (preview != null) ...[
                const SizedBox(height: 4),
                Text(
                  '“$preview”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                _relative(ticket.updatedAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.face, required this.unread});
  final TicketInboxFace face;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final (bg, fg) = switch (face) {
      TicketInboxFace.waitingForSupport => (const Color(0xFFFEF7E0), const Color(0xFFE37400)),
      TicketInboxFace.supportReplied || TicketInboxFace.yourReplyNeeded => (
          const Color(0xFFEDE7FF),
          MintzerColors.primary,
        ),
      TicketInboxFace.resolved => (const Color(0xFFE6F4EA), const Color(0xFF188038)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unread) ...[
            const Icon(Icons.circle, size: 6, color: MintzerColors.primary),
            const SizedBox(width: 4),
          ],
          Text(face.pill, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.openTab, required this.onNew});
  final bool openTab;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              openTab ? S.e('No open tickets') : 'No resolved tickets yet',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              // l10n-missing
              openTab
                  ? 'Need help? Open a ticket and we’ll get back to you here.'
                  // l10n-missing
                  : 'Resolved tickets will show up in this tab.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9AA0A6), height: 1.4),
            ),
            if (openTab) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onNew,
                style: TextButton.styleFrom(
                  foregroundColor: MintzerColors.primary,
                  backgroundColor: const Color(0xFFF0EDF8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                child: Text(S.e('+ New ticket')),
              ),
            ],
          ],
        ),
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
  // l10n-missing
  return '${at.day} ${_mon(at.month)} ${at.year}';
}

String _mon(int m) =>  [S.e('Jan'), S.e('Feb'), S.e('Mar'), S.e('Apr'), S.e('May'), S.e('Jun'), S.e('Jul'), S.e('Aug'), S.e('Sep'), S.e('Oct'), S.e('Nov'), S.e('Dec')][m - 1];
