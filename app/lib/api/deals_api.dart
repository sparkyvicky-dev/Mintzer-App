import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_api.dart';

/// Live Home deals — `GET /getDealdata` (public).
/// Fetches **direct** and **Instant (link)** catalogs; never shows “Pine Lab” in the app.
class DealsApi {
  DealsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final instance = DealsApi();

  /// Both deal kinds for Home Direct / Link chips.
  /// Partial failure OK — returns whichever list succeeded. Throws only if both fail.
  Future<List<Map<String, dynamic>>> fetchAllDeals({int? userId}) async {
    List<Map<String, dynamic>>? direct;
    List<Map<String, dynamic>>? link;
    Object? errDirect;
    Object? errLink;

    await Future.wait([
      () async {
        try {
          direct = await fetchDeals(userId: userId, instantLink: false);
        } catch (e) {
          errDirect = e;
        }
      }(),
      () async {
        try {
          link = await fetchDeals(userId: userId, instantLink: true);
        } catch (e) {
          errLink = e;
        }
      }(),
    ]);

    if (direct == null && link == null) {
      throw AuthApiException(
        'Couldn’t load deals',
        statusCode: (errDirect is AuthApiException)
            ? (errDirect as AuthApiException).statusCode
            : (errLink is AuthApiException)
                ? (errLink as AuthApiException).statusCode
                : null,
      );
    }

    final byId = <String, Map<String, dynamic>>{};
    for (final item in direct ?? const <Map<String, dynamic>>[]) {
      final id = '${item['id'] ?? ''}';
      if (id.isEmpty) continue;
      byId[id] = item;
    }
    for (final item in link ?? const <Map<String, dynamic>>[]) {
      final id = '${item['id'] ?? ''}';
      if (id.isEmpty) continue;
      final copy = Map<String, dynamic>.from(item);
      copy['is_pine_lab'] = copy['is_pine_lab'] ?? 1;
      byId[id] = copy;
    }
    return byId.values.toList();
  }

  /// [instantLink] true → admin `is_pine_lab=1` (Instant / link deals).
  Future<List<Map<String, dynamic>>> fetchDeals({
    int? userId,
    bool instantLink = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getDealdataPath}').replace(
      queryParameters: {
        if (userId != null) 'user_id': '$userId',
        'is_pine_lab': instantLink ? '1' : '0',
      },
    );

    final res = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));

    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t load deals'),
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
