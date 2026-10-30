import 'package:flutter/material.dart';
import '../models/mock_order.dart';
import '../theme/app_theme.dart';

const _stepIcons = [
  Icons.shopping_bag_outlined,
  Icons.local_shipping_outlined,
  Icons.inventory_2_outlined,
  Icons.home_outlined,
  Icons.description_outlined,
  Icons.schedule,
  Icons.check_circle_outline,
];

/// Horizontal 7-step icon rail. Purple while in progress; green when paid.
class OrderProgressRail extends StatelessWidget {
  const OrderProgressRail({super.key, required this.order});

  final MockOrder order;

  @override
  Widget build(BuildContext context) {
    final paid = order.paid && !order.canceled;
    final color = paid ? MintzerColors.earnGreen : MintzerColors.primary;

    return Row(
      children: [
        for (var i = 0; i < kOrderSteps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _segDone(i - 1, paid) ? color : MintzerColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          _Node(
            icon: _stepIcons[i],
            done: _nodeDone(i, paid),
            current: !paid && !order.canceled && i == order.step,
            color: color,
          ),
        ],
      ],
    );
  }

  bool _nodeDone(int i, bool paid) {
    if (order.canceled) return i == 0;
    if (paid) return true;
    return i < order.step;
  }

  bool _segDone(int afterIndex, bool paid) {
    if (order.canceled) return false;
    if (paid) return true;
    return afterIndex < order.step;
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.icon,
    required this.done,
    required this.current,
    required this.color,
  });

  final IconData icon;
  final bool done;
  final bool current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 11, color: Colors.white),
      );
    }
    if (current) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(icon, size: 11, color: color),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: MintzerColors.line, width: 1.5),
      ),
      child: Icon(icon, size: 11, color: const Color(0xFF9AA0A6)),
    );
  }
}
