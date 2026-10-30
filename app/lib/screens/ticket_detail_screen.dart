import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../api/auth_api.dart';
import '../config/app_config.dart';
import '../live/tickets_repository.dart';
import '../mock/session.dart';
import '../models/mock_ticket.dart';
import '../theme/app_theme.dart';
import '../widgets/mintzer_toast.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.ticket});
  final MockTicket ticket;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen>
    with WidgetsBindingObserver {
  final _reply = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  bool _closing = false;
  Timer? _poll;
  int _lastMsgCount = 0;

  MockTicket get t {
    for (final e in MockSession.tickets.value) {
      if (e.id == widget.ticket.id) return e;
    }
    return widget.ticket;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MockSession.tickets.addListener(_onTickets);
    MockSession.markTicketRead(t);
    _lastMsgCount = t.messages.length;
    _startPoll();
    // Fresh pull when opening detail (admin may have replied).
    // ignore: unawaited_futures
    TicketsRepository.instance.refreshFromLiveApi(force: true);
  }

  void _onTickets() {
    if (!mounted) return;
    final ticket = t;
    MockSession.markTicketRead(ticket);
    final n = ticket.messages.length;
    if (n > _lastMsgCount) {
      _lastMsgCount = n;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      _lastMsgCount = n;
    }
    setState(() {});
  }

  void _startPoll() {
    _poll?.cancel();
    if (!AppConfig.useLiveTicketsApi || MockSession.authToken.isEmpty) return;
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (!t.status.isOpen) return;
      // ignore: unawaited_futures
      TicketsRepository.instance.refreshFromLiveApi();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ignore: unawaited_futures
      TicketsRepository.instance.refreshFromLiveApi(force: true);
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    MockSession.tickets.removeListener(_onTickets);
    _reply.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String? get _nextSim => switch (t.status) {
        TicketStatus.submitted => S.e('Support reply'),
        TicketStatus.inProgress => S.t('st_resolved'),
        _ => null,
      };

  String get _faceLabel => t.inboxFace.label;

  bool get _canReplyLive => t.liveRemote && t.supportsReplies && t.status.isOpen;
  bool get _canReplyMock => !t.liveRemote && t.status.isOpen;
  bool get _canClose => t.status.isOpen;

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) return;

    if (_canReplyLive) {
      setState(() => _sending = true);
      try {
        await TicketsRepository.instance.replyLive(ticket: t, message: text);
        _reply.clear();
        if (!mounted) return;
        setState(() {});
        showMintzerToast(context, S.e('Reply sent'), kind: MintzerToastKind.success);
      } on AuthApiException catch (e) {
        if (!mounted) return;
        showMintzerToast(context, e.message, kind: MintzerToastKind.warn);
      } catch (_) {
        if (!mounted) return;
        // l10n-missing
        showMintzerToast(context, 'Couldn’t send reply', kind: MintzerToastKind.warn);
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }

    if (_canReplyMock) {
      MockSession.userReply(t, text);
      _reply.clear();
      setState(() {});
    }
  }

  Future<void> _closeTicket() async {
    if (_closing || !_canClose) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        S.watch(c);
        return AlertDialog(
        title: Text(S.e('Mark as resolved?')),
        // l10n-missing
        content: const Text(
          'This closes the ticket for you and updates Mintzer ops. You can open a new ticket later if needed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(S.t('cancel'))),
          // l10n-missing
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Mark resolved')),
        ],
      );
      },
    );
    if (ok != true || !mounted) return;

    if (t.liveRemote && AppConfig.useLiveTicketsApi && MockSession.authToken.isNotEmpty) {
      setState(() => _closing = true);
      try {
        await TicketsRepository.instance.closeLive(ticket: t);
        if (!mounted) return;
        setState(() {});
        showMintzerToast(context, S.e('Ticket resolved'), kind: MintzerToastKind.success);
      } on AuthApiException catch (e) {
        if (!mounted) return;
        showMintzerToast(context, e.message, kind: MintzerToastKind.warn);
      } catch (_) {
        if (!mounted) return;
        // l10n-missing
        showMintzerToast(context, 'Couldn’t close ticket', kind: MintzerToastKind.warn);
      } finally {
        if (mounted) setState(() => _closing = false);
      }
      return;
    }

    t.status = TicketStatus.resolved;
    MockSession.tickets.value = [...MockSession.tickets.value];
    setState(() {});
    showMintzerToast(context, S.e('Ticket resolved'), kind: MintzerToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final ticket = t;
    return Scaffold(
      backgroundColor: MintzerColors.background,
      appBar: AppBar(
        title: Text(ticket.subject, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          if (_canClose)
            TextButton(
              onPressed: _closing ? null : _closeTicket,
              child: Text(
                _closing ? S.e('…') : 'Resolve',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF188038)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ticket.id} · ${ticket.categoryLabel} · $_faceLabel',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MintzerColors.muted),
                ),
                if (ticket.orderId.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  // l10n-missing
                  Text('Order ${ticket.orderId}', style: const TextStyle(fontSize: 12, color: MintzerColors.muted)),
                ],
                Text(
                  // l10n-missing
                  'Opened ${ticket.created.day}/${ticket.created.month}/${ticket.created.year}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6)),
                ),
                if (ticket.answers.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(ticket.answers.join(' · '), style: const TextStyle(fontSize: 12, color: MintzerColors.muted)),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                for (final m in ticket.messages) _bubble(m),
                if (AppConfig.showSimulateControls && _nextSim != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      MockSession.simulateAdminReply(ticket);
                      setState(() {});
                      showMintzerToast(
                        context,
                        S.e('Mintzer replied'),
                        // l10n-missing
                        subtitle: 'Check the message below',
                        kind: MintzerToastKind.info,
                        icon: Icons.mark_chat_read_outlined,
                      );
                    },
                    child: Text(S.t('sim_admin', {'st': _nextSim!})),
                  ),
                ],
              ],
            ),
          ),
          if (_canReplyLive || _canReplyMock)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _reply,
                        enabled: !_sending,
                        decoration:  InputDecoration(
                          hintText: S.e('Reply…'),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _sending ? null : _send,
                      child: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(S.e('Send')),
                    ),
                  ],
                ),
              ),
            )
          else if (ticket.liveRemote && !ticket.supportsReplies && ticket.status.isOpen)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                // l10n-missing
                child: Text(
                  'Replies will unlock after Mintzer finishes the server update. Status still updates here.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35),
                ),
              ),
            )
          else if (ticket.status.isDone)
             SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  S.e('This ticket is resolved.'),
                  style: TextStyle(fontSize: 12, color: Color(0xFF188038), fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bubble(TicketMessage m) {
    final you = m.fromYou;
    final maxW = MediaQuery.sizeOf(context).width * 0.78;
    final time =
        '${m.at.hour.toString().padLeft(2, '0')}:${m.at.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: you ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!you) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: const BoxDecoration(
                color: Color(0xFFEDE7FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, size: 16, color: MintzerColors.primary),
            ),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              crossAxisAlignment: you ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                  child: Text(
                    you ? S.t('you') : S.t('mintzer'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: you ? const Color(0xFF5F6368) : MintzerColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  decoration: BoxDecoration(
                    color: you ? MintzerColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(you ? 16 : 4),
                      bottomRight: Radius.circular(you ? 4 : 16),
                    ),
                    border: you ? null : Border.all(color: const Color(0xFFE8EAED)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: you ? Colors.white : const Color(0xFF202124),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: you ? const Color(0xCCFFFFFF) : const Color(0xFF9AA0A6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (you) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(left: 8, bottom: 2),
              decoration: const BoxDecoration(
                color: Color(0xFFE8EAED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF5F6368)),
            ),
          ],
        ],
      ),
    );
  }
}
