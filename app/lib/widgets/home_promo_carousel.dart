import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../config/app_config.dart';
import '../mock/home_promos.dart';
import '../theme/app_theme.dart';
import 'product_image_cache.dart';

/// Locked Home banner carousel — 118dp · swipe · dots · ~5s auto-rotate.
class HomePromoCarousel extends StatefulWidget {
  const HomePromoCarousel({
    super.key,
    required this.slides,
    required this.onCta,
  });

  final List<HomePromoSlide> slides;
  final void Function(HomePromoSlide slide) onCta;

  @override
  State<HomePromoCarousel> createState() => _HomePromoCarouselState();
}

class _HomePromoCarouselState extends State<HomePromoCarousel> {
  late final PageController _page;
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _page = PageController();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    if (widget.slides.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_page.hasClients) return;
      final next = (_index + 1) % widget.slides.length;
      _page.animateToPage(next, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) {
      if (!AppConfig.useLiveDealsApi) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: SizedBox(height: 118),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          SizedBox(
            height: 118,
            child: PageView.builder(
              controller: _page,
              itemCount: widget.slides.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _arm();
              },
              itemBuilder: (context, i) => _Slide(
                slide: widget.slides[i],
                onCta: () => widget.onCta(widget.slides[i]),
              ),
            ),
          ),
          if (widget.slides.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _index ? 14 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _index ? MintzerColors.primary : const Color(0xFFDADCE0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.slide, required this.onCta});
  final HomePromoSlide slide;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final banner = slide.variant == 'banner' && (slide.imageUrl ?? '').isNotEmpty;
    if (banner) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCta,
          borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: slide.imageUrl!,
                    cacheManager: ProductImageCache.manager,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    useOldImageOnUrlChange: true,
                    placeholder: (_, _) => const ColoredBox(color: Color(0xFF1C1C1C)),
                    errorWidget: (_, _, _) => const ColoredBox(color: Color(0xFFF3F0FF)),
                  ),
                  if (slide.title.trim().isNotEmpty)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 28, 12, 10),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0x99000000)],
                          ),
                        ),
                        child: Text(
                          slide.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final cards = slide.variant == 'cards';
    final community = slide.variant == 'community';
    final List<Color> gradient = cards
        ? const [Color(0xFF6E54F5), Color(0xFF9B87FF)]
        : community
            ? const [Color(0xFFFFF8F0), Color(0xFFFFF1E0), Color(0xFFFFE8D1)]
            : const [Color(0xFFF8F7FC), Color(0xFFF3F0FF)];
    final titleColor = cards ? Colors.white : MintzerColors.ink;
    final kickerColor = cards
        ? const Color(0xFFDDD4FF)
        : community
            ? const Color(0xFFC2410C)
            : MintzerColors.primary;
    final bulletColor = cards ? const Color(0xE6FFFFFF) : const Color(0xFF5F6368);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: cards ? null : Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
        image: slide.imageUrl != null
            ? DecorationImage(image: NetworkImage(slide.imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.kicker.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: kickerColor,
                      letterSpacing: 0.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    slide.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                      height: 1.25,
                    ),
                  ),
                  if (slide.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        slide.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9, color: bulletColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                  if (slide.bullets.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    for (final b in slide.bullets.take(2))
                      Text(
                        '· $b',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9, color: bulletColor, height: 1.35),
                      ),
                  ],
                  const Spacer(),
                  Material(
                    color: cards ? Colors.white : MintzerColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: onCta,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(
                          slide.ctaLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cards ? MintzerColors.primary : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 64,
              child: _Art(variant: slide.variant, cards: cards),
            ),
          ],
        ),
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({required this.variant, required this.cards});
  final String variant;
  final bool cards;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    if (variant == 'tutorial') {
      return Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: MintzerColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
        ),
      );
    }
    if (cards) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-8, 6),
            child: _miniCard('HDFC', const Color(0xFF0B4F8A)),
          ),
          Transform.translate(
            offset: const Offset(8, -4),
            child: _miniCard('AXIS', const Color(0xFF97144D)),
          ),
        ],
      );
    }
    // community — mini phone
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 52,
        height: 84,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: MintzerColors.ink, width: 2),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(4)),
              child: Text(
                S.e('🔥 New deal'),
                style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)),
              child: Text(
                S.t('earn_rupee', {'n': '450'}),
                style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniCard(String label, Color bg) {
    return Container(
      width: 40,
      height: 52,
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
    );
  }
}
