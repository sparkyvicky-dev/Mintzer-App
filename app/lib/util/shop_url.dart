/// How an in-app store page may treat a link.
enum ShopNavigation {
  /// Normal store or payment page. Load it inside the app.
  allowPage,

  /// UPI, phone, or store-app link. Hand it to the phone, do not load it inside the page.
  openOutside,

  /// javascript:, file:, http, and anything else. Do not open.
  block,
}

ShopNavigation classifyShopNavigation(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !uri.hasScheme) return ShopNavigation.block;
  switch (uri.scheme.toLowerCase()) {
    case 'https':
      if (uri.host.isEmpty) return ShopNavigation.block;
      return ShopNavigation.allowPage;
    case 'upi':
    case 'intent':
    case 'tel':
    case 'mailto':
    case 'sms':
    case 'whatsapp':
    case 'market':
      return ShopNavigation.openOutside;
    default:
      return ShopNavigation.block;
  }
}
