import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk-backed product photos — survives force-close (Flipkart / Amazon style).
/// RAM cache alone is wiped on kill; this keeps files on device for ~30 days.
class ProductImageCache {
  ProductImageCache._();

  static const key = 'mintzerProductImages';

  static final CacheManager manager = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 400,
    ),
  );

  /// Pull URLs onto disk (and into RAM if [context] given). Safe to call often.
  static Future<void> warmUrls(
    Iterable<String> urls, {
    BuildContext? context,
    int limit = 16,
  }) async {
    final seen = <String>{};
    final list = <String>[];
    for (final raw in urls) {
      final u = raw.trim();
      if (u.isEmpty || !seen.add(u)) continue;
      list.add(u);
      if (list.length >= limit) break;
    }
    if (list.isEmpty) return;

    const chunk = 6;
    for (var i = 0; i < list.length; i += chunk) {
      final slice = list.skip(i).take(chunk);
      await Future.wait(slice.map((url) async {
        try {
          await manager.downloadFile(url);
          final ctx = context;
          if (ctx != null && ctx.mounted) {
            await precacheImage(
              CachedNetworkImageProvider(url, cacheManager: manager),
              ctx,
            ).timeout(const Duration(seconds: 2), onTimeout: () {});
          }
        } catch (_) {}
      }));
    }
  }
}

/// Network product photo with disk cache + tiny fade only when truly downloading.
class ProductCachedImage extends StatelessWidget {
  const ProductCachedImage({
    super.key,
    required this.url,
    required this.cachePx,
    required this.fallback,
  });

  final String url;
  final int cachePx;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    // Only memCacheWidth — setting both width+height forces a square decode and stretches.
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: ProductImageCache.manager,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      memCacheWidth: cachePx,
      fadeInDuration: const Duration(milliseconds: 80),
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => const ColoredBox(color: Color(0xFFF8F9FA)),
      errorWidget: (_, _, _) => fallback,
      httpHeaders: const {'Accept': 'image/webp,image/*,*/*;q=0.8'},
    );
  }
}
