import '../l10n/strings.dart';
import '../mock/session.dart';

/// Post-login intro — mirrors backend `postLoginIntro*` / marketing endpoint.
/// Until API is live, defaults here. Admin can swap banner + copy without a store release.
class IntroConfig {
  const IntroConfig({
    required this.enabled,
    required this.durationMs,
    required this.brandName,
    required this.headline,
    required this.footer,
    this.bannerUrl,
    this.bannerLink,
  });

  final bool enabled;
  final int durationMs;
  final String brandName;
  /// Optional mid line (empty = brand only). Future: seasonal / campaign.
  final String headline;
  /// e.g. Made with ❤️ in India
  final String footer;
  /// Optional promo / festival banner image (HTTPS).
  final String? bannerUrl;
  /// Optional tap target when banner is shown (deep link or https).
  final String? bannerLink;

  /// Mock bootstrap — replace with `GET /marketing/post-login-intro` later.
  static IntroConfig get current {
    final lang = MockSession.language;
    return IntroConfig(
      enabled: true,
      // Short brand beat — Home continues loading in the background.
      durationMs: 1100,
      brandName: 'Mintzer',
      headline: 'BIGGER OPPORTUNITIES TOGETHER',
      footer: L10n.t(lang, 'intro_footer'),
      bannerUrl: null,
      bannerLink: null,
    );
  }

  factory IntroConfig.fromJson(Map<String, dynamic> json) {
    return IntroConfig(
      enabled: json['enabled'] as bool? ?? true,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 2800,
      brandName: json['brandName'] as String? ?? 'Mintzer',
      headline: json['headline'] as String? ?? '',
      footer: json['footer'] as String? ?? 'Made with ❤️ in India',
      bannerUrl: json['bannerUrl'] as String?,
      bannerLink: json['bannerLink'] as String?,
    );
  }
}
