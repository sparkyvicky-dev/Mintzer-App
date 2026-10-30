import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_api.dart';

/// Live My Orders — `POST /getOrderList` (Sanctum).
class OrdersApi {
  OrdersApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final instance = OrdersApi();

  /// Returns raw order maps for [OrdersRepository.loadRemoteJson]. Never throws empty on soft fail — throws [AuthApiException] on hard failure.
  Future<List<Map<String, dynamic>>> fetchOrderList({
    required String authToken,
    String? status,
    int pageSize = 200,
  }) async {
    if (authToken.isEmpty) {
      throw AuthApiException('Not signed in');
    }

    final body = <String, dynamic>{
      'pageSize': pageSize,
    };
    if (status != null && status.isNotEmpty) {
      body['status'] = status;
    }

    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getOrderListPath}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t load orders'),
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
