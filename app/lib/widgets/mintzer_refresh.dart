import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Premium Home pull-to-refresh — soft white disc, mintzer purple arc, light haptic.
Future<void> runMintzerRefresh(Future<void> Function() work) async {
  HapticFeedback.mediumImpact();
  await work();
  HapticFeedback.selectionClick();
}

Widget mintzerRefreshIndicator({
  required Future<void> Function() onRefresh,
  required Widget child,
  double edgeOffset = 0,
}) {
  return RefreshIndicator(
    color: MintzerColors.primary,
    backgroundColor: Colors.white,
    strokeWidth: 2.8,
    displacement: 52,
    edgeOffset: edgeOffset,
    elevation: 0,
    triggerMode: RefreshIndicatorTriggerMode.onEdge,
    onRefresh: () => runMintzerRefresh(onRefresh),
    child: child,
  );
}
