import 'dart:convert';

import '../api/banners_api.dart';

import '../config/app_config.dart';

import '../mock/home_promos.dart';

import '../mock/session.dart';

import '../widgets/product_image_cache.dart';

import 'package:shared_preferences/shared_preferences.dart';



/// Home carousel. Slides come from admin banners. Browse cards is one of those banners.

class BannersRepository {

  BannersRepository._();

  static final instance = BannersRepository._();

  static const _cacheKey = 'mintzer_banners_cache_v1';



  Future<bool> refreshFromLiveApi() async {

    if (!AppConfig.useLiveDealsApi) {

      MockSession.homePromos.value = List.from(kMockHomePromos);

      return true;

    }

    try {

      final live = await BannersApi.instance.fetchBanners(userId: MockSession.userId);
      final popupUrl = BannersApi.instance.pendingHomePopup?.imageUrl;
      if (popupUrl != null && popupUrl.isNotEmpty) {
        ProductImageCache.warmUrls([popupUrl], limit: 1);
      }

      if (live.isNotEmpty) {

        _publish(_cardsFirst(live));

        return true;

      }

    } catch (_) {}

    if (MockSession.homePromos.value.isEmpty) {

      _publish(List.from(kMockHomePromos), persist: false);

    }

    return false;

  }



  /// Skip a new list when nothing changed — stops the carousel blanking on resume.

  static void _publish(List<HomePromoSlide> next, {bool persist = true}) {

    final cur = MockSession.homePromos.value;

    if (cur.length == next.length) {

      var same = true;

      for (var i = 0; i < cur.length; i++) {

        if (cur[i].id != next[i].id ||
            cur[i].imageUrl != next[i].imageUrl ||
            cur[i].title != next[i].title ||
            cur[i].ctaUrl != next[i].ctaUrl ||
            cur[i].ctaAction != next[i].ctaAction) {

          same = false;

          break;

        }

      }

      if (same) return;

    }

    MockSession.homePromos.value = next;

    ProductImageCache.warmUrls(next.map((s) => s.imageUrl ?? ''), limit: 8);

    if (persist && next.any((s) => s.id.startsWith('banner_'))) {

      instance._persist(next);

    }

  }



  /// Last Home banners, before the first frame, so the strip does not pop in late.

  Future<void> hydrateFromCache() async {

    try {

      final p = await SharedPreferences.getInstance();

      final raw = p.getString(_cacheKey);

      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);

      if (decoded is! List) return;

      final slides = <HomePromoSlide>[];

      for (final item in decoded) {

        if (item is Map<String, dynamic>) {

          slides.add(HomePromoSlide.fromJson(item));

        } else if (item is Map) {

          slides.add(HomePromoSlide.fromJson(Map<String, dynamic>.from(item)));

        }

      }

      if (slides.isEmpty) return;

      _publish(slides, persist: false);

    } catch (_) {}

  }



  Future<void> _persist(List<HomePromoSlide> slides) async {

    try {

      final p = await SharedPreferences.getInstance();

      await p.setString(_cacheKey, jsonEncode(slides.map(_slideJson).toList()));

    } catch (_) {}

  }



  static Map<String, dynamic> _slideJson(HomePromoSlide s) => {

        'id': s.id,

        'kicker': s.kicker,

        'title': s.title,

        'subtitle': s.subtitle,

        'bullets': s.bullets,

        'ctaLabel': s.ctaLabel,

        'ctaAction': s.ctaAction,

        'ctaUrl': s.ctaUrl,

        'imageUrl': s.imageUrl,

        'variant': s.variant,

      };



  /// Browse-cards admin banners stay first. Nothing else is added by the app.

  static List<HomePromoSlide> _cardsFirst(List<HomePromoSlide> live) {

    final cards = <HomePromoSlide>[];

    final rest = <HomePromoSlide>[];

    for (final s in live) {

      if (s.ctaAction == 'open_partner_cards') {

        cards.add(s);

      } else {

        rest.add(s);

      }

    }

    return [...cards, ...rest];

  }

}


