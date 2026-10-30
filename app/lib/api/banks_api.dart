import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../live/brand_catalog.dart';
import '../mock/partner_cards.dart';
import 'api_config.dart';

/// Live partner banks — `GET /getBanks` (bundled logos + optional apply URL from admin).
class BanksApi {
  BanksApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final instance = BanksApi();

  Future<List<PartnerCardOffer>> fetchBanks() async {
    final res = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getBanksPath}'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) return const [];
    final decoded = _decode(res.body);
    final data = decoded['data'];
    if (data is! List) return const [];

    final out = <PartnerCardOffer>[];
    final seenPacked = <String>{};

    for (final item in data) {
      final map = item is Map<String, dynamic>
          ? item
          : (item is Map ? Map<String, dynamic>.from(item) : null);
      if (map == null) continue;
      final status = map['status'];
      if (status == 0 || status == '0' || status == false) continue;
      final name = _str(map['name']);
      if (name == null) continue;
      final idRaw = map['id']?.toString() ?? '';
      final packed = _packedCardId(name);
      // Same packed card uploaded more than once (four PNB rows) shows once.
      if (packed != null) {
        if (seenPacked.contains(packed)) continue;
        seenPacked.add(packed);
      }
      final id = packed ??
          (idRaw.isNotEmpty ? 'bank_$idRaw' : 'bank_${name.toLowerCase().hashCode.abs()}');
      out.add(
        PartnerCardOffer(
          id: id,
          bank: name,
          name: name.contains(RegExp(r'card', caseSensitive: false)) ? name : '$name Credit Card',
          applyUrl: _str(map['apply_url']) ?? _str(map['applyUrl']),
          accent: _accentFor(packed ?? id),
          rewardUpto: _int(map['reward_upto']),
          loungeAccess: map['lounge_access'] == true || map['lounge_access'] == 1 || map['lounge_access'] == '1',
          featured: map['featured'] == true || map['featured'] == 1 || map['featured'] == '1',
          featuredSort: _int(map['featured_sort']),
          liveBankId: int.tryParse(idRaw),
        ),
      );
    }
    return out;
  }

  static Color _accentFor(String id) {
    return switch (id) {
      'hdfc' => const Color(0xFF0B4F8A),
      'axis' => const Color(0xFF97144D),
      'amex' => const Color(0xFF006FCF),
      'icici' => const Color(0xFFF57C00),
      'bob' => const Color(0xFFE65100),
      'sbi' => const Color(0xFF1565C0),
      'kotak' => const Color(0xFFED1C24),
      'yes' => const Color(0xFF00518F),
      'indusind' => const Color(0xFF9C1D26),
      'rbl' => const Color(0xFF21317D),
      'idfc' => const Color(0xFF9B1D20),
      'hsbc' => const Color(0xFFDB0011),
      'federal' => const Color(0xFF004B87),
      'canara' => const Color(0xFF00A3E0),
      'pnb' => const Color(0xFF9E1B32),
      'onecard' => const Color(0xFF111111),
      'scapia' => const Color(0xFF5B4BDB),
      _ => const Color(0xFF7B61FF),
    };
  }

  /// Packed logo id when the admin name matches a card in the app. Unknown names stay null.
  static String? _packedCardId(String name) {
    final id = BrandCatalog.cardIdFromName(name);
    if (id == 'any') {
      return name.toLowerCase().contains('any') ? 'any' : null;
    }
    if (BrandCatalog.cardIds.contains(id)) return id;
    return null;
  }

  /// Records one Apply tap. Failures stay quiet so the bank page still opens.
  Future<void> logApplyClick({required String authToken, required int bankId}) async {
    if (authToken.isEmpty || bankId <= 0) return;
    try {
      await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.partnerCardClickPath}'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({'bank_id': bankId}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString().trim());
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty || s == 'null' ? null : s;
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
}
