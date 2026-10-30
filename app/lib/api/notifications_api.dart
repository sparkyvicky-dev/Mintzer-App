import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_api.dart';

/// Live bell inbox — `GET /getnotifications` · `POST /updatenotifications`.
class NotificationsApi {
  NotificationsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final instance = NotificationsApi();

  Map<String, String> _headers(String authToken) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  Future<List<Map<String, dynamic>>> fetchNotifications({
    required String authToken,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');

    final res = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getNotificationsPath}'),
          headers: _headers(authToken),
        )
        .timeout(const Duration(seconds: 25));

    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t load notifications'),
        statusCode: res.statusCode,
      );
    }

    final data = decoded['data'];
    if (data is! List) return [];

    final out = <Map<String, dynamic>>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        out.add(item);
      } else if (item is Map) {
        out.add(Map<String, dynamic>.from(item));
      }
    }
    return out;
  }

  Future<void> markAllRead({required String authToken}) async {
    if (authToken.isEmpty) return;
    try {
      await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateNotificationsPath}'),
            headers: {
              ..._headers(authToken),
              'Content-Type': 'application/json',
            },
            body: '{}',
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {}
  }

  Future<void> markOneRead({
    required String authToken,
    required int notificationId,
  }) async {
    if (authToken.isEmpty) return;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateNotificationsPath}')
          .replace(queryParameters: {'notification_id': '$notificationId'});
      await _client
          .post(
            uri,
            headers: {
              ..._headers(authToken),
              'Content-Type': 'application/json',
            },
            body: '{}',
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {}
  }

  /// Wipe inbox on server (`action=clear`) — no archive.
  Future<void> clearAll({required String authToken}) async {
    if (authToken.isEmpty) return;
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateNotificationsPath}')
        .replace(queryParameters: {'action': 'clear'});
    final res = await _client
        .post(
          uri,
          headers: {
            ..._headers(authToken),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'action': 'clear'}),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException('Couldn’t clear notifications', statusCode: res.statusCode);
    }
  }

  static Map<String, dynamic> _decode(String raw) {
    if (raw.trim().isEmpty) return {};
    try {
      final v = jsonDecode(raw);
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
    } catch (_) {}
    return {};
  }

  static String _message(Map<String, dynamic> body, String fallback) {
    final m = body['message'];
    if (m is String && m.trim().isNotEmpty) return m.trim();
    return fallback;
  }
}
