import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/banks_api.dart';
import '../l10n/s.dart';
import '../live/partner_cards_repository.dart';
import '../mock/partner_cards.dart';
import '../mock/session.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/brand_mark.dart';
import '../widgets/mintzer_toast.dart';

const _pickIds = ['amex', 'axis', 'hdfc'];
const _pickReward = {'amex': 5000, 'axis': 3600, 'hdfc': 2100};
const _cardFace = 'assets/apply/apply-card-face-default.png';

/// Opens Apply for cards — banks marked On plan in admin, each with its own page.
Future<void> openPartnerCards(BuildContext context) async {
  // ignore: unawaited_futures
  PartnerCardsRepository.instance.refreshFromLiveApi();
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const PartnerCardsScreen()),
  );
}

int rewardFor(PartnerCardOffer card) {
  final live = card.rewardUpto;
  if (live != null && live > 0) return live;
  return _pickReward[card.id] ?? 5000;
}

String _digits(int n) {
  final s = formatInr(n);
  return s.startsWith('₹') ? s.substring(1) : s;
}

List<PartnerCardOffer> _picks(List<PartnerCardOffer> live) {
  final fromApi = live.any((c) => c.liveBankId != null);
  if (fromApi) {
    final featured = [for (final c in live) if (c.featured) c];
    featured.sort((a, b) {
      final as = a.featuredSort;
      final bs = b.featuredSort;
      if (as != null && bs != null && as != bs) return as.compareTo(bs);
      if (as != null && bs == null) return -1;
      if (as == null && bs != null) return 1;
      return a.bank.toLowerCase().compareTo(b.bank.toLowerCase());
    });
    return featured;
  }
  final byId = <String, PartnerCardOffer>{
    for (final c in kPartnerCards) c.id: c,
    for (final c in live) c.id: c,
  };
  return [for (final id in _pickIds) if (byId[id] != null) byId[id]!];
}

class PartnerCardsScreen extends StatelessWidget {
  const PartnerCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      appBar: AppBar(
        title: Text(S.t('apply_cards')),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8EAED)),
        ),
      ),
      body: ValueListenableBuilder<List<PartnerCardOffer>>(
        valueListenable: MockSession.partnerCards,
        builder: (context, liveCards, _) {
          final cards = _picks(liveCards);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              const _ListHeader(),
              const SizedBox(height: 14),
              for (final c in cards) ...[
                _PickRow(card: c),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              Text(
                S.t('pick_foot'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF80868B), height: 1.4),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader();

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.t('cards_for'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF202124), height: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                S.t('cards_for_sub'),
                style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368), height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Transform.rotate(
          angle: 0.14,
          child: Image.asset(_cardFace, width: 108, height: 68, fit: BoxFit.contain),
        ),
      ],
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({required this.card});
  final PartnerCardOffer card;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final amount = _digits(rewardFor(card));
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => PartnerCardPage(card: card)),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Row(
            children: [
              BrandMark(size: 44, asset: card.logoAsset, letter: card.bank),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.bank,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.t('month_upto', {'n': amount}),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: MintzerColors.primary),
                    ),
                    Text(
                      S.t('card_on_deals'),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB39DFF)),
            ],
          ),
        ),
      ),
    );
  }
}

class PartnerCardPage extends StatelessWidget {
  const PartnerCardPage({super.key, required this.card});
  final PartnerCardOffer card;

  Future<void> _apply(BuildContext context) async {
    final url = (card.applyUrl ?? '').trim();
    if (url.isEmpty) {
      showMintzerToast(context, S.t('card_soon'), kind: MintzerToastKind.info);
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.toLowerCase() != 'https') {
      if (context.mounted) {
        showMintzerToast(context, S.e('Couldn’t open apply link'), kind: MintzerToastKind.danger);
      }
      return;
    }
    final bankId = card.liveBankId;
    if (bankId != null) {
      // ignore: unawaited_futures
      BanksApi.instance.logApplyClick(authToken: MockSession.authToken, bankId: bankId);
    }
    showMintzerToast(context, S.t('card_opening'), kind: MintzerToastKind.info);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showMintzerToast(context, S.e('Couldn’t open apply link'), kind: MintzerToastKind.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final name = card.bank;
    final amount = _digits(rewardFor(card));
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      appBar: AppBar(
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8EAED)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              BrandMark(size: 40, asset: card.logoAsset, letter: card.bank),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(
                      S.t('month_upto', {'n': amount}),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MintzerColors.primary),
                    ),
                    Text(S.t('card_on_deals'), style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Transform.rotate(
              angle: 0.1,
              child: Image.asset(_cardFace, width: 280, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up_rounded, color: Color(0xFF137333)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.t('card_hi_t'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF137333))),
                      const SizedBox(height: 2),
                      Text(
                        S.t('card_hi_b', {'n': amount}),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF137333), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(S.t('card_why_h'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _WhyRow(icon: Icons.payments_outlined, title: S.t('card_w1t'), body: S.t('card_w1b', {'n': amount})),
          _WhyRow(icon: Icons.airline_seat_recline_extra_outlined, title: S.t('card_w2t'), body: S.t('card_w2b')),
          _WhyRow(icon: Icons.local_offer_outlined, title: S.t('card_w3t'), body: S.t('card_w3b')),
          const SizedBox(height: 8),
          Text(S.t('card_how'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _StepRow(n: 1, title: S.t('card_s1t'), body: S.t('card_s1b', {'card': name})),
          _StepRow(n: 2, title: S.t('card_s2t'), body: S.t('card_s2b')),
          _StepRow(n: 3, title: S.t('card_s3t'), body: S.t('card_s3b')),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => _apply(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: MintzerColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    S.t('card_apply', {'card': name}),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.t('card_redirect', {'card': name}),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF80868B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhyRow extends StatelessWidget {
  const _WhyRow({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Color(0xFFEDE7FF), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: MintzerColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.n, required this.title, required this.body});
  final int n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: MintzerColors.primary, shape: BoxShape.circle),
            child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
