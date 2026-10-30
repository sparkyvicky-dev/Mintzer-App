import 'dart:convert';

import 'package:http/http.dart' as http;

import '../mock/home_promos.dart';
import '../mock/session.dart';
import 'api_config.dart';

/// Live Home banners — `GET /getbanners`.
class BannersApi {
  BannersApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final instance = BannersApi();

  /// Latest app-open alert from the last successful `getbanners` call.
  HomeAlertPopup? pendingHomePopup;
  bool homePopupResolved = false;

  Future<List<HomePromoSlide>> fetchBanners({int? userId}) async {
    homePopupResolved = false;
    pendingHomePopup = null;
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getBannersPath}').replace(
      queryParameters: {
        if (userId != null) 'user_id': '$userId',
      },
    );

    final res = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) return const [];

    final decoded = _decode(res.body);
    homePopupResolved = true;
    pendingHomePopup = _homePopup(decoded['home_popup']);
    final data = decoded['data'];
    if (data is! List) return const [];

    final out = <HomePromoSlide>[];
    for (final item in data) {
      final map = item is Map<String, dynamic>
          ? item
          : (item is Map ? Map<String, dynamic>.from(item) : null);
      if (map == null) continue;
      final slide = _fromBanner(map);
      if (slide != null) out.add(slide);
    }
    return out;
  }

  Future<void> markHomePopupSeen(int bannerId) async {
    final token = MockSession.authToken.trim();
    if (token.isEmpty || bannerId < 1) return;
    try {
      await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.homePopupSeenPath}'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'banner_id': bannerId}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  static HomeAlertPopup? _homePopup(dynamic raw) {
    final map = raw is Map<String, dynamic>
        ? raw
        : (raw is Map ? Map<String, dynamic>.from(raw) : null);
    if (map == null) return null;
    final id = int.tryParse('${map['id'] ?? ''}'.trim()) ?? 0;
    final image = _str(map['image']);
    if (id < 1 || image == null) return null;
    return HomeAlertPopup(id: id, imageUrl: image, link: _str(map['url']));
  }

  static HomePromoSlide? _fromBanner(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final image = _str(json['banner_image']);
    final name = _str(json['banner_name']) ?? '';
    final desc = _htmlDecode(_str(json['banner_discription']) ?? '');
    final url = _str(json['banner_url']);
    final opensCards = json['opens_cards'] == 1 || json['opens_cards'] == true || '${json['opens_cards']}' == '1';
    if (image == null && name.isEmpty) return null;

    return HomePromoSlide(
      id: 'banner_$id',
      kicker: 'Mintzer',
      title: name,
      subtitle: desc,
      bullets: const [],
      ctaLabel: opensCards ? 'Browse cards' : (url != null ? 'Open →' : ''),
      ctaAction: opensCards ? 'open_partner_cards' : (url != null ? 'open_url' : 'none'),
      ctaUrl: opensCards ? null : url,
      imageUrl: image,
      variant: 'banner',
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = _htmlDecode(v.toString()).trim();
    if (s.isEmpty || s == 'null') return null;
    return s;
  }

  static String _htmlDecode(String s) {
    var out = s;
    for (var i = 0; i < 4; i++) {
      final next = out
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#039;', "'")
          .replaceAll('&nbsp;', ' ');
      if (next == out) break;
      out = next;
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

  Future<String?> fetchWhatsAppGroupLink() async {
    try {
      final res = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.businessConfigurationPath}'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return null;
      final s = _htmlDecode(decoded['whatsapp_group_link']?.toString() ?? '').trim();
      if (s.isEmpty || s == 'null') return null;
      return s;
    } catch (_) {
      return null;
    }
  }
}

class HomeAlertPopup {
  const HomeAlertPopup({required this.id, required this.imageUrl, this.link});

  final int id;
  final String imageUrl;
  final String? link;
}
