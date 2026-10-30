import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/banners_api.dart';
import '../mock/home_promos.dart';
import '../mock/session.dart';
import '../mock/session_store.dart';
import '../models/deal.dart';
import '../config/app_config.dart';
import '../l10n/s.dart';
import '../live/banners_repository.dart';
import '../live/deals_repository.dart';
import '../live/partner_cards_repository.dart';
import '../live/social_proof.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/deal_card.dart';
import '../widgets/image_alert_popup.dart';
import '../widgets/home_filter_sheet.dart';
import '../widgets/home_promo_carousel.dart';
import '../widgets/mintzer_refresh.dart';
import '../widgets/mintzer_toast.dart';
import '../widgets/product_image_cache.dart';
import '../widgets/suggest_deal_sheet.dart';
import '../widgets/whatsapp_icon.dart';
import '../util/external_links.dart';
import 'deal_detail_screen.dart';
import 'notifications_screen.dart';
import 'place_order_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onWallet});

  final VoidCallback onWallet;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  late final String _idleSub = pickHomeIdleSub();
  String _filter = 'all';
  bool _grid = true;
  double _lastScroll = 0;
  HomeFilterResult _funnel = const HomeFilterResult();
  DateTime? _lastDealsFetch;
  Timer? _homePoll;
  bool _homeAlertChecked = false;

  String get _greeting => homeGreeting(MockSession.greetingFirstName);

  String get _sub {
    if (MockSession.activeDeal.value != null) return S.t('home_sub_timer');
    final needs = MockSession.orders.value.any((o) => o.ongoing && o.step >= 1 && o.step <= 4);
    if (needs) return S.t('home_sub_action');
    return S.e(_idleSub);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MockSession.activeDeal.addListener(_onActive);
    MockSession.orders.addListener(_onActive);
    MockSession.deals.addListener(_onActive);
    MockSession.homePromos.addListener(_onActive);
    MockSession.notifications.addListener(_onActive);
    MockSession.tabIndex.addListener(_onTab);
    MockSession.homeCardFilter.addListener(_onHomeCardFilter);
    // Apply immediately if View deals already set the filter.
    _onHomeCardFilter();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!MockSession.skipNextHomeDealsRefresh) {
        _softRefreshDeals(force: true);
      } else {
        MockSession.skipNextHomeDealsRefresh = false;
      }
      _refreshHomeBanners();
      PartnerCardsRepository.instance.refreshFromLiveApi();
      SocialProofRepository.instance.refresh();
      _startHomePoll();
      final urls = MockSession.deals.value.expand((d) => d.allImageUrls);
      ProductImageCache.warmUrls(urls, context: context, limit: 24);
    });
  }

  void _onHomeCardFilter() {
    final card = MockSession.homeCardFilter.value;
    if (card == null || card.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _filter = 'all';
      _funnel = HomeFilterResult(cardId: card);
      _search.clear();
    });
  }

  void _onActive() {
    if (mounted) setState(() {});
  }

  void _onTab() {
    if (MockSession.tabIndex.value != 0) {
      _searchFocus.unfocus();
      MockSession.homeChrome.value = 0;
      _homePoll?.cancel();
      _homePoll = null;
      return;
    }
    _onHomeCardFilter();
    if (MockSession.skipNextHomeDealsRefresh) {
      MockSession.skipNextHomeDealsRefresh = false;
    } else {
      _softRefreshDeals(force: true);
    }
    _refreshHomeBanners();
    SocialProofRepository.instance.refresh();
    _startHomePoll();
  }

  void _clearHomeFilters() {
    MockSession.homeCardFilter.value = null;
    setState(() {
      _filter = 'all';
      _funnel = const HomeFilterResult();
      _search.clear();
    });
  }

  void _startHomePoll() {
    _homePoll?.cancel();
    // Backup if FCM is delayed — near-instant while Home is visible.
    _homePoll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || MockSession.tabIndex.value != 0) return;
      _softRefreshDeals(force: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && MockSession.tabIndex.value == 0) {
      _softRefreshDeals(force: true);
      _refreshHomeBanners();
      _startHomePoll();
    } else if (state == AppLifecycleState.paused) {
      _homePoll?.cancel();
      _homePoll = null;
    }
  }

  Future<void> _softRefreshDeals({bool force = false}) async {
    final now = DateTime.now();
    final last = _lastDealsFetch;
    if (!force && last != null && now.difference(last).inSeconds < 6) return;
    _lastDealsFetch = now;
    await DealsRepository.instance.refreshFromLiveApi();
  }

  @override
  void dispose() {
    _homePoll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    MockSession.activeDeal.removeListener(_onActive);
    MockSession.orders.removeListener(_onActive);
    MockSession.deals.removeListener(_onActive);
    MockSession.homePromos.removeListener(_onActive);
    MockSession.notifications.removeListener(_onActive);
    MockSession.tabIndex.removeListener(_onTab);
    MockSession.homeCardFilter.removeListener(_onHomeCardFilter);
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<MockDeal> get _visible {
    final q = _search.text.trim().toLowerCase();
    final list = MockSession.deals.value.where((d) {
      final okType = _filter == 'all' || d.type == _filter;
      if (!okType) return false;
      if (!dealMatchesFilter(d, _funnel)) return false;
      if (q.isEmpty) return true;
      final hay = [
        d.name,
        d.color,
        d.variant,
        d.storeLabel,
        d.storeId,
        d.cardLabel,
        d.homeCardLabel,
        d.cardId,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList()
      ..sort((a, b) => b.earn.compareTo(a.earn));
    return list;
  }

  void _open(MockDeal d) {
    _searchFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    if (MockSession.activeDeal.value != null) {
      showDialog<void>(
        context: context,
        builder: (c) {
          S.watch(c);
          return AlertDialog(
            title: Text(S.t('finish_first')),
            content: Text(
              S.e('Complete the order in progress before accepting another deal.'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: Text(S.t('ok'))),
            ],
          );
        },
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DealDetailScreen(deal: d),
      ),
    ).then((_) {
      if (mounted) {
        _searchFocus.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollUpdateNotification) {
      _searchFocus.unfocus();
      final y = n.metrics.pixels;
      final dy = y - _lastScroll;
      _lastScroll = y;
      if (y < 16) {
        MockSession.homeChrome.value = 0;
      } else if (dy > 4) {
        MockSession.homeChrome.value = 2; // header gone + mini nav
      } else if (dy < -4) {
        MockSession.homeChrome.value = 1; // compact header + mini nav
      }
    }
    return false;
  }

  Future<void> _promoCta(HomePromoSlide slide) async {
    final a = slide.ctaAction;
    if (a == 'open_whatsapp') {
      await openWhatsAppCommunity(context);
    } else if (a == 'open_tutorial') {
      await openTutorials(context);
    } else if (a == 'open_partner_cards') {
      await openPartnerCards(context);
    } else if (a == 'open_url') {
      final url = (slide.ctaUrl ?? '').trim();
      if (url.isEmpty) return;
      await openExternalUrl(
        context,
        url,
        failTitle: S.e('Couldn’t open link'),
      );
    }
  }

  Future<void> _refreshHomeBanners() async {
    await BannersRepository.instance.refreshFromLiveApi();
    await _maybeHomeAlert();
  }

  Future<void> _maybeHomeAlert() async {
    if (_homeAlertChecked || !mounted) return;
    if (!BannersApi.instance.homePopupResolved) return;
    if (MockSession.userId == null) return;
    final popup = BannersApi.instance.pendingHomePopup;
    _homeAlertChecked = true;
    if (popup == null) return;
    if (await SessionStore.homePopupSeen(MockSession.userId, popup.id)) return;
    if (!mounted) return;
    final shown = await showImageAlertPopup(context, imageUrl: popup.imageUrl, link: popup.link);
    if (!shown) return;
    await SessionStore.markHomePopupSeen(MockSession.userId, popup.id);
    await BannersApi.instance.markHomePopupSeen(popup.id);
  }

  Future<void> _onRefresh() async {
    _lastDealsFetch = DateTime.now();
    final ok = await DealsRepository.instance.refreshFromLiveApi();
    await _refreshHomeBanners();
    await SocialProofRepository.instance.refresh();
    if (!mounted) return;
    setState(() {});
    if (ok && MockSession.deals.value.isNotEmpty) {
      MintzerToasts.newDeals(context);
    }
  }

  bool get _catalogEmpty => MockSession.deals.value.isEmpty;

  bool get _filtersActive =>
      _filter != 'all' || _funnel.isActive || _search.text.trim().isNotEmpty;

  String get _activeFilterLabel {
    final bits = <String>[];
    if (_funnel.cardId != null) {
      final hit = MockSession.deals.value.where((d) => d.cardId == _funnel.cardId).map((d) => d.homeCardLabel);
      bits.add(hit.isNotEmpty ? hit.first : _funnel.cardId!);
    }
    if (_funnel.storeId != null) bits.add(_funnel.storeId!);
    if (_funnel.minEarn > 0) bits.add(S.t('earn_rupee', {'n': '${_funnel.minEarn}+'}));
    if (_search.text.trim().isNotEmpty) bits.add('“${_search.text.trim()}”');
    if (bits.isEmpty) {
      return S.e('Filters on');
    }
    return bits.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final deals = _visible;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MintzerColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF0F3),
        // Header pinned — pull-to-refresh only moves the feed.
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: MockSession.homeChrome,
              builder: (context, chrome, _) {
                return _Header(
                  greeting: _greeting,
                  sub: _sub,
                  onWallet: widget.onWallet,
                  wallet: MockSession.totalEarned,
                  chrome: chrome,
                );
              },
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: mintzerRefreshIndicator(
                  edgeOffset: 8,
                  onRefresh: _onRefresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          focusNode: _searchFocus,
                          onChanged: (_) => setState(() {}),
                          onTapOutside: (_) => _searchFocus.unfocus(),
                          decoration: InputDecoration(
                            hintText: S.e('Search deals, store, card…'),
                            hintStyle: const TextStyle(fontSize: 14, color: MintzerColors.muted),
                            prefixIcon: const Icon(Icons.search, color: MintzerColors.muted, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: MintzerColors.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: MintzerColors.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: MintzerColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ViewToggle(grid: _grid, onChanged: (g) => setState(() => _grid = g)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChip(label: S.t('chip_all'), selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                              const SizedBox(width: 8),
                              _FilterChip(label: S.t('chip_direct'), selected: _filter == 'direct', onTap: () => setState(() => _filter = 'direct')),
                              const SizedBox(width: 8),
                              _FilterChip(label: S.t('chip_link'), selected: _filter == 'link', onTap: () => setState(() => _filter = 'link')),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: _funnel.isActive ? const Color(0xFFEDE7FF) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: _funnel.isActive ? MintzerColors.primary : MintzerColors.line),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            final next = await showHomeFilterSheet(context, current: _funnel);
                            if (next != null && mounted) setState(() => _funnel = next);
                          },
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(
                              Icons.tune_rounded,
                              size: 17,
                              color: _funnel.isActive ? MintzerColors.primary : MintzerColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ValueListenableBuilder<List<HomePromoSlide>>(
                  valueListenable: MockSession.homePromos,
                  builder: (context, slides, _) => HomePromoCarousel(
                    slides: slides,
                    onCta: _promoCta,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: _AdminSocialProof()),
              if (MockSession.showHomeTutorial)
                SliverToBoxAdapter(
                  child: _TutorialBanner(
                    onClose: () async {
                      // One tap hides now. Count visit so banner can return once more next launch.
                      MockSession.tutorialHiddenThisSession = true;
                      MockSession.tutorialDismissCount =
                          (MockSession.tutorialDismissCount + 1).clamp(0, MockSession.tutorialMaxShows);
                      await SessionStore.save();
                      if (mounted) setState(() {});
                    },
                    onOpen: () => openTutorials(context),
                  ),
                ),
              if (MockSession.activeDeal.value != null)
                SliverToBoxAdapter(
                  child: _ActiveStrip(
                    deal: MockSession.activeDeal.value!,
                    onTap: () {
                      _searchFocus.unfocus();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PlaceOrderScreen(deal: MockSession.activeDeal.value!),
                        ),
                      );
                    },
                  ),
                ),
              if (_funnel.isActive || _search.text.trim().isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Material(
                      color: const Color(0xFFEDE7FF),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _clearHomeFilters,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_alt_rounded, size: 18, color: MintzerColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _activeFilterLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF5B4BDB),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: MintzerColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  S.t('clear'),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (deals.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          deals.length == 1
                              ? S.t('deal_live', {'n': '${deals.length}'})
                              : S.t('deals_live', {'n': '${deals.length}'}),
                          style: const TextStyle(fontSize: 11, color: MintzerColors.muted),
                        ),
                        const Spacer(),
                        Text(
                          S.t('highest_earn'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: MintzerColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              if (deals.isEmpty)
                SliverToBoxAdapter(
                  child: (!DealsRepository.instance.liveAttempted &&
                          AppConfig.useLiveDealsApi)
                      ? const _HomeDealsLoading()
                      : _filter == 'link'
                          ? _EmptyLinkDeals(
                              onSeeAll: () => setState(() => _filter = 'all'),
                            )
                          : _EmptyHome(
                              filtered: _filtersActive && !_catalogEmpty,
                              onSend: () => showSuggestDealSheet(
                                context,
                                sendAnyway: _filtersActive && !_catalogEmpty,
                              ),
                              onClearFilters: _clearHomeFilters,
                            ),
                )
              else if (_grid)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: 248,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (c, i) => DealCard(
                        deal: deals[i],
                        grid: true,
                        dim: MockSession.activeDeal.value != null,
                        onTap: () => _open(deals[i]),
                      ),
                      childCount: deals.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (c, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DealCard(
                          deal: deals[i],
                          grid: false,
                          dim: MockSession.activeDeal.value != null,
                          onTap: () => _open(deals[i]),
                        ),
                      ),
                      childCount: deals.length,
                    ),
                  ),
                ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.sub,
    required this.onWallet,
    required this.wallet,
    required this.chrome,
  });
  final String greeting;
  final String sub;
  final VoidCallback onWallet;
  final int wallet;
  final int chrome;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final gone = chrome == 2;
    final compact = chrome == 1;
    final topPad = MediaQuery.paddingOf(context).top;
    final purple = compact ? const Color(0xFF8A78FF) : MintzerColors.primary;

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: gone
          ? SizedBox(height: 0, width: MediaQuery.sizeOf(context).width)
          : DecoratedBox(
              decoration: BoxDecoration(
                color: purple,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, topPad + (compact ? 4 : 8), 16, compact ? 12 : 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            greeting,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 15 : 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!compact)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFDDD4FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Wallet · notify · WA — same frosted language, equal gaps.
                    GestureDetector(
                      onTap: onWallet,
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          formatInr(wallet),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ValueListenableBuilder<List<MockNotification>>(
                      valueListenable: MockSession.notifications,
                      builder: (context, _, _) {
                        return _RoundIcon(
                          icon: Icons.notifications_outlined,
                          dot: MockSession.hasUnreadNotifications,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    WhatsAppHeaderButton(
                      onTap: () => openWhatsAppCommunity(context),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, this.dot = false, this.onTap});
  final IconData icon;
  final bool dot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
              child: Center(child: Icon(icon, color: Colors.white, size: 18)),
            ),
            if (dot)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD93025),
                    shape: BoxShape.circle,
                    border: Border.all(color: MintzerColors.primary, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.grid, required this.onChanged});
  final bool grid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MintzerColors.line),
      ),
      child: Row(
        children: [
          _ToggleBtn(icon: Icons.view_list_rounded, active: !grid, onTap: () => onChanged(false)),
          Container(width: 1, height: 34, color: MintzerColors.line),
          _ToggleBtn(icon: Icons.grid_view_rounded, active: grid, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({required this.icon, required this.active, required this.onTap});
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        color: active ? const Color(0xFFF3F0FF) : Colors.transparent,
        child: Icon(icon, size: 18, color: active ? MintzerColors.primary : const Color(0xFF9AA0A6)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? MintzerColors.spendFill : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? MintzerColors.primary : MintzerColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? MintzerColors.primary : const Color(0xFF3C4043),
          ),
        ),
      ),
    );
  }
}

/// Locked empty Home — demo `empty-home` + suggest sheet CTA.
class _HomeDealsLoading extends StatelessWidget {
  const _HomeDealsLoading();

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return  Padding(
      padding: EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: MintzerColors.primary),
            ),
            SizedBox(height: 14),
            Text(
              S.e('Loading deals…'),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5F6368)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Link chip empty — notify for fast grab; never suggest a deal here.
class _EmptyLinkDeals extends StatelessWidget {
  const _EmptyLinkDeals({required this.onSeeAll});
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE7FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, size: 28, color: MintzerColors.primary),
              ),
              const SizedBox(height: 14),
              Text(
                S.e('Link deals drop anytime'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF202124),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                S.e('We’ll notify you when one goes live — grab it fast before it’s gone.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF5F6368), height: 1.4),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSeeAll,
                  child: Text(
                    S.e('See all deals'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({
    required this.filtered,
    required this.onSend,
    required this.onClearFilters,
  });

  final bool filtered;
  final VoidCallback onSend;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE7FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  filtered ? Icons.search_rounded : Icons.send_rounded,
                  size: 28,
                  color: MintzerColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                filtered ? S.t('empty_match') : S.t('empty_got'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF202124),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                filtered ? S.t('empty_match_p') : S.t('empty_got_p'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368), height: 1.4),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSend,
                  child: Text(filtered ? S.t('send_anyway') : S.t('send_in')),
                ),
              ),
              if (filtered) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: onClearFilters,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEDE7FF),
                      foregroundColor: MintzerColors.primary,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: MintzerColors.primary, width: 1.5),
                      ),
                    ),
                    child: Text(S.t('clear_filters'), style: const TextStyle(fontWeight: FontWeight.w800)),
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

class _ActiveStrip extends StatefulWidget {
  const _ActiveStrip({required this.deal, required this.onTap});
  final MockDeal deal;
  final VoidCallback onTap;

  @override
  State<_ActiveStrip> createState() => _ActiveStripState();
}

class _ActiveStripState extends State<_ActiveStrip> {
  Timer? _tick;
  bool _expiryFired = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final end = MockSession.placementEndsAt;
      if (!_expiryFired && end != null && !end.isAfter(DateTime.now())) {
        _expiryFired = true;
        MockSession.expireOpenPlacement();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String get _clock {
    final sec = MockSession.placementSecLeft;
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    // l10n-missing
    const finishBefore = 'Finish before time runs out';
    // l10n-missing
    const reserved = 'Deal reserved';
    final deal = widget.deal;
    final sec = MockSession.placementSecLeft;
    final urgent = sec > 0 && sec < 5 * 60;
    final title = deal.name.length > 22 ? '${deal.name.substring(0, 20)}…' : deal.name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: MintzerColors.gstFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: urgent ? const Color(0xFFF9AB00) : MintzerColors.gstBorder),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      S.e('Active order'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF137333)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: urgent ? const Color(0xFFFEF7E0) : const Color(0xFFCEEAD6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        urgent ? finishBefore : reserved,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: urgent ? const Color(0xFFE37400) : const Color(0xFF137333),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 22, color: urgent ? const Color(0xFFE37400) : const Color(0xFF188038)),
                    const SizedBox(width: 6),
                    Text(
                      // l10n-missing
                      '$_clock left',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: urgent ? const Color(0xFFE37400) : const Color(0xFF188038),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF202124)),
                          ),
                          Text(
                            S.e('Complete your order'),
                            style: TextStyle(fontSize: 11, color: Color(0xFF5F6368)),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: widget.onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: MintzerColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('${S.t('continue')} →', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminSocialProof extends StatelessWidget {
  const _AdminSocialProof();

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return ValueListenableBuilder<HomeSocialProof>(
      valueListenable: SocialProofRepository.instance.value,
      builder: (context, proof, _) {
        if (!proof.visible) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.3),
              children: [
                TextSpan(
                  text: proof.earnedLabel,
                  style: const TextStyle(color: MintzerColors.ink, fontWeight: FontWeight.w800),
                ),
                 TextSpan(text: S.e(' earned this week · ')),
                TextSpan(
                  text: proof.orders,
                  style: const TextStyle(color: MintzerColors.ink, fontWeight: FontWeight.w800),
                ),
                // l10n-missing
                const TextSpan(text: ' orders today'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

class _TutorialBanner extends StatelessWidget {
  const _TutorialBanner({required this.onClose, required this.onOpen});
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      decoration: BoxDecoration(
        color: MintzerColors.spendFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MintzerColors.spendBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpen,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: MintzerColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          S.t('tutorial'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: MintzerColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 16, color: MintzerColors.muted),
          ),
        ],
      ),
    );
  }
}
