import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../live/must_test_shapes.dart';
import '../mock/session.dart';
import '../models/mock_order.dart';
import '../theme/app_theme.dart';
import 'order_detail_screen.dart';
import 'wallet_screen.dart';

/// Debug-only Play crash gate — open Tracking · Invoice · Paid · Wallet without OTP.
/// Each screen auto-closes after a short paint window so the gate can run hands-free.
class DebugMustTestGateScreen extends StatefulWidget {
  const DebugMustTestGateScreen({super.key});

  @override
  State<DebugMustTestGateScreen> createState() => _DebugMustTestGateScreenState();
}

class _DebugMustTestGateScreenState extends State<DebugMustTestGateScreen> {
  String _status = 'Loading…';
  bool _pass = false;
  bool _running = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runGate());
  }

  Future<void> _openThenAutoPop(Widget page, {Duration dwell = const Duration(milliseconds: 900)}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _AutoPopHost(dwell: dwell, child: page),
      ),
    );
  }

  Future<void> _runGate() async {
    if (_running) return;
    setState(() {
      _running = true;
      _pass = false;
      _error = null;
      _status = 'Loading Hostinger shapes…';
    });

    try {
      // Empty token → detail screens skip live refresh timers (same as widget tests).
      MockSession.authToken = '';
      MockSession.userId = 0;
      final n = await MustTestShapes.loadIntoSession();
      if (n < 3) {
        throw StateError('Need ≥3 shapes, got $n');
      }
      final orders = List<MockOrder>.from(MockSession.orders.value);

      for (var i = 0; i < orders.length; i++) {
        final o = orders[i];
        if (!mounted) return;
        setState(() => _status = 'Opening ${i + 1}/${orders.length}: ${o.mintzerId}');
        await _openThenAutoPop(OrderDetailScreen(order: o));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }

      if (!mounted) return;
      setState(() => _status = 'Opening Wallet…');
      await _openThenAutoPop(const Scaffold(body: WalletScreen()));

      if (!mounted) return;
      setState(() {
        _pass = true;
        _status = 'PASS — tracking · invoice · paid · wallet opened without crash';
        _running = false;
      });
    } catch (e, st) {
      debugPrint('Must-test gate failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _pass = false;
        _error = e;
        _status = 'FAIL — $e';
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'DebugMustTestGateScreen is debug-only');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crash-gate must-test'),
        actions: [
          TextButton(
            onPressed: _running ? null : _runGate,
            child: const Text('Re-run'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _status,
              key: const Key('must_test_status'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _pass
                    ? MintzerColors.earnGreen
                    : (_error != null ? const Color(0xFFD93025) : MintzerColors.ink),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Debug only. Paints live Hostinger Tracking · Invoice · Paid, then Wallet, then auto-returns.',
              style: TextStyle(fontSize: 13, color: Color(0xFF5F6368), height: 1.35),
            ),
            const Spacer(),
            if (_running) const Center(child: CircularProgressIndicator()),
            if (_pass)
              const Icon(Icons.check_circle, key: Key('must_test_pass'), size: 72, color: MintzerColors.earnGreen),
          ],
        ),
      ),
    );
  }
}

class _AutoPopHost extends StatefulWidget {
  const _AutoPopHost({required this.child, required this.dwell});
  final Widget child;
  final Duration dwell;

  @override
  State<_AutoPopHost> createState() => _AutoPopHostState();
}

class _AutoPopHostState extends State<_AutoPopHost> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.dwell, () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
