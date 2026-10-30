import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Soft crossfade for language copy — no slide (reads fresher on Login).
class LangFadeText extends StatelessWidget {
  const LangFadeText({
    super.key,
    required this.language,
    required this.text,
    this.style,
    this.textAlign,
  });

  final String language;
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        children: [
          ...previous,
          if (current != null) current,
        ],
      ),
      transitionBuilder: (child, anim) {
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        final scale = Tween<double>(begin: 0.97, end: 1).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: Text(
        text,
        key: ValueKey('$language|$text'),
        textAlign: textAlign,
        style: style,
      ),
    );
  }
}

/// Locked EN · हि · ಕಾ · മല rail (Login + Profile).
class LangRail extends StatelessWidget {
  const LangRail({
    super.key,
    required this.language,
    required this.onChanged,
    this.compact = false,
  });

  final String language;
  final ValueChanged<String> onChanged;
  final bool compact;

  static const _items = [
    ('en', 'EN'),
    ('hi', 'हि'),
    ('kn', 'ಕಾ'),
    ('ml', 'മല'),
  ];

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 8.0 : 10.0;
    final vPad = compact ? 7.0 : 10.0;
    final fontSize = compact ? 12.0 : 13.0;
    return Row(
      children: [
        for (final e in _items)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: language == e.$1
                      ? (compact ? const Color(0xFFF3F0FF) : MintzerColors.spendFill)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: language == e.$1
                        ? (compact ? const Color(0xFFDDD4FF) : MintzerColors.primary)
                        : MintzerColors.line,
                    width: compact && language == e.$1 ? 1 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(radius),
                    onTap: () => onChanged(e.$1),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: vPad),
                      child: Center(
                        child: Text(
                          e.$2,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: fontSize,
                            color: language == e.$1 ? MintzerColors.primary : MintzerColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
