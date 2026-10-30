import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../util/external_links.dart';
import 'product_image_cache.dart';

/// Poster alert. The picture is downloaded first, then the card opens with it already painted.
/// Returns false when the picture never arrived, so the caller can try again later.
Future<bool> showImageAlertPopup(
  BuildContext context, {
  required String imageUrl,
  String? link,
}) async {
  final image = imageUrl.trim();
  if (image.isEmpty || !context.mounted) return false;
  final url = _browserUrl(link);
  final provider = CachedNetworkImageProvider(
    image,
    cacheManager: ProductImageCache.manager,
  );
  try {
    await precacheImage(provider, context).timeout(const Duration(seconds: 12));
  } catch (_) {
    return false;
  }
  if (!context.mounted) return false;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Close',
    barrierColor: const Color(0xC4100E16),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, _, _) => _ImageAlertCard(image: provider, link: url),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          alignment: Alignment.center,
          child: child,
        ),
      );
    },
  );
  return true;
}

class _ImageAlertCard extends StatelessWidget {
  const _ImageAlertCard({required this.image, this.link});

  final ImageProvider image;
  final String? link;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final maxW = screen.width - 44;
    final maxH = screen.height * 0.74;
    const aspect = 1080 / 1350;
    var width = maxW;
    var height = width / aspect;
    if (height > maxH) {
      height = maxH;
      width = height * aspect;
    }

    return SafeArea(
      child: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 18)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: link == null ? null : () => openExternalUrl(context, link!),
                    child: Image(
                      image: image,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _CloseButton(onPressed: () => Navigator.of(context).pop()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF2FFFFFF),
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.close_rounded, size: 20, color: Color(0xFF1A1528)),
        ),
      ),
    );
  }
}

String? _browserUrl(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty || s == 'null') return null;
  if (s.startsWith('https://') || s.startsWith('http://')) return s;
  return 'https://$s';
}
