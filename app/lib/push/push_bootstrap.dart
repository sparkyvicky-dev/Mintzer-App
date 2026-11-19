import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_api.dart';
import '../live/deals_repository.dart';
import '../mock/session.dart';
import 'push_router.dart';

/// FCM bootstrap — token + phone tray + sync to live `/fcm-update` + V3 register.
/// Tap on tray → [PushRouter] (ticket chat / order / inbox).
@pragma('vm:entry-point')
Future<void> mintzerFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log(
    'FCM background: ${message.messageId} data=${message.data}',
    name: 'mintzer.push',
  );
  final type = message.data['type']?.toString() ?? '';
  if (type == 'deal.catalog' || type == 'deal.live') {
    try {
      await DealsRepository.instance.refreshFromLiveApi();
    } catch (_) {}
  }
}

class PushBootstrap {
  PushBootstrap._();

  static const _tokenKey = 'mintzer_fcm_token_v1';
  static const _lastSyncedKey = 'mintzer_fcm_synced_v1';
  static const _lastV3SyncedKey = 'mintzer_fcm_v3_synced_v1';
  static const channelDeals = 'mintzer_deals';
  static const channelOrders = 'mintzer_orders';
  static const channelPayments = 'mintzer_payments';

  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  /// Last known FCM token (for Firebase Console test send / debug copy).
  static String? lastToken;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 6));
    } catch (e) {
      developer.log('Firebase.initializeApp failed: $e', name: 'mintzer.push');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(mintzerFirebaseMessagingBackgroundHandler);
    } catch (e) {
      developer.log('onBackgroundMessage: $e', name: 'mintzer.push');
    }

    try {
      await _initLocalNotifications().timeout(const Duration(seconds: 4));
    } catch (e) {
      developer.log('local notifications: $e', name: 'mintzer.push');
    }

    final messaging = FirebaseMessaging.instance;

    try {
      await messaging
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    try {
      final settings = await messaging
          .getNotificationSettings()
          .timeout(const Duration(seconds: 3));
      developer.log('FCM permission: ${settings.authorizationStatus}', name: 'mintzer.push');
    } catch (_) {}

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      developer.log(
        'FCM foreground: ${message.notification?.title} ${message.data}',
        name: 'mintzer.push',
      );
      final type = message.data['type']?.toString() ?? '';
      if (type == 'deal.catalog' || type == 'deal.live') {
        await DealsRepository.instance.refreshFromLiveApi();
        final reason = message.data['reason']?.toString() ?? '';
        if (type == 'deal.catalog' && reason != 'on') {
          return;
        }
      }
      await _showLocalFromRemote(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('FCM opened: ${message.data}', name: 'mintzer.push');
      // ignore: discarded_futures
      PushRouter.handleData(Map<String, dynamic>.from(message.data));
    });

    // Cold start: app launched from tray tap — never block init on this.
    try {
      final initial = await messaging.getInitialMessage().timeout(const Duration(seconds: 2));
      if (initial != null) {
        developer.log('FCM cold open: ${initial.data}', name: 'mintzer.push');
        Future<void>.delayed(const Duration(milliseconds: 400), () {
          // ignore: discarded_futures
          PushRouter.handleData(Map<String, dynamic>.from(initial.data));
        });
      }
    } catch (_) {}

    messaging.onTokenRefresh.listen((token) async {
      await _persistToken(token);
      await syncTokenToBackend();
    });

    // getToken frequently hangs on wireless / Play Services — hard cap.
    try {
      final token = await messaging.getToken().timeout(const Duration(seconds: 5));
      if (token != null) await _persistToken(token);
    } catch (e) {
      developer.log('getToken timed out/failed: $e', name: 'mintzer.push');
    }

    if (kDebugMode && lastToken != null) {
      developer.log('FCM token: $lastToken', name: 'mintzer.push');
    }

    // Network sync never blocks init completion.
    // ignore: discarded_futures
    syncTokenToBackend();
  }

  /// Call after OTP / whenever auth token becomes available.
  static Future<void> syncTokenToBackend() async {
    final auth = MockSession.authToken;
    final token = lastToken ?? await readStoredToken();
    if (auth.isEmpty || token == null || token.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getString(_lastSyncedKey);
    final alreadyV3 = prefs.getString(_lastV3SyncedKey);
    final marker = '$auth|$token';

    try {
      if (already != marker) {
        await AuthApi.instance.updateFcmToken(authToken: auth, fcmToken: token);
        await prefs.setString(_lastSyncedKey, marker);
        developer.log('FCM token synced to newapp (/fcm-update)', name: 'mintzer.push');
      }
    } catch (e) {
      developer.log('FCM sync failed: $e', name: 'mintzer.push');
    }

    try {
      if (alreadyV3 != marker) {
        await AuthApi.instance.registerV3PushDevice(authToken: auth, fcmToken: token);
        await prefs.setString(_lastV3SyncedKey, marker);
        developer.log('FCM token synced to V3 devices', name: 'mintzer.push');
      }
    } catch (e) {
      developer.log('V3 register failed: $e', name: 'mintzer.push');
    }
  }

  static Future<void> clearSyncMarker() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncedKey);
    await prefs.remove(_lastV3SyncedKey);
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@drawable/ic_stat_mintzer');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: (resp) {
        // ignore: discarded_futures
        PushRouter.handlePayload(resp.payload);
      },
    );

    final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        channelDeals,
        'Deal alerts',
        description: 'New deals and follow-ups',
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        channelOrders,
        'Order updates',
        description: 'Timers, tracking, parcel',
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        channelPayments,
        'Payment & wallet',
        description: 'Payouts and KYC',
        importance: Importance.defaultImportance,
      ),
    );
  }

  static Future<void> _showLocalFromRemote(RemoteMessage message) async {
    final n = message.notification;
    final title = n?.title ?? message.data['title']?.toString() ?? 'Mintzer';
    final body = n?.body ?? message.data['body']?.toString() ?? '';
    final channel = message.data['channel']?.toString() ?? channelOrders;

    final payload = jsonEncode(Map<String, dynamic>.from(message.data));

    await _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          channel == channelDeals
              ? 'Deal alerts'
              : channel == channelPayments
                  ? 'Payment & wallet'
                  : 'Order updates',
          icon: '@drawable/ic_stat_mintzer',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  static Future<void> _persistToken(String token) async {
    lastToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> readStoredToken() async {
    if (lastToken != null) return lastToken;
    final prefs = await SharedPreferences.getInstance();
    lastToken = prefs.getString(_tokenKey);
    return lastToken;
  }
}
