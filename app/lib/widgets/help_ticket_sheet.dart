import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../api/auth_api.dart';
import '../config/app_config.dart';
import '../live/tickets_repository.dart';
import '../mock/session.dart';
import '../theme/app_theme.dart';
import 'mintzer_toast.dart';

/// General Help (not order-tied). Topic → follow-up → 80-char note.
Future<void> showHelpTicketSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      S.watch(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: const _HelpBody(),
      );
    },
  );
}

Map<String, ({String label, String q, List<String> opts})> _topics() => {
  'account': (
    label: S.e('Account / login'),
    q: 'What’s wrong?',
    opts: [
      // l10n-missing
      'Can’t log in',
      // l10n-missing
      'Wrong number',
      'Other',
    ],
  ),
  'payout': (
    // l10n-missing
    label: 'Payout / bank',
    // l10n-missing
    q: 'What’s the issue?',
    opts: [
      'Not received',
      // l10n-missing
      'Wrong bank',
      'Other',
    ],
  ),
  'deal': (
    label: S.e('Deal / Home'),
    // l10n-missing
    q: 'What’s up?',
    opts: [
      // l10n-missing
      'Deal missing',
      // l10n-missing
      'Wrong price',
      'Other',
    ],
  ),
  'app': (
    // l10n-missing
    label: 'App bug',
    // l10n-missing
    q: 'Where?',
    opts: [
      'Orders',
      'Wallet',
      'Other',
    ],
  ),
};

String _helpShown(String en) => switch (en) {
      'What’s wrong?' => S.t('help_payout_q'),
      'Other' => S.t('help_other'),
      'Not received' => S.t('help_payout_1'),
      'Orders' => S.t('nav_orders'),
      'Wallet' => S.t('wallet'),
      _ => en,
    };

class _HelpBody extends StatefulWidget {
  const _HelpBody();

  @override
  State<_HelpBody> createState() => _HelpBodyState();
}

class _HelpBodyState extends State<_HelpBody> {
  String? topic;
  String? follow;
  final details = TextEditingController();
  final _noteFocus = FocusNode();
  bool _submitting = false;
  List<({int id, String name})> _liveSubjects = const [];

  bool get _useLive =>
      AppConfig.useLiveTicketsApi && MockSession.authToken.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_useLive) {
      // ignore: unawaited_futures
      _loadSubjects();
    }
  }

  Future<void> _loadSubjects() async {
    final list = await TicketsRepository.instance.ensureSubjects();
    if (!mounted) return;
    setState(() {
      _liveSubjects = [for (final s in list) (id: s.id, name: s.name)];
    });
  }

  @override
  void dispose() {
    details.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final note = details.text.trim();
    if (note.length < 4) return;

    setState(() => _submitting = true);
    try {
      if (_useLive) {
        String subjectLabel;
        if (_liveSubjects.isNotEmpty && topic != null && int.tryParse(topic!) != null) {
          final id = int.parse(topic!);
          subjectLabel = _liveSubjects.firstWhere((e) => e.id == id, orElse: () => _liveSubjects.first).name;
        } else {
          subjectLabel = topic == null ? 'Other' : (_topics()[topic]?.label ?? topic!);
        }
        final msg = [
          if (follow != null) follow,
          note,
        ].whereType<String>().where((e) => e.isNotEmpty).join('. ');

        final ticket = await TicketsRepository.instance.submitLive(
          subjectLabel: subjectLabel,
          message: msg,
        );
        if (!mounted) return;
        Navigator.pop(context);
        MintzerToasts.ticketOpened(context, ticket?.id ?? 'sent');
        return;
      }

      final label = _topics()[topic]!.label;
      final msg = [
        if (follow != null) follow,
        note,
      ].whereType<String>().where((e) => e.isNotEmpty).join('. ');
      final ticket = MockSession.createTicket(
        subject: label,
        category: topic!,
        orderId: '',
        answers: [if (follow != null) follow!],
        message: msg,
      );
      MockSession.addNotification(
        title: S.e('Ticket opened'),
        // l10n-missing
        body: 'Ticket ${ticket.id} · $label',
        action: 'ticket',
        ref: ticket.id,
      );
      if (!mounted) return;
      Navigator.pop(context);
      MintzerToasts.ticketOpened(context, ticket.id);
    } on AuthApiException catch (e) {
      if (!mounted) return;
      showMintzerToast(context, e.message, kind: MintzerToastKind.warn);
    } catch (_) {
      if (!mounted) return;
      showMintzerToast(context, S.e('Couldn’t send ticket'), kind: MintzerToastKind.warn);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final useLiveTopics = _useLive && _liveSubjects.isNotEmpty;
    final t = (!useLiveTopics && topic != null) ? _topics()[topic] : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: MintzerColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(S.t('help'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              S.e('Goes to Mintzer ops — not WhatsApp.'),
              style: TextStyle(fontSize: 12, color: MintzerColors.muted),
            ),
            const SizedBox(height: 14),
            Text(S.t('topic'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MintzerColors.muted)),
            const SizedBox(height: 6),
            if (useLiveTopics)
              ..._liveSubjects.map((e) {
                final key = '${e.id}';
                final selected = topic == key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected ? MintzerColors.spendFill : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: selected ? MintzerColors.primary : MintzerColors.line),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() {
                        topic = key;
                        follow = null;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.name,
                                style: TextStyle(
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected ? MintzerColors.primary : MintzerColors.ink,
                                ),
                              ),
                            ),
                            if (selected) const Icon(Icons.check_circle, size: 18, color: MintzerColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              })
            else
              ..._topics().entries.map((e) {
                final selected = topic == e.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected ? MintzerColors.spendFill : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: selected ? MintzerColors.primary : MintzerColors.line),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() {
                        topic = e.key;
                        follow = null;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _helpShown(e.value.label),
                                style: TextStyle(
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected ? MintzerColors.primary : MintzerColors.ink,
                                ),
                              ),
                            ),
                            if (selected) const Icon(Icons.check_circle, size: 18, color: MintzerColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            if (t != null) ...[
              const SizedBox(height: 4),
              Text(_helpShown(t.q), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final opt in t.opts)
                    ChoiceChip(
                      label: Text(_helpShown(opt)),
                      selected: follow == opt,
                      onSelected: (_) => setState(() => follow = opt),
                    ),
                ],
              ),
            ],
            if (topic != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: details,
                focusNode: _noteFocus,
                maxLength: 80,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration:  InputDecoration(
                  labelText: S.e('Short note'),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: MintzerColors.primary, width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton(
              onPressed: topic == null || details.text.trim().length < 4 || _submitting
                  ? null
                  : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(S.t('submit_ticket')),
            ),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.pop(context),
              child: Text(S.t('cancel'), style: const TextStyle(color: MintzerColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
