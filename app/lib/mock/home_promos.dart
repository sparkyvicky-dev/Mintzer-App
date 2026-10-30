/// Home promo carousel slides — mirrors `GET /marketing/home-carousel`.
/// Admin uploads image + copy; app does not hardcode campaign art forever.
class HomePromoSlide {
  const HomePromoSlide({
    required this.id,
    required this.kicker,
    required this.title,
    required this.bullets,
    required this.ctaLabel,
    required this.ctaAction,
    this.subtitle = '',
    this.imageUrl,
    this.ctaUrl,
    this.variant = 'default',
  });

  final String id;
  final String kicker;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final String ctaLabel;
  /// open_whatsapp | open_tutorial | open_partner_cards | open_url
  final String ctaAction;
  final String? ctaUrl;
  /// HTTPS CDN from admin upload (optional full-bleed art).
  final String? imageUrl;
  /// default | community | tutorial | cards
  final String variant;

  factory HomePromoSlide.fromJson(Map<String, dynamic> json) {
    return HomePromoSlide(
      id: json['id'] as String? ?? '',
      kicker: json['kicker'] as String? ?? json['title'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      bullets: (json['bullets'] as List?)?.map((e) => '$e').toList() ?? const [],
      ctaLabel: json['ctaLabel'] as String? ?? 'Learn more',
      ctaAction: json['ctaAction'] as String? ?? 'open_url',
      ctaUrl: json['ctaUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      variant: json['variant'] as String? ?? 'default',
    );
  }
}

/// Designed Home carousel (not admin PNG banners).
/// Partner cards → Apply for cards screen. Community → WhatsApp.
List<HomePromoSlide> get kMockHomePromos => const [
      HomePromoSlide(
        id: 'partner_cards',
        kicker: 'Partner cards',
        title: 'Cards for Mintzer deals',
        subtitle: 'Higher earnings on Mintzer deals',
        bullets: [],
        ctaLabel: 'Browse cards →',
        ctaAction: 'open_partner_cards',
        variant: 'cards',
      ),
      HomePromoSlide(
        id: 'community',
        kicker: 'Community',
        title: 'Deals before Home · payout updates',
        bullets: ['New Instant drops first', 'Ask & share with other earners'],
        ctaLabel: 'Join WhatsApp ↗',
        ctaAction: 'open_whatsapp',
        variant: 'community',
      ),
    ];
