import 'dart:async';

import 'package:flutter/material.dart';
import 'app.dart';
import 'config/app_config.dart';
import 'api/profile_api.dart';
import 'live/banners_repository.dart';
import 'live/deals_repository.dart';
import 'live/notifications_repository.dart';
import 'live/orders_repository.dart';
import 'live/tickets_repository.dart';
import 'mock/session.dart';
import 'mock/session_store.dart';
import 'push/push_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep more product photos in RAM so Home / Orders don’t re-fetch / blink.
  PaintingBinding.instance.imageCache.maximumSize = 280;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 160 << 20; // ~160 MB

  // Hard caps — native splash (logo) stays until runApp paints first frame.
  // Never await FCM / network here or Play users can stick on the logo forever.
  try {
    await SessionStore.load().timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('SessionStore.load: $e');
  }
  try {
    await DealsRepository.instance.hydrateFromCache().timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('Deals hydrate: $e');
  }
  if (AppConfig.useLiveOrdersApi) {
    try {
      await OrdersRepository.instance.hydrateFromCache().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Orders hydrate: $e');
    }
  }
  try {
    await BannersRepository.instance.hydrateFromCache().timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('Banners hydrate: $e');
  }
  try {
    await TicketsRepository.instance.hydrateFromCache().timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('Tickets hydrate: $e');
  }
  try {
    await NotificationsRepository.instance.hydrateFromCache().timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('Notifications hydrate: $e');
  }

  if (AppConfig.useLiveDumpFixtures) {
    try {
      await OrdersRepository.instance.loadBundledLiveDump().timeout(const Duration(seconds: 2));
      MockSession.reloadOrdersFromRepo();
    } catch (e) {
      debugPrint('Live dump: $e');
    }
  }

  runApp(const MintzerApp());

  // After first frame path is free — push + live refresh must not block logo exit.
  unawaited(_afterFirstFrame());
}

Future<void> _afterFirstFrame() async {
  try {
    await PushBootstrap.init().timeout(const Duration(seconds: 12));
  } catch (e, st) {
    debugPrint('PushBootstrap.init failed: $e\n$st');
  }
  if (AppConfig.useLiveDumpFixtures) return;
  if (MockSession.authToken.isNotEmpty) {
    unawaited(ProfileApi.instance.refreshProfileIntoSession(authToken: MockSession.authToken));
  }
  if (AppConfig.useLiveOrdersApi && MockSession.authToken.isNotEmpty) {
    unawaited(OrdersRepository.instance.refreshFromLiveApi());
  }
  if (AppConfig.useLiveDealsApi) {
    unawaited(DealsRepository.instance.refreshFromLiveApi());
    unawaited(BannersRepository.instance.refreshFromLiveApi());
  }
  if (MockSession.authToken.isNotEmpty) {
    unawaited(TicketsRepository.instance.refreshFromLiveApi());
    unawaited(NotificationsRepository.instance.refreshFromLiveApi());
  }
}
