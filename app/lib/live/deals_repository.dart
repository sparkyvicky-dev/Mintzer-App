import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/deals_api.dart';
import '../config/app_config.dart';
import '../mock/sample_deals.dart';
import '../mock/session.dart';
import '../models/deal.dart';
import '../widgets/product_image_cache.dart';
import 'live_deal_adapter.dart';

/// Live Home deals source.
class DealsRepository {
  DealsRepository._();
  static final instance = DealsRepository._();

  static const _cacheKey = 'mintzer_deals_cache_v1';

  List<MockDeal> _live = const [];
  bool _liveAttempted = false;
  Future<bool>? _inFlight;

  bool get hasLive => _live.isNotEmpty;
  bool get liveAttempted => _liveAttempted;
  bool get isRefreshing => _inFlight != null;

  /// Live mode: only API rows (empty = no deals on). Offline/dev: sample catalog.
  List<MockDeal> fetchDeals() {
    if (AppConfig.useLiveDealsApi) return List.unmodifiable(_live);
    return List.unmodifiable(kSampleDeals);
  }

  /// Restore last successful catalog **before first Home paint** (cold start).
  Future<void> hydrateFromCache() async {
    if (!AppConfig.useLiveDealsApi) return;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final maps = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          maps.add(item);
        } else if (item is Map) {
          maps.add(Map<String, dynamic>.from(item));
        }
      }
      final parsed = liveDealsFromList(maps);
      if (parsed.isEmpty) return;
      _live = parsed;
      MockSession.deals.value = fetchDeals();
      unawaited(_warmProductImages(parsed));
    } catch (e) {
      debugPrint('Deals cache hydrate failed: $e');
    }
  }

  /// Fetch live deals. Coalesces concurrent callers. Never publishes empty over a good cache.
  Future<bool> refreshFromLiveApi({bool precacheImages = true}) {
    if (!AppConfig.useLiveDealsApi) return Future.value(false);
    final existing = _inFlight;
    if (existing != null) return existing;
    final run = _refreshBody(precacheImages: precacheImages);
    _inFlight = run.whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  Future<bool> _refreshBody({required bool precacheImages}) async {
    Object? lastErr;
    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
      }
      try {
        final raw = await DealsApi.instance
            .fetchAllDeals(userId: MockSession.userId)
            .timeout(const Duration(seconds: 15));
        final parsed = liveDealsFromList(raw);

        // A real empty catalog means admin turned the deals off. Keep the
        // previous list only when the request itself fails (see catch below).
        _live = parsed;
        _liveAttempted = true;
        MockSession.deals.value = fetchDeals();
        if (raw.isEmpty) {
          await _clearCache();
        } else {
          await _persistCache(raw);
        }
        if (precacheImages && parsed.isNotEmpty) {
          unawaited(_warmProductImages(parsed));
        }
        return true;
      } catch (e, st) {
        lastErr = e;
        debugPrint('DealsApi refresh attempt ${attempt + 1} failed: $e\n$st');
      }
    }

    _liveAttempted = true;
    MockSession.deals.value = fetchDeals();
    debugPrint('DealsApi refresh gave up: $lastErr');
    return false;
  }

  Future<void> _persistCache(List<Map<String, dynamic>> raw) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_cacheKey, jsonEncode(raw));
    } catch (_) {}
  }

  Future<void> _clearCache() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_cacheKey);
    } catch (_) {}
  }

  /// Disk + optional RAM warm — survives force-close.
  static Future<void> _warmProductImages(List<MockDeal> deals) async {
    final urls = deals.expand((d) => d.allImageUrls);
    await ProductImageCache.warmUrls(urls, limit: 36);
  }
}
