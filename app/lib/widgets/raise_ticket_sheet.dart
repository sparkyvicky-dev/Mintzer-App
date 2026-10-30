import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../api/auth_api.dart';
import '../config/app_config.dart';
import '../live/tickets_repository.dart';
import '../mock/session.dart';
import '../models/mock_order.dart';
import '../models/mock_ticket.dart';
import '../theme/app_theme.dart';
import 'mintzer_toast.dart';

class _Reason {
  const _Reason(this.id, this.label, this.qs);
  final String id;
  final String label;
  final List<({String id, String text, List<String> opts})> qs;
}

const _reasons = <_Reason>[
  _Reason('product_canceled', 'Product canceled', [
    (id: 'who', text: 'Who canceled it?', opts: ['Store canceled', 'I canceled']),
    (id: 'proof', text: 'Got cancel SMS or email?', opts: ['Yes', 'No']),
  ]),
  _Reason('paid_extra', 'Paid extra vs app', [
    (id: 'more', text: 'Was checkout more than You pay?', opts: ['Yes', 'Not sure']),
    (id: 'shot', text: 'Have a payment screenshot?', opts: ['Yes', 'No']),
  ]),
  _Reason('diff_color', 'Different color', [
    (id: 'listed', text: 'Was that color on the deal?', opts: ['No', 'Deal said any color']),
  ]),
  _Reason('diff_variant', 'Different variant', [
    (id: 'kind', text: 'What was different?', opts: ['Storage / size', 'Model', 'Not sure']),
  ]),
  _Reason('other', 'Other', []),
];

String _reasonShown(String en) => switch (en) {
      'Product canceled' => S.t('r_prod'),
      'Paid extra vs app' => S.t('r_extra'),
      'Different color' => S.t('r_color'),
      'Different variant' => S.t('r_variant'),
      'Other' => S.t('r_other'),
      'Who canceled it?' => S.t('q_who'),
      'Store canceled' => S.t('o_store'),
      'I canceled' => S.t('o_i'),
      'Got cancel SMS or email?' => S.t('q_proof'),
      'Yes' => S.t('yes'),
      'No' => S.t('no'),
      'Was checkout more than You pay?' => S.t('q_more'),
      'Not sure' => S.t('not_sure'),
      'Have a payment screenshot?' => S.t('q_shot'),
      'Was that color on the deal?' => S.t('q_listed'),
      'Deal said any color' => S.t('o_any'),
      'What was different?' => S.t('q_kind'),
      'Storage / size' => S.t('o_storage'),
      'Model' => S.t('o_model'),
      _ => en,
    };

/// Guided raise-ticket flow (locked ORDERS-PAGES). Returns created ticket or null.
Future<MockTicket?> showRaiseTicketSheet(BuildContext context, MockOrder order) {
  return showModalBottomSheet<MockTicket>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (c) {
      S.watch(c);
      return _RaiseTicketBody(order: order);
    },
  );
}

class _RaiseTicketBody extends StatefulWidget {
  const _RaiseTicketBody({required this.order});
  final MockOrder order;

  @override
  State<_RaiseTicketBody> createState() => _RaiseTicketBodyState();
}

class _RaiseTicketBodyState extends State<_RaiseTicketBody> {
  int step = 0;
  int qIndex = 0;
  _Reason? reason;
  final answers = <String, String>{};
  final otherCtrl = TextEditingController();
  bool _submitting = false;

