import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Push permission:
/// 1st ask when Home opens · if they allow, stop.
/// If they skip or deny, one more ask on Place order.
/// Profile can reopen settings. Never hard-blocks the app.
class NotificationPermission {
  NotificationPermission._();

  static const _countKey = 'mintzer_notif_ask_count_v2';

  static Future<bool> isOsGranted() async {
    final s = await Permission.notification.status;
    return s.isGranted || s.isLimited;
  }

  static Future<int> _askCount() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_countKey) ?? 0;
  }

  static Future<void> _setCount(int n) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_countKey, n);
  }

  /// Home, as soon as the app is open. First automatic ask only.
  static Future<void> maybeAskOnFirstHome(BuildContext context) {
    return _maybeAsk(context, onlyWhenCountIs: 0);
  }

  /// Place order. Runs only when the startup ask was skipped or denied.
  static Future<void> maybeAskSecondChance(BuildContext context) {
    return _maybeAsk(context, onlyWhenCountIs: 1);
  }

  static Future<void> _maybeAsk(BuildContext context, {required int onlyWhenCountIs}) async {
    if (!context.mounted) return;
    if (await isOsGranted()) {
      await _setCount(2);
      return;
    }
    if (!context.mounted) return;
    if (await _askCount() != onlyWhenCountIs) return;
    if (!context.mounted) return;

    final want = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _NotifPrePromptSheet(),
    );

    await _setCount(onlyWhenCountIs + 1);
    if (want != true || !context.mounted) return;
    await _requestOs(context);
  }

  static Future<void> _requestOs(BuildContext context) async {
    var status = await Permission.notification.status;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await openAppSettings();
      return;
    }
    if (!context.mounted) return;
    status = await Permission.notification.request();
    if (status.isGranted || status.isLimited) {
      await _setCount(2);
    }
  }

  /// Profile master switch ON — request or open system settings if permanently denied.
  static Future<bool> enableFromProfile(BuildContext context) async {
    var status = await Permission.notification.status;
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (!context.mounted) return false;
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Turn on notifications', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text(
            'Notifications are off in system settings. Open settings to get deal alerts and order timer reminders.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
      if (open == true) await openAppSettings();
      return await isOsGranted();
    }

    status = await Permission.notification.request();
    if (status.isGranted || status.isLimited) await _setCount(2);
    return status.isGranted || status.isLimited;
  }
}

class _NotifPrePromptSheet extends StatelessWidget {
  const _NotifPrePromptSheet();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDADCE0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Icon(Icons.notifications_active_rounded, size: 40, color: MintzerColors.primary),
          const SizedBox(height: 12),
          const Text(
            'Don’t miss your timer',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get notified when high-earn deals go live and when your order timer is running — so you finish on time and get paid.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF5F6368), height: 1.45),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: MintzerColors.primary,
            ),
            child: const Text('Turn on alerts', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
          ),
        ],
      ),
    );
  }
}
