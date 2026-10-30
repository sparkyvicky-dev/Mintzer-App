import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';

/// Soft pre-prompt → Google Play In-App Review when available.
class PlayInAppReview {
  PlayInAppReview._();

  static const _askedKey = 'mintzer_play_review_asked_v1';
  static const _cooldownDays = 90;

  /// After payout / paid.
  static Future<void> maybeAskAfterPayout(BuildContext context) async {
    if (!context.mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_askedKey);
    if (lastMs != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      if (DateTime.now().difference(last).inDays < _cooldownDays) return;
    }
    if (!context.mounted) return;

    final want = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _RatePrePromptSheet(),
    );

    await prefs.setInt(_askedKey, DateTime.now().millisecondsSinceEpoch);
    if (want != true || !context.mounted) return;

    await requestInAppReview();
  }

  static Future<void> requestInAppReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('requestReview: $e');
    }
  }

  /// Profile → Rate Mintzer — opens Play listing.
  static Future<void> openPlayListing() async {
    final market = Uri.parse('market://details?id=${AppConfig.packageId}');
    final https = Uri.parse(AppConfig.playUrl);
    try {
      if (await canLaunchUrl(market)) {
        final ok = await launchUrl(market, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    } catch (_) {}
    try {
      await launchUrl(https, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await InAppReview.instance.openStoreListing();
      } catch (_) {}
    }
  }
}

class _RatePrePromptSheet extends StatelessWidget {
  const _RatePrePromptSheet();

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
          const Text(
            'Loving the earns? 💜',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
          ),
          const SizedBox(height: 10),
          const Text(
            'A quick ⭐⭐⭐⭐⭐ means the world — it helps more people find Mintzer and keep the deals coming your way.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF5F6368), height: 1.45),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.star_rounded, size: 34, color: Color(0xFFF6A623)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: MintzerColors.primary,
            ),
            child: const Text('Leave a ⭐ review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Maybe later', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
          ),
        ],
      ),
    );
  }
}
