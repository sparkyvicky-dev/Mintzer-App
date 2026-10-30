import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/deal.dart';
import '../theme/app_theme.dart';
import 'brand_mark.dart';
import 'product_image_cache.dart';

/// Smooth multi-image product gallery — Home cards + Deal detail.
/// Never stretches. Auto-advances when 2+ images; pauses while the user swipes.
class DealImageGallery extends StatefulWidget {
  const DealImageGallery({
    super.key,
    required this.deal,
    this.height = 220,
    this.compact = false,
    this.autoPlay = true,
    this.showGst = true,
    this.showStoreMark = false,
    this.showUrgency = false,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.showBorder = true,
    this.showDots = true,
    this.showCount = true,
  });

  final MockDeal deal;
  final double height;

  /// Home card: tighter chrome, smaller dots, staggered autoplay.
  final bool compact;
  final bool autoPlay;
  final bool showGst;
  final bool showStoreMark;
  final bool showUrgency;
  final double borderRadius;
  final EdgeInsets padding;
  final bool showBorder;
  final bool showDots;
  final bool showCount;

  @override
  State<DealImageGallery> createState() => _DealImageGalleryState();
}

class _DealImageGalleryState extends State<DealImageGallery> with AutomaticKeepAliveClientMixin {
  late final PageController _page;
  Timer? _auto;
  double _pageValue = 0;
  int _index = 0;
  bool _userDragging = false;

