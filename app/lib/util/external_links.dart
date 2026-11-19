import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../widgets/mintzer_toast.dart';

export '../screens/partner_cards_screen.dart' show openPartnerCards;

/// Opens external URLs / WhatsApp / store / legal. Falls back to toast if launch fails.
Future<bool> openExternalUrl(BuildContext context, String url, {String? failTitle}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    if (context.mounted) {
      showMintzerToast(context, failTitle ?? 'Couldn’t open link', kind: MintzerToastKind.danger);
    }
    return false;
  }
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showMintzerToast(context, failTitle ?? 'Couldn’t open link', kind: MintzerToastKind.warn);
    }
    return ok;
  } catch (_) {
    if (context.mounted) {
      showMintzerToast(context, failTitle ?? 'Couldn’t open link', kind: MintzerToastKind.danger);
    }
    return false;
  }
}

Future<void> openWhatsAppCommunity(BuildContext context) =>
    openExternalUrl(context, AppConfig.communityWhatsAppUrl, failTitle: 'WhatsApp unavailable');

Future<void> openSupportWhatsApp(BuildContext context, {String? preset}) {
  final text = Uri.encodeComponent(preset ?? 'Hi Mintzer support, I need help.');
  return openExternalUrl(context, '${AppConfig.supportWhatsAppUrl}?text=$text', failTitle: 'WhatsApp unavailable');
}

Future<void> openTerms(BuildContext context) =>
    openExternalUrl(context, AppConfig.termsUrl, failTitle: 'Couldn’t open Terms');

Future<void> openPrivacy(BuildContext context) =>
    openExternalUrl(context, AppConfig.privacyUrl, failTitle: 'Couldn’t open Privacy');

Future<void> openTutorials(BuildContext context) =>
    openExternalUrl(context, AppConfig.tutorialsUrl, failTitle: 'Couldn’t open tutorials');

Future<void> openPlayStore(BuildContext context) =>
    openExternalUrl(context, AppConfig.storeUrl, failTitle: 'Couldn’t open store');

/// Opens the platform store listing (Play on Android, App Store on iOS).
Future<void> openAppStore(BuildContext context) => openPlayStore(context);

String storeFallbackUrl(String storeId) => switch (storeId) {
      'amazon' => 'https://www.amazon.in',
      'flipkart' => 'https://www.flipkart.com',
      _ => 'https://www.google.com/search?q=$storeId',
    };
