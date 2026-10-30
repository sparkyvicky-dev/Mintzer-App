import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    required this.size,
    this.asset,
    this.anyCard = false,
    this.letter,
  });

  final double size;
  final String? asset;
  final bool anyCard;
  final String? letter;

  @override
  Widget build(BuildContext context) {
    final resolved = anyCard ? (asset ?? 'assets/logos/cards/any.png') : asset;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size > 20 ? 2 : 1.5),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 3, offset: Offset(0, 1))],
      ),
      clipBehavior: Clip.antiAlias,
      child: resolved == null
          ? ColoredBox(
              color: MintzerColors.spendFill,
              child: Center(
                child: Text(
                  _glyph(letter),
                  style: TextStyle(
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w800,
                    color: MintzerColors.primary,
                  ),
                ),
              ),
            )
          : Padding(
              // Tight inset so bank/store PNGs read larger and never look cropped.
              padding: EdgeInsets.all(size * 0.06),
              child: Image.asset(
                resolved,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) {
                  return Center(
                    child: Text(
                      _glyph(letter),
                      style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w800),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

String _glyph(String? letter) {
  final t = (letter ?? '?').trim();
  if (t.isEmpty) return '?';
  return t.substring(0, 1).toUpperCase();
}
