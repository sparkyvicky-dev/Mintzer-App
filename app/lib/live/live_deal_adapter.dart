import '../live/brand_catalog.dart';
import '../models/deal.dart';

/// Parse one live `getDealdata` item. Product image only from admin URL.
/// Admin `is_pine_lab` → app **Instant / link** (never say “Pine Lab” in UI).
MockDeal? liveDealFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  try {
    final id = json['id'];
    if (id == null) return null;

    final name = _str(json['name']) ?? 'Deal';
    final storeName = _str(json['store_name']);
    final storeId = BrandCatalog.storeIdFromName(storeName);
    final storeLabel = BrandCatalog.storeLabel(storeName, storeId);

    final offer = _str(json['offer']);
    final cardId = BrandCatalog.cardIdFromName(offer);
    final cardLabel = BrandCatalog.cardLabel(offer, cardId);

    // Panel money: original_price · selling_price (You pay = card holder spend) ·
    // discount · cashback · earning_price (list = after TDS, detail = Card holder will earn) ·
    // tds_amount · cash_reward · card_holder_receive (detail).
    final selling = _asInt(json['selling_price']) ?? 0;
    final discountRaw = _asInt(json['discount']) ?? 0;
    final original = _asInt(json['original_price']);
    final cashback = _asInt(json['cashback']) ?? 0;
    final tdsAbs = _asInt(json['tds_amount']);
    final earnListed = _asInt(json['earning_price']) ?? 0;
    final cashReward = json.containsKey('cash_reward')
        ? (_asInt(json['cash_reward']) ?? 0)
        : null;
    final cardHolderReceive =
        json.containsKey('card_holder_receive') || json.containsKey('card_holder_recieve')
            ? (_asInt(json['card_holder_receive']) ?? _asInt(json['card_holder_recieve']) ?? 0)
            : null;

    int commission;
    int tdsFixed;
    if (tdsAbs != null) {
      // Detail: earning_price is Card holder will earn (gross). Do not use cash_reward.
      if (earnListed > 0 && tdsAbs > 0 && earnListed <= tdsAbs) {
        commission = earnListed + tdsAbs;
      } else {
        commission = earnListed;
      }
      tdsFixed = tdsAbs.clamp(0, commission);
    } else {
      // List-shaped — earning_price already TDS-net; do not apply % again.
      commission = earnListed;
      tdsFixed = 0;
    }

    final orderValue = original != null && original > 0
        ? original
        : (selling + discountRaw);
    final discount = discountRaw > 0
        ? discountRaw
        : (orderValue > selling ? orderValue - selling : 0);

    final color = _str(json['color']) ?? '';
    final gst = (_str(json['gst_number']) ?? '').isNotEmpty;
    final qty = _asInt(json['order_qty']) ?? _asInt(json['quantity']);

    // product_image only — never store_image / bank_card_image.
    final imageUrl = _str(json['product_image']) ?? _str(json['image']);
    final imageUrls = _imageUrls(json['deal_images'], primary: imageUrl);

    final platformFee = _asInt(json['platform_fee']) ?? 0;
    final cardFee = _asInt(json['card_fee']) ?? 0;

    // Instant link deals (legacy DB flag is_pine_lab) — payment page URL + 24h payout.
    final isInstant = _asInt(json['is_pine_lab']) == 1 ||
        (_str(json['deal_type'])?.toLowerCase() == 'link') ||
        (_str(json['deal_type'])?.toLowerCase() == 'instant');
    final linkUrl = _str(json['pine_lab_url']) ?? _str(json['product_url']) ?? _str(json['offer_link1']);

    return MockDeal(
      id: 'live_$id',
      type: isInstant ? 'link' : 'direct',
      name: name,
      color: color,
      // Live API has one `color` field — do not mirror into variant.
      variant: '',
      gst: gst,
      storeId: storeId,
      storeLabel: storeLabel,
      cardId: cardId,
      cardLabel: cardLabel,
      orderValue: orderValue > 0 ? orderValue : selling,
      discount: discount,
      platformFee: platformFee,
      cardFee: cardFee,
      cashback: cashback,
      cardHolderSpend: selling > 0 ? selling : null,
      cashReward: cashReward,
      cardHolderReceive: cardHolderReceive,
      commission: commission,
      tds: tdsFixed,
      slotsLeft: qty,
      imageAsset: null,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      productUrl: linkUrl,
      paymentHours: isInstant ? 24 : 48,
      offerText: isInstant ? 'Instant · Paid within 24 working hours' : null,
      badge: isInstant ? 'instant' : null,
      popupImage: _str(json['popup_image']),
      popupUrl: _str(json['popup_url']),
      couponCode: _str(json['coupon_code']),
    );
  } catch (_) {
    return null;
  }
}

List<String> _imageUrls(dynamic raw, {String? primary}) {
  final out = <String>[];
  final seen = <String>{};
  void add(String? u) {
    final s = (u ?? '').trim();
    if (s.isEmpty || !seen.add(s)) return;
    out.add(s);
  }

  add(primary);
  if (raw is List) {
    for (final item in raw) {
      if (item is String) {
        add(item);
      } else if (item is Map) {
        add(_str(item['image'] ?? item['url'] ?? item['product_image']));
      }
    }
  }
  // Drop primary from gallery list — [MockDeal.allImageUrls] re-adds it first.
  if (primary != null && primary.trim().isNotEmpty && out.isNotEmpty && out.first == primary.trim()) {
    return out.skip(1).toList(growable: false);
  }
  return List<String>.unmodifiable(out);
}

List<MockDeal> liveDealsFromList(dynamic data) {
  if (data is! List) return const [];
  final out = <MockDeal>[];
  for (final item in data) {
    final map = item is Map<String, dynamic>
        ? item
        : (item is Map ? Map<String, dynamic>.from(item) : null);
    final d = liveDealFromJson(map);
    if (d != null) out.add(d);
  }
  return out;
}

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty || s == 'null' ? null : s;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is bool) return v ? 1 : 0;
  return int.tryParse(v.toString().trim());
}
