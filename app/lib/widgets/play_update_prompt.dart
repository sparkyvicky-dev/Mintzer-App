import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import '../config/app_config.dart';
import '../l10n/s.dart';
import '../util/external_links.dart';

/// Play flexible update. One prompt per app open. Force-update stays off.
enum PlayUpdatePhase { idle, downloading, ready }

class PlayUpdatePrompt {
  PlayUpdatePrompt._();

  static final phase = ValueNotifier<PlayUpdatePhase>(PlayUpdatePhase.idle);
  static bool _asked = false;
  static StreamSubscription<InstallStatus>? _sub;

  static Future<void> maybeAsk(BuildContext context) async {
    if (_asked) return;
    if (kIsWeb || !Platform.isAndroid) return;
    _asked = true;
    _sub ??= InAppUpdate.installUpdateListener.listen((status) {
      if (status == InstallStatus.downloaded) {
        phase.value = PlayUpdatePhase.ready;
      } else if (status == InstallStatus.downloading || status == InstallStatus.pending) {
        phase.value = PlayUpdatePhase.downloading;
      } else if (status == InstallStatus.failed || status == InstallStatus.canceled) {
        phase.value = PlayUpdatePhase.idle;
      }
    });
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (!context.mounted) return;
      if (info.installStatus == InstallStatus.downloaded) {
        phase.value = PlayUpdatePhase.ready;
        return;
      }
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;
      await _sheet(context, flexible: info.flexibleUpdateAllowed);
    } catch (e) {
      debugPrint('Play update check: $e');
    }
  }

  static Future<void> _sheet(BuildContext context, {required bool flexible}) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        S.watch(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  S.e('Update available'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
                ),
                const SizedBox(height: 6),
                Text(
                  S.e('A newer Mintzer is ready. You can keep using the app while it downloads.'),
                  style: const TextStyle(fontSize: 14, height: 1.35, color: Color(0xFF5F6368)),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _start(context, flexible: flexible);
                  },
                  child: Text(S.e('Update')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(S.e('Not now')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _start(BuildContext context, {required bool flexible}) async {
    if (!flexible) {
      if (context.mounted) {
        await openExternalUrl(context, AppConfig.playUrl, failTitle: S.e('Couldn’t open Play Store'));
      }
      return;
    }
    phase.value = PlayUpdatePhase.downloading;
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.userDeniedUpdate || result == AppUpdateResult.inAppUpdateFailed) {
        phase.value = PlayUpdatePhase.idle;
      }
    } catch (e) {
      phase.value = PlayUpdatePhase.idle;
      debugPrint('Play flexible update: $e');
      if (context.mounted) {
        await openExternalUrl(context, AppConfig.playUrl, failTitle: S.e('Couldn’t open Play Store'));
      }
    }
  }

  static Future<void> restart() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('Play complete update: $e');
    }
  }
}
