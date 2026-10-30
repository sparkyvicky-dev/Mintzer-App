import 'package:flutter/material.dart';

import '../l10n/s.dart';
import '../theme/app_theme.dart';
import '../util/external_links.dart';
import 'mintzer_toast.dart';

/// Locked empty-Home sheet — “Send a deal you saw” (demo `modalSuggest`).
/// For now: opens WhatsApp chat to Mintzer ops with the filled details.
Future<void> showSuggestDealSheet(BuildContext context, {bool sendAnyway = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _SuggestDealBody(sendAnyway: sendAnyway),
  );
}

class _SuggestDealBody extends StatefulWidget {
  const _SuggestDealBody({required this.sendAnyway});
  final bool sendAnyway;

  @override
  State<_SuggestDealBody> createState() => _SuggestDealBodyState();
}

class _SuggestDealBodyState extends State<_SuggestDealBody> {
  final _product = TextEditingController();
  final _link = TextEditingController();
  String _source = 'whatsapp';
  String _store = '';
  bool _sending = false;

  List<(String, String)> get _sources => [
    ('whatsapp', 'WhatsApp'),
    // l10n-missing
    ('telegram', 'Telegram'),
    ('other_app', 'Other app'),
    ('website', 'Website'),
  ];

  List<(String, String)> get _stores => [
    ('', S.e('Any store')),
    ('flipkart', 'Flipkart'),
    ('amazon', 'Amazon'),
    ('iqoo', 'iQOO'),
    ('myntra', 'Myntra'),
    ('apple', 'Apple'),
    ('jiomart', 'JioMart'),
  ];

  @override
  void dispose() {
    _product.dispose();
    _link.dispose();
    super.dispose();
  }

  String get _storeLabel {
    for (final (id, label) in _stores) {
      if (id == _store) return label;
    }
    return S.e('Any store');
  }

  String _sourceChip(String id, String label) {
    if (id == 'other_app' || id == 'website') return S.t(id);
    return label;
  }

  String get _sourceLabel {
    for (final (id, label) in _sources) {
      if (id == _source) return label;
    }
    // l10n-missing
    return 'WhatsApp';
  }

  Future<void> _send() async {
    final product = _product.text.trim();
    if (product.isEmpty) {
      showMintzerToast(context, S.t('snack_suggest'), kind: MintzerToastKind.danger);
      return;
    }
    setState(() => _sending = true);

    final link = _link.text.trim();
    final buf = StringBuffer()
      ..writeln(S.e('Hi Mintzer team — deal suggestion'))
      ..writeln()
      // l10n-missing
      ..writeln('Product / offer: $product')
      // l10n-missing
      ..writeln('Seen on: $_sourceLabel')
      // l10n-missing
      ..writeln('Store: $_storeLabel');
    if (link.isNotEmpty) {
      // l10n-missing
      buf.writeln('Link: $link');
    }
    buf.writeln();
    // l10n-missing
    buf.writeln('Please check if you can run this on Home.');

    if (!mounted) return;
    Navigator.of(context).pop();
    await openSupportWhatsApp(context, preset: buf.toString());
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final openingWa = S.e('Opening WhatsApp…');
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDADCE0),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              S.t('send_deal'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
            ),
            const SizedBox(height: 6),
            Text(
              S.t('send_deal_p'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368), height: 1.4),
            ),
            const SizedBox(height: 16),
            Text(S.t('what_see'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
            const SizedBox(height: 6),
            TextField(
              controller: _product,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: S.t('what_see_ph'),
                hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.35), fontWeight: FontWeight.w400),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Text(S.t('where_see'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, label) in _sources)
                  _Chip(
                    label: _sourceChip(id, label),
                    selected: _source == id,
                    onTap: () => setState(() => _source = id),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(S.t('store_opt'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, label) in _stores)
                  _Chip(
                    label: label,
                    selected: _store == id,
                    onTap: () => setState(() => _store = id),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(S.t('link_opt'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
            const SizedBox(height: 6),
            TextField(
              controller: _link,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: S.e('https://www.flipkart.com/… or Amazon link'),
                hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.35), fontWeight: FontWeight.w400),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              // l10n-missing
              'Opens WhatsApp chat with the Mintzer team — not a public post, not a ticket.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF5F6368)),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: Text(_sending ? openingWa : S.t('send_ops')),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _sending ? null : () => Navigator.of(context).pop(),
              child: Text(S.t('cancel')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Material(
      color: selected ? const Color(0xFFEDE7FF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(99),
        side: BorderSide(color: selected ? MintzerColors.primary : MintzerColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? MintzerColors.primary : const Color(0xFF5F6368),
            ),
          ),
        ),
      ),
    );
  }
}
