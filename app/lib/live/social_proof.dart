import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api/api_config.dart';

/// Home line under the banners. Admin Business Settings controls it.
/// Off, or empty figures, means the line is hidden.
class HomeSocialProof {
  const HomeSocialProof({
    required this.enabled,
    required this.earned,
    required this.orders,
  });

  const HomeSocialProof.hidden()
      : enabled = false,
        earned = '',
        orders = '';

  final bool enabled;
  final String earned;
  final String orders;

  bool get visible => enabled && earned.isNotEmpty && orders.isNotEmpty;

  String get earnedLabel => earned.startsWith('₹') ? earned : '₹$earned';
}

class SocialProofRepository {
  SocialProofRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final instance = SocialProofRepository();

  final value = ValueNotifier<HomeSocialProof>(const HomeSocialProof.hidden());

  Future<void> refresh() async {
    try {
      final res = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.businessConfigurationPath}'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) return;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return;
      final earned = _text(decoded['home_social_proof_earned']);
      final orders = _text(decoded['home_social_proof_orders']);
      final enabled = decoded['home_social_proof_enabled'] == true ||
          decoded['home_social_proof_enabled'] == 1 ||
          decoded['home_social_proof_enabled'] == '1';
      value.value = HomeSocialProof(enabled: enabled, earned: earned, orders: orders);
    } catch (_) {
      // Keep the last line. A failed refresh must not invent numbers.
    }
  }

  static String _text(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim();
    return s == 'null' ? '' : s;
  }
}
