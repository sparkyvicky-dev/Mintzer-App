import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Release / store gates. Do not flip force-update until live mapper is proven on device.
class AppConfig {
  static const packageId = 'com.mintzer';
  /// iOS bundle ID (same as Android applicationId).
  static const iosBundleId = 'com.mintzer';
  static const versionLabel = '3.0.41';
  static const playUrl = 'https://play.google.com/store/apps/details?id=com.mintzer';

  /// Numeric App Store ID from App Store Connect (set after first listing).
  /// Empty → [appStoreUrl] falls back to [websiteUrl] until you fill this in.
  static const appStoreId = '';

  static String get appStoreUrl => appStoreId.isEmpty
      ? websiteUrl
      : 'https://apps.apple.com/app/id$appStoreId';

  /// Platform store listing for Rate / open-store actions.
  static String get storeUrl {
    if (!kIsWeb && Platform.isIOS) return appStoreUrl;
    return playUrl;
  }

  /// Short label for Profile → Rate Mintzer trailing chip.
  static String get storeLabel {
    if (!kIsWeb && Platform.isIOS) return 'App Store';
    return 'Play';
  }

  /// Share / invite deep link. Prefer website until App Store is live, then
  /// include both stores when [appStoreId] is set.
  static String get inviteStoreUrl {
    if (appStoreId.isEmpty) return playUrl;
    return 'Android: $playUrl · iOS: $appStoreUrl';
  }

  /// Flexible update only until new APK opens real old orders without crash.
  static const forceUpdateEnabled = false;

  /// Live PAN via Cashfree on the server (`POST /pan-verify`). The key stays on the server.
  static const panVerifyLiveEnabled = true;

  /// @Deprecated Use [panVerifyLiveEnabled]. Kept so older asserts still compile if referenced.
  static const cashfreeLiveEnabled = panVerifyLiveEnabled;

  /// Demo-only CTAs (Simulate parcel / invoice / paid / admin reply). Off for Play.
  static const showSimulateControls = false;

  /// When true, Home loads from `getDealdata` (product PNG from admin; our store/bank logos).
  static const useLiveDealsApi = true;

  /// When true and signed in, My Orders loads from `getOrderList`.
  static const useLiveOrdersApi = true;

  /// When true and signed in, Accept + Place order hit live `newapp` writes.
  static const useLiveAcceptApi = true;

  /// When true and signed in, My tickets uses `getticket` / `addnewticket` / `getsubjects`.
  /// Live rows have no order_id and no reply thread — UI hides those empties.
  static const useLiveTicketsApi = true;

  /// When true and signed in, bell inbox uses `getnotifications`.
  static const useLiveNotificationsApi = true;

  /// Offline live dump fixtures (from Phpadmin/orders.sql).
  /// Off by default when live API is on. Keep for offline engineering.
  static const useLiveDumpFixtures = false;
  static const liveDumpAsset = 'assets/live/must_test_orders.json';

  /// Default TDS % of commission when deal has no absolute `tds` from backend.
  static const tdsPercentDefault = 2.0;

  // —— Public links ——
  static const termsUrl = 'https://mintzer.in/terms.html';
  static const privacyUrl = 'https://mintzer.in/privacy.html';
  static const websiteUrl = 'https://mintzer.in/';
  /// Support / community WhatsApp.
  /// Community banner → invite group. Support DMs stay on the ops number.
  static const communityWhatsAppUrl = 'https://chat.whatsapp.com/DkCvcrRoq1sHntOrmUK1Xw';
  static const supportWhatsAppUrl = 'https://wa.me/918248626422';
  /// How to use Mintzer.
  static const tutorialsUrl = 'https://www.youtube.com/watch?v=vv5XV460UgI';
  static const partnerCardsUrl = 'https://mintzer.in/';
}
