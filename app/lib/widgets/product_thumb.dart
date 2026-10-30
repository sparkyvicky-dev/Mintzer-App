import 'package:flutter/material.dart';

import '../models/deal.dart';
import '../theme/app_theme.dart';
import 'product_image_cache.dart';

/// Product photo only: admin [MockDeal.imageUrl] → local [MockDeal.imageAsset] → letter.
/// Live URLs use **disk cache** so force-close → reopen paints fast.
class ProductThumb extends StatelessWidget {
  const ProductThumb({
    super.key,
    required this.deal,
    required this.size,
    this.radius = 10,
    this.padding = 6,
    this.border = true,
  });

  final MockDeal deal;
  final double size;
  final double radius;
  final double padding;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cachePx = (size * dpr).round().clamp(64, 384);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: const Color(0xFFE8EAED)) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: _body(cachePx),
      ),
    );
  }

  Widget _body(int cachePx) {
    final url = (deal.imageUrl ?? '').trim();
    if (url.isNotEmpty) {
      return ProductCachedImage(
        url: url,
        cachePx: cachePx,
        fallback: _fallback(),
      );
    }
    final asset = deal.imageAsset;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        cacheWidth: cachePx,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final letter = deal.name.trim().isEmpty ? '?' : deal.name.trim().substring(0, 1).toUpperCase();
    return ColoredBox(
      color: MintzerColors.spendFill,
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: MintzerColors.primary,
          ),
        ),
      ),
    );
  }
}
