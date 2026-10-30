import 'package:flutter/material.dart';
import '../config/intro_config.dart';
import '../live/deals_repository.dart';
import '../mock/session.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image_cache.dart';
import 'shell.dart';

/// Post-OTP brand beat — LOCKED 20 Sep 2026.
/// Masks Home image precache; does not invent wait. Subtle fade/scale only.
/// White underlay so exit never flashes black.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final IntroConfig _cfg;
  bool _showCheck = false;

  static const _bg = Color(0xFFF7F4FF);

  @override
  void initState() {
    super.initState();
    _cfg = IntroConfig.current;
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _enter.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    if (!mounted) return;
    // Brand beat only — deals/images warm in background. Never stall after OTP.
    final minBeat = Future<void>.delayed(
      Duration(milliseconds: _cfg.durationMs.clamp(900, 1600)),
    );
    // ignore: discarded_futures
    DealsRepository.instance.refreshFromLiveApi();
    // ignore: discarded_futures
    _precacheHome(context);
    await minBeat;
    if (!mounted) return;
    setState(() => _showCheck = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _goHome();
  }

  Future<void> _precacheHome(BuildContext context) async {
    final futures = <Future<void>>[
      precacheImage(const AssetImage('assets/logos/mintzer-mark-circle.png'), context),
      precacheImage(const AssetImage('assets/logos/whatsapp.png'), context),
    ];
    final seen = <String>{};
    final productUrls = <String>[];
    for (final d in MockSession.deals.value) {
      final img = d.imageAsset;
      if (img != null && seen.add(img)) {
        futures.add(precacheImage(AssetImage(img), context));
      }
      final store = d.storeLogo;
      if (store != null && seen.add(store)) {
        futures.add(
          precacheImage(AssetImage(store), context).then((_) {}, onError: (_, _) {}),
        );
      }
      final card = d.cardLogo;
      if (card != null && seen.add(card)) {
        futures.add(
          precacheImage(AssetImage(card), context).then((_) {}, onError: (_, _) {}),
        );
      }
      final url = (d.imageUrl ?? '').trim();
      if (url.isNotEmpty) productUrls.add(url);
    }
    // Disk → RAM for first Home cards (instant after force-close if already cached).
    futures.add(ProductImageCache.warmUrls(productUrls, context: context, limit: 12));
    try {
      await Future.wait(futures).timeout(const Duration(milliseconds: 2800));
    } catch (_) {}
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: '/main'),
        pageBuilder: (_, _, _) => const AppShell(),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, anim, _, child) {
          return ColoredBox(
            color: Colors.white,
            child: FadeTransition(opacity: anim, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoIn = CurvedAnimation(parent: _enter, curve: const Interval(0, 0.55, curve: Curves.easeOutCubic));
    final titleIn = CurvedAnimation(parent: _enter, curve: const Interval(0.28, 0.85, curve: Curves.easeOutCubic));
    final footerIn = CurvedAnimation(parent: _enter, curve: const Interval(0.55, 1, curve: Curves.easeOut));

    return Scaffold(
      backgroundColor: _bg,
      body: ColoredBox(
        // Always opaque — prevents black flash when route swaps.
        color: _bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF7F4FF), Color(0xFFFFFFFF), Color(0xFFF3F0FF)],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    FadeTransition(
                      opacity: logoIn,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.94, end: 1).animate(logoIn),
                        child: SizedBox(
                          width: 84,
                          height: 84,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/logos/mintzer-mark-circle.png',
                                width: 84,
                                height: 84,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: AnimatedScale(
                                  scale: _showCheck ? 1 : 0,
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutBack,
                                  child: AnimatedOpacity(
                                    opacity: _showCheck ? 1 : 0,
                                    duration: const Duration(milliseconds: 220),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: MintzerColors.earnGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: const [
                                          BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
                                        ],
                                      ),
                                      child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeTransition(
                      opacity: titleIn,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(titleIn),
                        child: Text(
                          _cfg.brandName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: MintzerColors.ink,
                            letterSpacing: -0.4,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    if (_cfg.headline.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: titleIn,
                        child: Text(
                          _cfg.headline,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.7,
                            color: Color(0xFF9AA0A6),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(flex: 4),
                    FadeTransition(
                      opacity: footerIn,
                      child: Text(
                        _cfg.footer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9AA0A6),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
