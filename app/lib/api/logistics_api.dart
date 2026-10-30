import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import '../util/couriers.dart';

/// Live `GET /getLogistics` → partner id map for tracking saves.
class LogisticsApi {
  LogisticsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final instance = LogisticsApi();

  Future<void> refreshIntoCouriers() async {
    try {
      final res = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getLogisticsPath}'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) return;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return;
      final data = decoded['data'];
      if (data is! List) return;
      final map = <String, String>{};
      for (final item in data) {
        if (item is! Map) continue;
        final id = item['logistic_id']?.toString().trim() ?? '';
        final raw = item['logistic_name']?.toString().trim() ?? '';
        if (id.isEmpty || raw.isEmpty) continue;
        final label = MintzerCouriers.normalize(raw);
        if (label.isEmpty || MintzerCouriers.isJunkLabel(label)) continue;
        map[label.toLowerCase()] = id;
        // Also index raw for fuzzy match.
        map[raw.toLowerCase()] = id;
      }
      if (map.isNotEmpty) MintzerCouriers.applyLivePartnerIds(map);
    } catch (_) {}
  }
}
