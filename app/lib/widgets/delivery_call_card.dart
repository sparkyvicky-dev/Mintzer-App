import 'dart:async';

import 'package:flutter/material.dart';

import '../models/mock_order.dart';
import '../theme/app_theme.dart';
import '../util/delivery_call.dart';
import '../util/external_links.dart';

/// One clock so every card changes words together.
class _CallCycle {
  static final index = ValueNotifier<int>(0);
  static Timer? _timer;
  static int _uses = 0;

  static void attach() {
    _uses++;
    _timer ??= Timer.periodic(const Duration(milliseconds: 2400), (_) {
      index.value = (index.value + 1) % kDeliveryCallLines.length;
    });
  }

  static void detach() {
    _uses--;
    if (_uses > 0) return;
    _uses = 0;
    _timer?.cancel();
    _timer = null;
  }
}

class _CyclingLabel extends StatefulWidget {
  const _CyclingLabel({required this.style});

  final TextStyle style;

  @override
  State<_CyclingLabel> createState() => _CyclingLabelState();
}

class _CyclingLabelState extends State<_CyclingLabel> {
  @override
  void initState() {
    super.initState();
    _CallCycle.attach();
  }

  @override
  void dispose() {
    _CallCycle.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _CallCycle.index,
      builder: (context, i, _) {
        final text = kDeliveryCallLines[i];
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(text, key: ValueKey(text), textAlign: TextAlign.center, style: widget.style),
        );
      },
    );
  }
}

void _onCallTap(BuildContext context, MockOrder order, VoidCallback onReschedule) {
  final line = kDeliveryCallLines[_CallCycle.index.value];
  if (line.startsWith('Resched')) {
    onReschedule();
    return;
  }
  if (line.startsWith('Any')) {
    openSupportWhatsApp(context, preset: deliveryHelpMessage(order));
    return;
  }
  openSupportWhatsApp(context, preset: deliveryCallMessage(order, line: line));
}

const _waDeep = Color(0xFF128C7E);
const _waSoft = Color(0xFFE7F8EE);
const _waLine = Color(0xFFB7E4C7);

/// Green call card. Shown only after OTP is saved.
class DeliveryCallCard extends StatelessWidget {
  const DeliveryCallCard({super.key, required this.order, required this.onReschedule});

  final MockOrder order;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _waSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _waLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WaMark(),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tell Mintzer',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MintzerColors.ink, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WaButton(
            onTap: () => _onCallTap(context, order, onReschedule),
          ),
        ],
      ),
    );
  }
}

/// Quiet green button for the orders list. Does not open the order.
class DeliveryCallListButton extends StatelessWidget {
  const DeliveryCallListButton({super.key, required this.order, required this.onReschedule});

  final MockOrder order;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        height: 40,
        child: OutlinedButton(
          onPressed: () => _onCallTap(context, order, onReschedule),
          style: OutlinedButton.styleFrom(
            backgroundColor: _waSoft,
            foregroundColor: const Color(0xFF0E7A45),
            side: const BorderSide(color: _waLine),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          child: const _CyclingLabel(
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0E7A45)),
          ),
        ),
      ),
    );
  }
}

class _WaMark extends StatelessWidget {
  const _WaMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_waDeep, MintzerColors.wa],
        ),
      ),
      child: const Text('WA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class _WaButton extends StatelessWidget {
  const _WaButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_waDeep, MintzerColors.wa],
        ),
        boxShadow: const [BoxShadow(color: Color(0x3825D366), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const _CyclingLabel(
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
