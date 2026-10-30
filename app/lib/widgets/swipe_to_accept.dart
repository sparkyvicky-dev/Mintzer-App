import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../theme/app_theme.dart';

/// Magnetic swipe — rich idle animations (knob nudge · cascading chevrons · gradient fill).
class SwipeToAccept extends StatefulWidget {
  const SwipeToAccept({
    super.key,
    required this.onAccepted,
    this.label = 'Swipe to accept deal',
    this.sublabel = 'Reserve this deal and start earning',
  });

  final Future<void> Function() onAccepted;
  final String label;
  final String sublabel;

  @override
  State<SwipeToAccept> createState() => _SwipeToAcceptState();
}

class _SwipeToAcceptState extends State<SwipeToAccept> with TickerProviderStateMixin {
  static const _k = 58.0;
  static const _knob = 50.0;
  static const _pad = 4.0;

  double _x = 0;
  double _max = 1;
  bool _dragging = false;
  bool _done = false;

  late final AnimationController _dragAnim;
  late final AnimationController _idle;
  late final AnimationController _chevs;
  VoidCallback? _tick;

  @override
  void initState() {
    super.initState();
    _dragAnim = AnimationController(vsync: this);
    _idle = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _chevs = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150))..repeat();
  }

  @override
  void dispose() {
    _clearTick();
    _dragAnim.dispose();
    _idle.dispose();
    _chevs.dispose();
    super.dispose();
  }

  void _clearTick() {
    final t = _tick;
    if (t != null) _dragAnim.removeListener(t);
    _tick = null;
  }

  bool get _ok => _x > _max * 0.55;
  bool get _idleAnim => !_dragging && !_done && _x < 4;

  Future<void> _animateTo(double target, Duration d, Curve c) async {
    final from = _x;
    _clearTick();
    _dragAnim.duration = d;
    final tween = Tween(begin: from, end: target).animate(CurvedAnimation(parent: _dragAnim, curve: c));
    void tick() => setState(() => _x = tween.value);
    _tick = tick;
    _dragAnim.addListener(tick);
    await _dragAnim.forward(from: 0);
    _clearTick();
    if (mounted) setState(() => _x = target);
  }

  void _springBack() {
    _animateTo(0, const Duration(milliseconds: 450), const Cubic(0.22, 1.4, 0.36, 1));
  }

  Future<void> _complete() async {
    if (_done) return;
    setState(() => _done = true);
    await _animateTo(_max, const Duration(milliseconds: 220), Curves.easeOut);
    if (mounted) await widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final label = widget.label == 'Swipe to accept deal' ? S.t('swipe') : widget.label;
    return LayoutBuilder(
      builder: (context, box) {
        _max = (box.maxWidth - _k).clamp(1, 4000);
        // No violet fill at rest — purple grows only as the knob moves.
        final fill = (_done || _x > 0.5) ? (_k + _x) : 0.0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              key: const Key('swipe-to-accept'),
              height: 58,
              child: GestureDetector(
                onHorizontalDragStart: _done
                    ? null
                    : (_) {
                        _dragAnim.stop();
                        _clearTick();
                        setState(() => _dragging = true);
                      },
                onHorizontalDragUpdate: _done
                    ? null
                    : (d) {
                        setState(() => _x = (_x + d.delta.dx).clamp(0, _max));
                      },
                onHorizontalDragEnd: _done
                    ? null
                    : (d) {
                        setState(() => _dragging = false);
                        final vx = d.primaryVelocity ?? 0;
                        if (_x > _max * 0.68 || (_x > _max * 0.38 && vx > 550)) {
                          _complete();
                        } else {
                          _springBack();
                        }
                      },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7FF),
                    borderRadius: BorderRadius.circular(29),
                    border: Border.all(color: const Color(0xFFDDD4FF)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(29),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: fill,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF6E54F5), Color(0xFF8B74FF), Color(0xFFA78BFA)],
                                stops: [0, 0.55, 1],
                              ),
                            ),
                          ),
                        ),
                        if (_idleAnim)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _idle,
                                builder: (_, __) {
                                  final t = _idle.value;
                                  return Align(
                                    alignment: Alignment(-1.2 + t * 2.4, 0),
                                    child: Container(
                                      width: 48,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0),
                                            Colors.white.withValues(alpha: 0.18),
                                            Colors.white.withValues(alpha: 0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        // Label / Accepted centered on the full track (not offset past the knob).
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: _done
                                  ? Text(
                                      S.t('accepted'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: _ok ? Colors.white : const Color(0xFF5B4BDB),
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                        ),
                                        if (!_ok) ...[
                                          const SizedBox(width: 4),
                                          _CascadingChevs(controller: _chevs),
                                        ],
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _idle,
                          builder: (_, child) {
                            final nudge = _idleAnim ? Curves.easeInOut.transform(_idle.value) * 6.0 : 0.0;
                            return Positioned(
                              top: _pad,
                              left: _pad + _x + nudge,
                              child: child!,
                            );
                          },
                          child: Transform.scale(
                            scale: _dragging ? 1.06 : 1,
                            child: Container(
                              key: const Key('swipe-knob'),
                              width: _knob,
                              height: _knob,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0x4D7B61FF),
                                    blurRadius: _dragging ? 20 : 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _done ? Icons.check_rounded : Icons.chevron_right_rounded,
                                color: _done ? MintzerColors.earnGreen : MintzerColors.primary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!_done) ...[
              const SizedBox(height: 6),
              Text(
                S.e(widget.sublabel),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _ok ? MintzerColors.primary.withValues(alpha: 0.75) : const Color(0xFF9AA0A6),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CascadingChevs extends StatelessWidget {
  const _CascadingChevs({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (controller.value + i * 0.12) % 1.0;
            final wave = (phase < 0.5) ? phase * 2 : (1 - phase) * 2;
            return Transform.translate(
              offset: Offset(wave * 4, 0),
              child: Opacity(
                opacity: 0.28 + wave * 0.72,
                child: const Text(
                  '›',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF5B4BDB), height: 1),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