  List<String> get _urls => widget.deal.allImageUrls;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _page = PageController();
    _page.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmAround(0);
      _armAuto();
    });
  }

  @override
  void didUpdateWidget(covariant DealImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deal.id != widget.deal.id ||
        oldWidget.deal.allImageUrls.join() != widget.deal.allImageUrls.join()) {
      _index = 0;
      _pageValue = 0;
      if (_page.hasClients) {
        _page.jumpToPage(0);
      }
      _armAuto();
    }
  }

  @override
  void dispose() {
    _auto?.cancel();
    _page.removeListener(_onScroll);
    _page.dispose();
    super.dispose();
  }

  void _onScroll() {
    final v = _page.page;
    if (v == null || !mounted) return;
    setState(() {
      _pageValue = v;
      _index = v.round().clamp(0, math.max(0, _urls.length - 1));
    });
  }

  Duration get _interval {
    final base = widget.compact ? 3200 : 3800;
    final stagger = widget.deal.id.hashCode.abs() % 900;
    return Duration(milliseconds: base + stagger);
  }

  void _armAuto() {
    _auto?.cancel();
    if (!widget.autoPlay || _urls.length < 2 || !mounted) return;
    _auto = Timer(_interval, _tickAuto);
  }

  Future<void> _tickAuto() async {
    if (!mounted || _userDragging || _urls.length < 2 || !_page.hasClients) {
      _armAuto();
      return;
    }
    final next = (_index + 1) % _urls.length;
    try {
      await _page.animateToPage(
        next,
        duration: Duration(milliseconds: widget.compact ? 520 : 640),
        curve: Curves.easeInOutCubic,
      );
    } catch (_) {}
    if (!mounted) return;
    _warmAround(next);
    _armAuto();
  }

  void _warmAround(int i) {
    final urls = _urls;
    if (urls.isEmpty) return;
    final slice = <String>[
      urls[i],
      if (i + 1 < urls.length) urls[i + 1],
      if (i - 1 >= 0) urls[i - 1],
      if (urls.length > 2) urls[(i + 2) % urls.length],
    ];
    ProductImageCache.warmUrls(slice, context: context, limit: 4);
  }

  void _onDragStart() {
    _userDragging = true;
    _auto?.cancel();
  }

  void _onDragEnd() {
    _userDragging = false;
    _armAuto();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final urls = _urls;
    final deal = widget.deal;
    final multi = urls.length > 1;
    final urgency = deal.urgency;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cachePx = (widget.height * dpr * 1.2).round().clamp(160, 720);

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: deal.imageDark ? const Color(0xFF111111) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.showBorder ? Border.all(color: const Color(0xFFE8EAED)) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (urls.isEmpty)
                _LetterFallback(name: deal.name, compact: widget.compact)
              else if (!multi)
                Padding(
                  padding: widget.padding,
                  child: _FitPhoto(url: urls.first, cachePx: cachePx, fallbackName: deal.name),
                )
              else
                NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollStartNotification && n.dragDetails != null) {
                      _onDragStart();
                    } else if (n is ScrollEndNotification) {
                      _onDragEnd();
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _page,
                    itemCount: urls.length,
                    allowImplicitScrolling: true,
                    physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
                    onPageChanged: (i) {
                      _warmAround(i);
                      setState(() => _index = i);
                    },
                    itemBuilder: (context, i) {
                      final delta = (i - _pageValue).abs().clamp(0.0, 1.0);
                      final scale = 1.0 - (delta * (widget.compact ? 0.04 : 0.06));
                      final opacity = 1.0 - (delta * 0.28);
                      return Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.medium,
                          child: Padding(
                            padding: widget.padding,
                            child: _FitPhoto(
                              url: urls[i],
                              cachePx: cachePx,
                              fallbackName: deal.name,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (widget.compact)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 28,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00F8F9FA), Color(0xE6F8F9FA)],
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.showStoreMark)
                Positioned(
                  top: widget.compact ? 8 : 10,
                  left: widget.compact ? 8 : 10,
                  child: BrandMark(
                    size: widget.compact ? 24 : 28,
                    asset: deal.storeLogo,
                    letter: deal.storeLabel,
                  ),
                ),
              if (widget.showGst && deal.gst)
                Positioned(
                  top: widget.compact ? 8 : 10,
                  right: widget.compact ? 8 : 10,
                  child: const _GstChip(),
                ),
              if (widget.showUrgency && urgency != null)
                Positioned(
                  top: (widget.showGst && deal.gst) ? null : (widget.compact ? 8 : 10),
                  bottom: (widget.showGst && deal.gst) ? 8 : null,
                  right: widget.compact ? 8 : 10,
                  child: _UrgencyChip(kind: urgency.kind, label: urgency.label),
                ),
              if (multi && widget.showCount && !widget.compact)
                Positioned(
                  right: 12,
                  bottom: widget.showDots ? 28 : 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xCC202124),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${_index + 1}/${urls.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (multi && widget.showDots)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: widget.compact ? 6 : 10,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(urls.length, (i) {
                        final on = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          margin: EdgeInsets.symmetric(horizontal: widget.compact ? 2.5 : 3),
                          width: on ? (widget.compact ? 14 : 18) : (widget.compact ? 5 : 6),
                          height: widget.compact ? 5 : 6,
                          decoration: BoxDecoration(
                            color: on
                                ? MintzerColors.primary
                                : (widget.compact ? const Color(0x99DADCE0) : const Color(0xFFDADCE0)),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
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

class _GstChip extends StatelessWidget {
  const _GstChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: MintzerColors.gstFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: MintzerColors.gstBorder),
      ),
      child: const Text(
        'GST',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: MintzerColors.gstText,
          height: 1.2,
        ),
      ),
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  const _UrgencyChip({required this.kind, required this.label});
  final String kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color fg = switch (kind) {
      'hot' => MintzerColors.urgencyHot,
      'slots' => const Color(0xFFB45309),
      'trending' => MintzerColors.primary,
      'instant' => MintzerColors.primary,
      _ => MintzerColors.muted,
    };
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: fg,
        height: 1.2,
        shadows: const [Shadow(color: Color(0xB3000000), blurRadius: 6, offset: Offset(0, 1))],
      ),
    );
  }
}

class _FitPhoto extends StatelessWidget {
  const _FitPhoto({
    required this.url,
    required this.cachePx,
    required this.fallbackName,
  });

  final String url;
  final int cachePx;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    return ProductCachedImage(
      url: url,
      cachePx: cachePx,
      fallback: _LetterFallback(name: fallbackName),
    );
  }
}

class _LetterFallback extends StatelessWidget {
  const _LetterFallback({required this.name, this.compact = false});
  final String name;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();
    return ColoredBox(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: compact ? 28 : 42,
            fontWeight: FontWeight.w800,
            color: MintzerColors.primary,
          ),
        ),
      ),
    );
  }
}
