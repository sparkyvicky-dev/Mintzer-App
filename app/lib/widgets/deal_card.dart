import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../models/deal.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import 'brand_mark.dart';
import 'deal_image_gallery.dart';

/// Trial layout from ChatGPT declutter brief (product → variant → bank/price → Earn).
/// Locked **style B** kept in git history / demo HTML — flip this to restore overlay caption.
const bool kChatGptCardPreview = true;

class DealCard extends StatelessWidget {
  const DealCard({
    super.key,
    required this.deal,
    required this.grid,
    required this.onTap,
    this.dim = false,
  });

  final MockDeal deal;
  final bool grid;
  final VoidCallback onTap;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final card = kChatGptCardPreview
        ? (grid ? _ChatGptGrid(deal: deal, onTap: onTap) : _ChatGptList(deal: deal, onTap: onTap))
        : (grid ? _StyleBGrid(deal: deal, onTap: onTap) : _StyleBList(deal: deal, onTap: onTap));
    if (!dim) return card;
    return Opacity(opacity: 0.45, child: IgnorePointer(child: card));
  }
}

// ─── ChatGPT preview ─────────────────────────────────────────────────────────

class _ChatGptGrid extends StatelessWidget {
  const _ChatGptGrid({required this.deal, required this.onTap});
  final MockDeal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8EAED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PhotoZone(deal: deal, height: 120),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: MintzerColors.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _variantLine(deal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368), height: 1.25),
                  ),
                  const SizedBox(height: 8),
                  _BankPriceRow(deal: deal),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _EarnButton(earn: deal.earn, onTap: onTap),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatGptList extends StatelessWidget {
  const _ChatGptList({required this.deal, required this.onTap});
  final MockDeal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return SizedBox(
      height: 112,
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE8EAED)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              SizedBox(width: 112, child: _PhotoZone(deal: deal, height: 112)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        deal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MintzerColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _variantLine(deal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368)),
                      ),
                      const SizedBox(height: 6),
                      _BankPriceRow(deal: deal),
                      const Spacer(),
                      _EarnButton(earn: deal.earn, onTap: onTap),
                    ],
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

class _BankPriceRow extends StatelessWidget {
  const _BankPriceRow({required this.deal});
  final MockDeal deal;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Row(
      children: [
        BrandMark(
          size: 20,
          asset: deal.cardLogo,
          anyCard: deal.cardId == 'any',
          letter: deal.cardLabel,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            deal.homeCardLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF5F6368)),
          ),
        ),
        Text(
          formatInr(deal.spend),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MintzerColors.ink),
        ),
      ],
    );
  }
}

String _variantLine(MockDeal d) {
  final parts = <String>[];
  final color = d.color.trim();
  final variant = d.variant.trim();
  if (color.isNotEmpty) parts.add(color);
  // Skip variant when it’s the same as color (live deals used to duplicate).
  if (variant.isNotEmpty && variant.toLowerCase() != color.toLowerCase()) {
    parts.add(variant);
  }
  if (parts.isEmpty) {
    return S.e('Any variant');
  }
  return parts.join(' · ');
}

/// Fixed image zone — multi-image auto-scroll when deal has gallery photos.
class _PhotoZone extends StatelessWidget {
  const _PhotoZone({required this.deal, required this.height});
  final MockDeal deal;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DealImageGallery(
      deal: deal,
      height: height,
      compact: true,
      autoPlay: true,
      showGst: true,
      showStoreMark: true,
      showUrgency: true,
      borderRadius: 0,
      showBorder: false,
      showDots: true,
      showCount: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
    );
  }
}

// ─── Style B (locked) — restore via kChatGptCardPreview = false ──────────────

class _StyleBGrid extends StatelessWidget {
  const _StyleBGrid({required this.deal, required this.onTap});
  final MockDeal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: const Color(0x1A000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFDADCE0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StyleBPhoto(deal: deal, height: 118, width: double.infinity),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: _StyleBCaption(deal: deal),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: _EarnButton(earn: deal.earn, onTap: onTap),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleBList extends StatelessWidget {
  const _StyleBList({required this.deal, required this.onTap});
  final MockDeal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Material(
        color: Colors.white,
        elevation: 1.5,
        shadowColor: const Color(0x1A000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFDADCE0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              _StyleBPhoto(deal: deal, height: 96, width: 96),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: _StyleBCaption(deal: deal),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: _EarnButton(earn: deal.earn, onTap: onTap),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleBCaption extends StatelessWidget {
  const _StyleBCaption({required this.deal});
  final MockDeal deal;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Row(
      children: [
        BrandMark(size: 28, asset: deal.cardLogo, anyCard: deal.cardId == 'any', letter: deal.cardLabel),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            deal.homeCardLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: MintzerColors.muted),
          ),
        ),
        Text(
          formatInr(deal.spend),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: MintzerColors.ink),
        ),
      ],
    );
  }
}

class _StyleBPhoto extends StatelessWidget {
  const _StyleBPhoto({required this.deal, required this.height, required this.width});
  final MockDeal deal;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return SizedBox(
      height: height,
      width: width == double.infinity ? null : width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DealImageGallery(
            deal: deal,
            height: height,
            compact: true,
            autoPlay: true,
            showGst: false,
            showStoreMark: true,
            showUrgency: false,
            borderRadius: 0,
            showBorder: false,
            showDots: deal.allImageUrls.length > 1,
            showCount: false,
            padding: const EdgeInsets.all(6),
          ),
          // Locked style B caption overlay on photo
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xE03C4043)],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, 22, 8, 7),
                  child: SizedBox(height: 28),
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: (deal.gst && deal.urgency != null) ? 48 : 8,
            bottom: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, height: 1.3),
                ),
                Text(
                  '${deal.homeCardLabel} · ${formatInr(deal.spend)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFE8EAED), fontSize: 10, fontWeight: FontWeight.w500, height: 1.25),
                ),
              ],
            ),
          ),
          if (deal.gst)
            const Positioned(top: 8, right: 8, child: _GstPin()),
          if (deal.urgency != null)
            Positioned(
              top: deal.gst ? null : 8,
              bottom: deal.gst ? 8 : null,
              right: 8,
              child: _UrgencyText(kind: deal.urgency!.kind, label: deal.urgency!.label),
            ),
        ],
      ),
    );
  }
}

// ─── Shared ──────────────────────────────────────────────────────────────────

class _EarnButton extends StatelessWidget {
  const _EarnButton({required this.earn, required this.onTap});
  final int earn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return SizedBox(
      height: 36,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: MintzerColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        child: Text(S.t('earn_rupee', {'n': formatInr(earn).replaceFirst('₹', '')})),
      ),
    );
  }
}

class _GstPin extends StatelessWidget {
  const _GstPin();

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      child: Text(
        S.e('GST'),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Color(0xFF5F6368),
          height: 1.2,
        ),
      ),
    );
  }
}

class _UrgencyText extends StatelessWidget {
  const _UrgencyText({required this.kind, required this.label});
  final String kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
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
        shadows: kChatGptCardPreview
            ? null
            : const [
                Shadow(color: Color(0xB3000000), blurRadius: 6, offset: Offset(0, 1)),
              ],
      ),
    );
  }
}
