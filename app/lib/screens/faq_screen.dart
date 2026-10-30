import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../mock/faq_data.dart';
import '../theme/app_theme.dart';
import '../widgets/help_ticket_sheet.dart';

/// Consumer FAQ — Popular + compact category cards + search + support CTA.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _search = TextEditingController();
  final _catsKey = GlobalKey();
  String _query = '';
  String? _openKey;
  final Set<String> _expandedCats = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _filtering => _query.trim().isNotEmpty;

  List<FaqItem> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kFaqItems;
    return kFaqItems.where((i) => i.q.toLowerCase().contains(q) || i.a.toLowerCase().contains(q)).toList();
  }

  void _toggle(String key) => setState(() => _openKey = _openKey == key ? null : key);

  void _scrollToCats() {
    final ctx = _catsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: MintzerColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(S.t('faq'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
             Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  S.e('Quick answers about deals, orders and payouts.'),
                  style: TextStyle(fontSize: 13, color: Color(0xFF5F6368), height: 1.35),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() {
                  _query = v;
                  if (v.trim().isNotEmpty) {
                    for (final c in kFaqCats) {
                      _expandedCats.add(c.id);
                    }
                  }
                }),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: S.e('Search FAQs'),
                  hintStyle: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF9AA0A6)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9AA0A6)),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9AA0A6)),
                          onPressed: () => setState(() {
                            _search.clear();
                            _query = '';
                          }),
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF0EDF8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: MintzerColors.primary, width: 1.2),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  if (!_filtering) ...[
                    _PopularCard(
                      items: kPopularFaqItems,
                      openKey: _openKey,
                      onToggle: _toggle,
                      onSeeAll: _scrollToCats,
                    ),
                    const SizedBox(height: 14),
                    KeyedSubtree(
                      key: _catsKey,
                      child: Column(
                        children: [
                          for (final cat in kFaqCats) ...[
                            _CategoryCard(
                              cat: cat,
                              items: kFaqItems.where((i) => i.cat == cat.id).toList(),
                              expanded: _expandedCats.contains(cat.id),
                              openKey: _openKey,
                              onHeaderTap: () => setState(() {
                                if (_expandedCats.contains(cat.id)) {
                                  _expandedCats.remove(cat.id);
                                } else {
                                  _expandedCats.add(cat.id);
                                }
                              }),
                              onToggle: _toggle,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                  ] else ...[
                    if (filtered.isEmpty)
                       Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(S.e('No matching questions'), style: TextStyle(color: Color(0xFF9AA0A6))),
                        ),
                      )
                    else
                      _SearchResultsCard(
                        items: filtered,
                        openKey: _openKey,
                        onToggle: _toggle,
                      ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                  const _SupportCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  const _PopularCard({
    required this.items,
    required this.openKey,
    required this.onToggle,
    required this.onSeeAll,
  });

  final List<FaqItem> items;
  final String? openKey;
  final ValueChanged<String> onToggle;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0FF)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 18, color: MintzerColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(S.e('Popular questions'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: MintzerColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  // l10n-missing
                  child: const Text('See all ›'),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFE8E0FF)),
            _QuestionRow(
              item: items[i],
              rowKey: 'popular:${items[i].q}',
              open: openKey == 'popular:${items[i].q}',
              onTap: () => onToggle('popular:${items[i].q}'),
              compact: true,
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.cat,
    required this.items,
    required this.expanded,
    required this.openKey,
    required this.onHeaderTap,
    required this.onToggle,
  });

  final FaqCatMeta cat;
  final List<FaqItem> items;
  final bool expanded;
  final String? openKey;
  final VoidCallback onHeaderTap;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onHeaderTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cat.icon, size: 18, color: cat.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(S.e(cat.title), style:  TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 1),
                        // l10n-missing
                        Text(
                          '${items.length} question${items.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0A6)),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded, color: Color(0xFF9AA0A6)),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F3F4)),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFF1F3F4)),
              _QuestionRow(
                item: items[i],
                rowKey: '${cat.id}:${items[i].q}',
                open: openKey == '${cat.id}:${items[i].q}',
                onTap: () => onToggle('${cat.id}:${items[i].q}'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SearchResultsCard extends StatelessWidget {
  const _SearchResultsCard({required this.items, required this.openKey, required this.onToggle});

  final List<FaqItem> items;
  final String? openKey;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            // l10n-missing
            child: Text(
              '${items.length} result${items.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9AA0A6)),
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFF1F3F4)),
            _QuestionRow(
              item: items[i],
              rowKey: 'search:${items[i].q}',
              open: openKey == 'search:${items[i].q}',
              onTap: () => onToggle('search:${items[i].q}'),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.item,
    required this.rowKey,
    required this.open,
    required this.onTap,
    this.compact = false,
  });

  final FaqItem item;
  final String rowKey;
  final bool open;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      color: open ? const Color(0xFFF3EFFF) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, compact ? 12 : 14, 20, open ? 12 : (compact ? 12 : 14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      S.e(item.q),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: open ? MintzerColors.primary : MintzerColors.ink,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: open ? MintzerColors.primary : const Color(0xFF9AA0A6),
                    ),
                  ),
                ],
              ),
              if (open) ...[
                const SizedBox(height: 8),
                Text(
                  S.e(item.a),
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF5F6368), height: 1.45),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: MintzerColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.headset_mic_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
               Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.e('Still need help?'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    // l10n-missing
                    Text(
                      'Can’t find the answer you’re looking for? Our team is here to help.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF5F6368), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => showHelpTicketSheet(context),
              style: FilledButton.styleFrom(
                backgroundColor: MintzerColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              child: Text('${S.t('contact')} →'),
            ),
          ),
        ],
      ),
    );
  }
}
