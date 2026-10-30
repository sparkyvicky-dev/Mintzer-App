import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../mock/session.dart';
import '../models/deal.dart';
import '../theme/app_theme.dart';

class HomeFilterResult {
  const HomeFilterResult({this.storeId, this.cardId, this.minEarn = 0});
  final String? storeId;
  final String? cardId;
  final int minEarn;

  bool get isActive => storeId != null || cardId != null || minEarn > 0;

  HomeFilterResult copyClear() => const HomeFilterResult();
}

Future<HomeFilterResult?> showHomeFilterSheet(
  BuildContext context, {
  required HomeFilterResult current,
}) {
  return showModalBottomSheet<HomeFilterResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _HomeFilterBody(initial: current),
  );
}

class _HomeFilterBody extends StatefulWidget {
  const _HomeFilterBody({required this.initial});
  final HomeFilterResult initial;

  @override
  State<_HomeFilterBody> createState() => _HomeFilterBodyState();
}

class _HomeFilterBodyState extends State<_HomeFilterBody> {
  late String? _store;
  late String? _card;
  late double _minEarn;

  static final _stores = <(String?, String)>[
    (null, ''),
    ('flipkart', 'Flipkart'),
    ('amazon', 'Amazon'),
  ];

  late final List<(String?, String)> _cards;

  @override
  void initState() {
    super.initState();
    _store = widget.initial.storeId;
    _card = widget.initial.cardId;
    _minEarn = widget.initial.minEarn.toDouble();
    final seen = <String>{};
    final cards = <(String?, String)>[(null, '')];
    for (final d in MockSession.deals.value) {
      if (seen.add(d.cardId)) cards.add((d.cardId, d.homeCardLabel));
    }
    _cards = cards;
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final minAny = S.e('Any');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFDADCE0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(S.t('filter_deals'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, const HomeFilterResult()),
                  child: Text(S.t('clear'), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(S.t('store'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5F6368))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _stores)
                  ChoiceChip(
                    label: Text(s.$1 == null ? S.t('all_stores') : s.$2),
                    selected: _store == s.$1,
                    onSelected: (_) => setState(() => _store = s.$1),
                    selectedColor: const Color(0xFFEDE7FF),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: _store == s.$1 ? MintzerColors.primary : const Color(0xFF202124),
                    ),
                    side: BorderSide(color: _store == s.$1 ? MintzerColors.primary : const Color(0xFFE8EAED)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              S.e('Card'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5F6368)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _cards)
                  ChoiceChip(
                    label: Text(c.$1 == null ? S.t('any_card') : c.$2),
                    selected: _card == c.$1,
                    onSelected: (_) => setState(() => _card = c.$1),
                    selectedColor: const Color(0xFFEDE7FF),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: _card == c.$1 ? MintzerColors.primary : const Color(0xFF202124),
                    ),
                    side: BorderSide(color: _card == c.$1 ? MintzerColors.primary : const Color(0xFFE8EAED)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    // l10n-missing
                    'Min earn',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5F6368)),
                  ),
                ),
                Text(
                  _minEarn <= 0 ? minAny : '₹${_minEarn.round()}+',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: MintzerColors.primary),
                ),
              ],
            ),
            Slider(
              value: _minEarn,
              min: 0,
              max: 2000,
              divisions: 20,
              activeColor: MintzerColors.primary,
              onChanged: (v) => setState(() => _minEarn = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  HomeFilterResult(
                    storeId: _store,
                    cardId: _card,
                    minEarn: _minEarn.round(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: MintzerColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                S.e('Show deals'),
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool dealMatchesFilter(MockDeal d, HomeFilterResult f) {
  if (f.storeId != null && d.storeId != f.storeId) return false;
  if (f.cardId != null && d.cardId != f.cardId) return false;
  if (f.minEarn > 0 && d.earn < f.minEarn) return false;
  return true;
}
