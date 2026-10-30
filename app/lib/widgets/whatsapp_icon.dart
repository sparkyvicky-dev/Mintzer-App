import 'package:flutter/material.dart';

/// Real WhatsApp mark (green bubble + white phone + outer ring).
/// Do **not** ColorFilter to solid white — that reads as a blob, not WA.
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 18});

  final double size;

  static const _asset = 'assets/logos/whatsapp.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }
}

/// Same 36×36 frosted disc as notify — branded WA (not white silhouette).
class WhatsAppHeaderButton extends StatelessWidget {
  const WhatsAppHeaderButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0x33FFFFFF),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        // Slightly larger so the outer white ring of the logo reads clearly.
        child: const WhatsAppIcon(size: 20),
      ),
    );
  }
}
