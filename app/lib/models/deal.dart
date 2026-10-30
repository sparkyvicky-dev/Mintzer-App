import '../config/app_config.dart';

class MockDeal {
  const MockDeal({
    required this.id,
    required this.type,
    required this.name,
    required this.color,
    required this.variant,
    required this.gst,
    required this.storeId,
    required this.storeLabel,
    required this.cardId,
    required this.cardLabel,
    required this.orderValue,
    required this.commission,
    this.discount = 0,
    this.platformFee = 0,
    this.cardFee = 0,
    this.cashback = 0,
    this.cardHolderSpend,
    this.cashReward,
    this.cardHolderReceive,
    this.tds,
    this.badge,
    this.slotsLeft,
    this.imageAsset,
    this.imageUrl,
    this.imageUrls = const [],
    this.imageDark = false,
    this.rules = const [],
    this.offerText,
    this.productUrl,
    this.paymentHours = 48,
    this.popupImage,
    this.popupUrl,
    this.couponCode,
  });

  final String id;
  /// `direct` (store order) or `link` (Instant — pay link, payout within [paymentHours]h).
  final String type;
  final String name;
  final String color;
  final String variant;
  final bool gst;
  final String storeId;
  final String storeLabel;
  final String cardId;
  final String cardLabel;
  final int orderValue;
  final int discount;
  final int platformFee;
  final int cardFee;
  final int cashback;
  /// Admin **Card holder will spend** (`selling_price`). Null on samples → use formula.
  final int? cardHolderSpend;
  /// Admin cash reward. Null on samples and list rows that do not send the field.
  final int? cashReward;
  /// Admin total card holder will receive. Null means Mintzer payout uses the formula.
  final int? cardHolderReceive;
  final int commission;
  /// Absolute TDS from backend. Null → apply [AppConfig.tdsPercentDefault] of commission.
  final int? tds;
  final String? badge;
  final int? slotsLeft;
  final String? imageAsset;
  /// Remote product image from live API (preferred over [imageAsset] when set).
  final String? imageUrl;
  /// Extra product photos from live `deal_images` (gallery). Never stretch — fit only.
  final List<String> imageUrls;
  final bool imageDark;
  final List<String> rules;
  /// Short offer / instruction line (demo `offerText`).
  final String? offerText;
  final String? productUrl;
  /// Working hours to payout after Instant link deal is finished (24) vs direct (48).
  final int paymentHours;
  /// Deal alert image. Empty means this deal has no popup.
  final String? popupImage;
  /// Optional. Empty means tapping the image does nothing.
  final String? popupUrl;
  /// Store coupon. Empty means the address card hides the line.
  final String? couponCode;

  bool get isInstantLink => type == 'link';

  /// Numeric id for live APIs (`live_345` → 345).
  int? get liveNumericId {
    final m = RegExp(r'^live_(\d+)$').firstMatch(id);
    if (m != null) return int.tryParse(m.group(1)!);
    return int.tryParse(id);
  }

  /// You pay at checkout = admin card holder spend when set; else product − discount + fees.
  int get spend {
    final admin = cardHolderSpend;
    if (admin != null && admin > 0) return admin;
    return orderValue - discount + platformFee + cardFee;
  }

  /// TDS deducted from commission (backend absolute, else % default).
  int get tdsAmount {
    if (tds != null) return tds!.clamp(0, commission);
    return (commission * AppConfig.tdsPercentDefault / 100).round().clamp(0, commission);
  }

  /// Hero earn = commission − TDS
  int get earn => (commission - tdsAmount).clamp(0, commission);

  /// Mintzer payout. Live deals use total card holder will receive.
  int get walletFromMintzer =>
      cardHolderReceive ?? (orderValue - cashback - discount + commission);

  /// Cash reward line. Live deals use the admin cash reward field.
  int get cashRewardShown => cashReward ?? commission;

  String get homeCardLabel {
    if (cardId == 'bob') return 'BOB Credit Card';
    if (cardId == 'amex') return 'Amex';
    return cardLabel
        .replaceFirst(RegExp(r'\s+Credit Card$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s+Card$', caseSensitive: false), '');
  }

  String? get storeLogo {
    if (storeId.isEmpty || storeId == 'unknown') return null;
    return 'assets/logos/stores/$storeId.png';
  }

  String? get cardLogo {
    if (cardId.isEmpty || cardId == 'any') return 'assets/logos/cards/any.png';
    return 'assets/logos/cards/$cardId.png';
  }

  /// Primary + gallery URLs, de-duped, for swipe gallery / warm cache.
  List<String> get allImageUrls {
    final out = <String>[];
    final seen = <String>{};
    void add(String? raw) {
      final u = (raw ?? '').trim();
      if (u.isEmpty || !seen.add(u)) return;
      out.add(u);
    }

    add(imageUrl);
    for (final u in imageUrls) {
      add(u);
    }
    return out;
  }

  /// One chip — **admin only**. Never auto from `slotsLeft` alone.
  /// Admin sets `badge`: `hot` | `trending` | `slots` (slots needs `slotsLeft`).
  ({String kind, String label})? get urgency {
    switch (badge) {
      case 'hot':
        return (kind: 'hot', label: 'Hot');
      case 'trending':
        return (kind: 'trending', label: 'Trending');
      case 'instant':
        return (kind: 'instant', label: 'Instant');
      case 'slots':
        final n = slotsLeft;
        if (n == null) return null;
        return (kind: 'slots', label: n <= 5 ? '$n left' : '$n slots');
      default:
        return null;
    }
  }
}