  bool get _useLive =>
      AppConfig.useLiveTicketsApi && MockSession.authToken.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_useLive) {
      // ignore: unawaited_futures
      TicketsRepository.instance.ensureSubjects();
    }
  }

  @override
  void dispose() {
    otherCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLive(String subjectLabel, List<String> lines) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final msg = lines.where((e) => e.isNotEmpty).join('. ');
      final o = widget.order;
      final refParts = <String>[
        if (o.mintzerId.trim().isNotEmpty) o.mintzerId.trim(),
        if (o.hasStoreOrderId) o.orderId.trim(),
      ];
      final t = await TicketsRepository.instance.submitLive(
        subjectLabel: subjectLabel,
        message: msg.isEmpty ? subjectLabel : msg,
        orderRef: refParts.isEmpty ? o.displayOrderId : refParts.join(' · '),
      );
      if (!mounted) return;
      Navigator.pop(context, t);
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
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= step ? MintzerColors.primary : MintzerColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (step == 0) ..._stepCategory(),
          if (step == 1) ..._stepQuestions(),
          if (step == 2) ..._stepConfirm(),
        ],
      ),
    );
  }

  List<Widget> _stepCategory() => [
        Text(S.t('what_happened'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(S.e('Pick one'), style: TextStyle(fontSize: 13, color: MintzerColors.muted)),
        const SizedBox(height: 12),
        for (final r in _reasons)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              onPressed: () => setState(() {
                reason = r;
                qIndex = 0;
                answers.clear();
                otherCtrl.clear();
                step = 1;
              }),
              child: Text(_reasonShown(r.label), style: const TextStyle(fontWeight: FontWeight.w600, color: MintzerColors.ink)),
            ),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(S.t('close'))),
      ];

  List<Widget> _stepQuestions() {
    final r = reason!;
    if (r.id == 'other') {
      return [
        Text(S.t('r_other'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(S.t('other_p'), style: const TextStyle(fontSize: 13, color: MintzerColors.muted)),
        const SizedBox(height: 12),
        TextField(
          controller: otherCtrl,
          maxLength: 80,
          maxLines: 3,
          decoration: InputDecoration(hintText: S.t('other_ph'), border: const OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        Row(
          children: [
            TextButton(onPressed: () => setState(() => step = 0), child: Text(S.t('back'))),
            const Spacer(),
            FilledButton(
              onPressed: otherCtrl.text.trim().length < 4
                  ? null
                  : () => setState(() => step = 2),
              child: Text(S.t('next')),
            ),
          ],
        ),
      ];
    }
    final q = r.qs[qIndex];
    return [
      Text(_reasonShown(q.text), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      for (final opt in q.opts)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            onPressed: () => setState(() {
              answers[q.id] = opt;
              if (qIndex < r.qs.length - 1) {
                qIndex++;
              } else {
                step = 2;
              }
            }),
            child: Text(_reasonShown(opt), style: const TextStyle(fontWeight: FontWeight.w600, color: MintzerColors.ink)),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => setState(() {
            if (qIndex > 0) {
              qIndex--;
            } else {
              step = 0;
            }
          }),
          child: Text(S.t('back')),
        ),
      ),
    ];
  }

  List<Widget> _stepConfirm() {
    final r = reason!;
    final lines = r.id == 'other'
        ? [otherCtrl.text.trim()]
        : answers.values.toList();
    return [
      Text(S.t('submit_q'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(
        S.t('on_order', {'label': _reasonShown(r.label), 'id': widget.order.mintzerId}),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      Text(
        (r.id == 'other' ? lines : lines.map(_reasonShown)).where((e) => e.isNotEmpty).join(' · '),
        style: const TextStyle(color: MintzerColors.muted),
      ),
      const SizedBox(height: 8),
      Text(S.t('well_update'), style: const TextStyle(fontSize: 13, color: MintzerColors.muted)),
      const SizedBox(height: 16),
      Row(
        children: [
          TextButton(onPressed: () => setState(() => step = 1), child: Text(S.t('back'))),
          const Spacer(),
          FilledButton(
            onPressed: _submitting
                ? null
                : () async {
                    final r = reason!;
                    final lines = r.id == 'other'
                        ? [otherCtrl.text.trim()]
                        : answers.values.toList();
                    if (_useLive) {
                      await _submitLive(r.label, lines);
                      return;
                    }
                    final t = MockSession.createTicket(
                      subject: r.label,
                      category: r.id,
                      orderId: widget.order.mintzerId,
                      answers: lines,
                      message: lines.where((e) => e.isNotEmpty).join('. '),
                    );
                    if (!mounted) return;
                    Navigator.pop(context, t);
                  },
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(S.t('submit_ticket')),
          ),
        ],
      ),
    ];
  }
}
