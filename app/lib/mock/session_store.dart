import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../mock/session.dart';
import '../models/mock_ticket.dart';

/// Persist login + KYC/payout prefs so killing the app doesn't wipe progress.
/// Orders/deals stay mock/in-memory until live APIs are wired.
class SessionStore {  SessionStore._();

  static const _v = 'mintzer_session_v1';
  static const _popupSeen = 'mintzer_home_popup_seen_v1';

  static String _popupKey(int? userId, int bannerId) => '${userId ?? 0}:$bannerId';

  static Future<bool> homePopupSeen(int? userId, int bannerId) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_popupSeen) ?? const <String>[];
    return list.contains(_popupKey(userId, bannerId));
  }

  static Future<void> markHomePopupSeen(int? userId, int bannerId) async {
    final p = await SharedPreferences.getInstance();
    final list = List<String>.from(p.getStringList(_popupSeen) ?? const <String>[]);
    final key = _popupKey(userId, bannerId);
    if (!list.contains(key)) list.add(key);
    await p.setStringList(_popupSeen, list);
  }

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    MockSession.authToken = p.getString('${_v}_auth') ?? '';
    MockSession.userId = p.getInt('${_v}_uid');
    final phone = p.getString('${_v}_phone');
    if (phone != null && phone.length == 10) MockSession.phoneDigits = phone;
    MockSession.displayName = p.getString('${_v}_name') ?? MockSession.displayName;
    MockSession.kycDone = p.getBool('${_v}_kyc') ?? false;
    MockSession.payoutDone = p.getBool('${_v}_payout') ?? false;
    MockSession.panName = p.getString('${_v}_panName') ?? '';
    MockSession.panNumber = p.getString('${_v}_pan') ?? '';
    // Drop old demo seed names so Home never greets "Arun".
    _scrubFakeNames();
    MockSession.bankName = p.getString('${_v}_bank') ?? '';
    MockSession.bankAccount = p.getString('${_v}_acct') ?? '';
    MockSession.bankIfsc = p.getString('${_v}_ifsc') ?? '';
    MockSession.upiId = p.getString('${_v}_upi') ?? '';
    MockSession.pushMaster = p.getBool('${_v}_pushM') ?? true;
    MockSession.pushDeals = p.getBool('${_v}_pushD') ?? true;
    MockSession.pushOrders = p.getBool('${_v}_pushO') ?? true;
    MockSession.pushPayments = p.getBool('${_v}_pushP') ?? true;
    MockSession.shopModeAsked = p.getBool('${_v}_shopAsked') ?? false;
    MockSession.tutorialDismissCount = p.getInt('${_v}_tutorialN') ??
        ((p.getBool('${_v}_tutorial') ?? false) ? MockSession.tutorialMaxShows : 0);
    MockSession.shopMode = p.getString('${_v}_shop') ?? MockSession.shopMode;
    MockSession.language = p.getString('${_v}_lang') ?? 'en';
    MockSession.profilePictureUrl = p.getString('${_v}_pic') ?? '';
    MockSession.useLetterAvatar = p.getBool('${_v}_letter') ??
        (MockSession.profilePictureUrl.isEmpty);
    MockSession.referralCode = p.getString('${_v}_ref') ?? '';
    MockSession.orderNotes
      ..clear()
      ..addAll(_decodeNotes(p.getString('${_v}_notes')));
  }

  static Map<String, String> _decodeNotes(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((k, v) => MapEntry('$k', '$v'));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveOrderNotes() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('${_v}_notes', jsonEncode(MockSession.orderNotes));
  }

  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('${_v}_auth', MockSession.authToken);
    if (MockSession.userId != null) {
      await p.setInt('${_v}_uid', MockSession.userId!);
    } else {
      await p.remove('${_v}_uid');
    }
    await p.setString('${_v}_phone', MockSession.phoneDigits);
    await p.setString('${_v}_name', MockSession.displayName);
    await p.setBool('${_v}_kyc', MockSession.kycDone);
    await p.setBool('${_v}_payout', MockSession.payoutDone);
    await p.setString('${_v}_panName', MockSession.panName);
    await p.setString('${_v}_pan', MockSession.panNumber);
    await p.setString('${_v}_bank', MockSession.bankName);
    await p.setString('${_v}_acct', MockSession.bankAccount);
    await p.setString('${_v}_ifsc', MockSession.bankIfsc);
    await p.setString('${_v}_upi', MockSession.upiId);
    await p.setBool('${_v}_pushM', MockSession.pushMaster);
    await p.setBool('${_v}_pushD', MockSession.pushDeals);
    await p.setBool('${_v}_pushO', MockSession.pushOrders);
    await p.setBool('${_v}_pushP', MockSession.pushPayments);
    await p.setBool('${_v}_shopAsked', MockSession.shopModeAsked);
    await p.setInt('${_v}_tutorialN', MockSession.tutorialDismissCount);
    await p.setString('${_v}_shop', MockSession.shopMode);
    await p.setString('${_v}_lang', MockSession.language);
    await p.setString('${_v}_pic', MockSession.profilePictureUrl);
    await p.setBool('${_v}_letter', MockSession.useLetterAvatar);
    await p.setString('${_v}_ref', MockSession.referralCode);
  }

  static void _scrubFakeNames() {
    const fake = {'arun', 'member', 'there', 'arun k', 'mintzer wh / arun k'};
    final pan = MockSession.panName.trim().toLowerCase();
    final disp = MockSession.displayName.trim().toLowerCase();
    if (fake.contains(pan) || (pan.startsWith('arun') && MockSession.panNumber.trim().isEmpty)) {
      MockSession.panName = '';
      if (MockSession.panNumber.trim().isEmpty) MockSession.kycDone = false;
    }
    if (fake.contains(disp) || disp == 'arun') {
      MockSession.displayName = '';
    }
  }

  static Future<void> clearAuth() async {
    MockSession.authToken = '';
    MockSession.userId = null;
    MockSession.profilePictureUrl = '';
    MockSession.useLetterAvatar = true;
    MockSession.displayName = '';
    MockSession.panName = '';
    MockSession.panNumber = '';
    MockSession.referralCode = '';
    MockSession.kycDone = false;
    MockSession.payoutDone = false;
    MockSession.bankName = '';
    MockSession.bankAccount = '';
    MockSession.bankIfsc = '';
    MockSession.upiId = '';
    if (AppConfig.useLiveTicketsApi) {
      MockSession.tickets.value = <MockTicket>[];
    }
    if (AppConfig.useLiveNotificationsApi) {
      MockSession.notifications.value = <MockNotification>[];
    }
    await save();
  }
}
