import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../mock/session.dart';
import '../models/deal.dart';
import '../models/mock_order.dart';
import '../theme/app_theme.dart';
import '../util/external_links.dart';
import '../util/format.dart';
import 'package:share_plus/share_plus.dart';

/// Order placed — marketing-led: short celebration · earn · CTAs · one fat rotating promo.
/// No Order ID copy card (user just submitted it).
class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final MockOrder order;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with TickerProviderStateMixin {
  late final AnimationController _hero;
  late final AnimationController _content;

  @override
  void initState() {
    super.initState();
    _hero = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _content = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _hero.forward();
      if (mounted) _content.forward();
    });
  }

  @override
  void dispose() {
    _hero.dispose();
    _content.dispose();
    super.dispose();
  }

  void _goOrders() {
    MockSession.goToOrdersTab();
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (r) => false);
  }

  void _goHome() {
    MockSession.goToHomeTab();
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final o = widget.order;
    final d = o.deal;
    final gst = d.gst;
    final fade = CurvedAnimation(parent: _content, curve: Curves.easeOutCubic);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_hero, _content]),
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                children: [
                  SizedBox(height: 140, child: _HeroAnim(progress: _hero.value)),
                  FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(fade),
                      child: Column(
                        children: [
                          Text(
                            S.t('order_placed'),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            gst
                                // l10n-missing
                                ? 'You’re earning ${formatInr(d.earn)}. We’ll verify your GST invoice after delivery.'
                                // l10n-missing
                                : 'You’re earning ${formatInr(d.earn)}. Track delivery and upload invoice in My Orders.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368), height: 1.45),
                          ),
                          const SizedBox(height: 16),
                          _EarnPill(earn: d.earn),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: _goOrders,
                              style: FilledButton.styleFrom(
                                backgroundColor: MintzerColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(S.t('view_order'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _goHome,
                              icon: const Icon(Icons.grid_view_rounded, size: 18),
                              label: Text(S.e('Browse more deals'), style: TextStyle(fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MintzerColors.primary,
                                side: const BorderSide(color: MintzerColors.primary, width: 1.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              S.e('More for you'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _FatPromo(index: o.successPromo, deal: d, onHome: _goHome),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EarnPill extends StatelessWidget {
  const _EarnPill({required this.earn});
  final int earn;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCEEAD6)),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF137333)),
          children: [
             TextSpan(text: S.e('Expected earnings  ')),
            TextSpan(
              text: formatInr(earn),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAnim extends StatelessWidget {
  const _HeroAnim({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final phoneOpacity = progress < 0.4 ? 1.0 : (1.0 - ((progress - 0.4) / 0.12).clamp(0.0, 1.0));
    final checkOpacity = ((progress - 0.45) / 0.15).clamp(0.0, 1.0);
    final pulse = progress < 0.3 ? (progress / 0.3) : (progress < 0.5 ? 1.0 : 0.0);
    final ring = ((progress - 0.15) / 0.35).clamp(0.0, 1.0);
    final confetti = ((progress - 0.55) / 0.3).clamp(0.0, 1.0);

    return Center(
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (pulse > 0)
              Opacity(
                opacity: (1 - pulse) * 0.5 + 0.12,
                child: Transform.scale(
                  scale: 0.75 + pulse * 0.5,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEDE7FF).withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            CustomPaint(
              size: const Size(108, 108),
              painter: _RingPainter(progress: ring),
            ),
            Opacity(
              opacity: phoneOpacity,
              child: const Icon(Icons.smartphone_rounded, size: 48, color: MintzerColors.primary),
            ),
            Opacity(
              opacity: checkOpacity,
              child: Transform.scale(
                scale: 0.86 + 0.14 * checkOpacity,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(color: MintzerColors.primary, shape: BoxShape.circle),
                  child: CustomPaint(painter: _CheckPainter(progress: ((progress - 0.48) / 0.2).clamp(0.0, 1.0))),
                ),
              ),
            ),
            if (confetti > 0)
              ...List.generate(8, (i) {
                final angle = (i / 8) * math.pi * 2;
                final dist = 26.0 + confetti * 32.0;
                final colors = [const Color(0xFF34A853), MintzerColors.primary, const Color(0xFF4285F4), const Color(0xFFFBBC04)];
                return Transform.translate(
                  offset: Offset(math.cos(angle) * dist, math.sin(angle) * dist),
                  child: Opacity(
                    opacity: (1 - confetti * 0.4).clamp(0.0, 1.0),
                    child: Container(
                      width: i.isEven ? 6 : 4,
                      height: i.isEven ? 3 : 6,
                      decoration: BoxDecoration(color: colors[i % 4], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: size.width * 0.42),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = MintzerColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.34);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) => oldDelegate.progress != progress;
}

/// One fat marketing template per order — rotates: order more · partner cards · refer · WA.
class _FatPromo extends StatelessWidget {
  const _FatPromo({required this.index, required this.deal, required this.onHome});
  final int index;
  final MockDeal deal;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return switch (index % 4) {
      0 => _OrderMore(deal: deal, onHome: onHome),
      1 => _PartnerCards(
          onTap: () => openPartnerCards(context),
        ),
      2 => _Refer(
          onTap: () => SharePlus.instance.share(
            ShareParams(
              text:
                  S.e('Join me on Mintzer — earn on Flipkart & Amazon card deals. https://play.google.com/store/apps/details?id=com.mintzer'),
            ),
          ),
        ),
      _ => _WhatsApp(
          onTap: () => openWhatsAppCommunity(context),
        ),
    };
  }
}

class _OrderMore extends StatelessWidget {
  const _OrderMore({required this.deal, required this.onHome});
  final MockDeal deal;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final name = deal.name.length > 24 ? deal.name.substring(0, 24) : deal.name;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onHome,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDD4FF)),
            boxShadow: const [BoxShadow(color: Color(0x297B61FF), blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFEDE7FF), borderRadius: BorderRadius.circular(14)),
                child: const Text('+', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: MintzerColors.primary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.t('order_another'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      S.t('order_more_sub', {
                        'name': name,
                        'n': formatInr(deal.earn).replaceFirst('₹', ''),
                      }),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: MintzerColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartnerCards extends StatelessWidget {
  const _PartnerCards({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MintzerColors.primary, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x407B61FF), blurRadius: 22, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFEDE7FF), borderRadius: BorderRadius.circular(6)),
            child: Text(S.e('PARTNER CARDS'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: MintzerColors.primary, letterSpacing: 0.4)),
          ),
          const SizedBox(height: 10),
          Text(
            S.t('bigger_earn'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.25),
          ),
          const SizedBox(height: 6),
          Text(
            S.e('Apply HDFC or Axis once — unlock higher earn on every matching deal.'),
            style: TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _chip('HDFC')),
              const SizedBox(width: 8),
              Expanded(child: _chip('Axis')),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: MintzerColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(S.t('explore_cards'), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      alignment: Alignment.center,
      child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
    );
  }
}

class _Refer extends StatelessWidget {
  const _Refer({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Material(
      color: const Color(0xFFFFF8E8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFDE293)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.t('refer_b'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                S.t('refer_sp'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(S.e('Share invite →'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: MintzerColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsApp extends StatelessWidget {
  const _WhatsApp({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [Color(0xFF128C7E), Color(0xFF25D366)]),
            boxShadow: const [BoxShadow(color: Color(0x5525D366), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.t('wa_b'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                S.e('Card promos and deal drops hit the channel first.'),
                style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 12),
              // l10n-missing
              const Text('Join channel →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
