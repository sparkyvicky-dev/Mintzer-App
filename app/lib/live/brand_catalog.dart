/// Map live store / bank-card **names** → our bundled logo ids.
/// Never use admin `store_image` / `bank_card_image` URLs — only product PNGs are networked.
class BrandCatalog {
  BrandCatalog._();

  static const storeIds = {
    'flipkart',
    'amazon',
    'apple',
    'imagine',
    'instamart',
    'iqoo',
    'jiomart',
    'motorola',
    'myntra',
    'oppo',
    'reliance-digital',
    'sangeetha',
    'shopsy',
    'tata-neu',
    'vijaysales',
    'vivo',
  };

  static const cardIds = {
    'any',
    'amex',
    'axis',
    'bob',
    'canara',
    'federal',
    'hdfc',
    'hsbc',
    'icici',
    'idfc',
    'indusind',
    'kotak',
    'onecard',
    'pnb',
    'rbl',
    'sbi',
    'scapia',
    'yes',
  };

  /// Resolve store master id from API `store_name`.
  /// Never default unknown/empty to Flipkart — that caused Amazon→Flipkart flash.
  static String storeIdFromName(String? raw) {
    final n = (raw ?? '').trim().toLowerCase();
    if (n.isEmpty) return 'unknown';
    if (n.contains('amazon')) return 'amazon';
    if (n.contains('flipkart') || n.contains('shopsy')) {
      return n.contains('shopsy') ? 'shopsy' : 'flipkart';
    }
    if (n.contains('myntra')) return 'myntra';
    if (n.contains('jiomart') || n.contains('jio mart')) return 'jiomart';
    if (n.contains('instamart')) return 'instamart';
    if (n.contains('reliance')) return 'reliance-digital';
    if (n.contains('vijay')) return 'vijaysales';
    if (n.contains('sangeetha')) return 'sangeetha';
    if (n.contains('imagine')) return 'imagine';
    if (n.contains('apple')) return 'apple';
    if (n.contains('motorola')) return 'motorola';
    if (n.contains('iqoo')) return 'iqoo';
    if (n.contains('vivo')) return 'vivo';
    if (n.contains('oppo')) return 'oppo';
    if (n.contains('tata') || n.contains('neu')) return 'tata-neu';
    // Slug match against known ids
    final slug = n.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    if (storeIds.contains(slug)) return slug;
    return 'unknown';
  }

  /// Display label for store (keep API name when present).
  static String storeLabel(String? raw, String storeId) {
    final t = (raw ?? '').trim();
    if (t.isNotEmpty) return t;
    return switch (storeId) {
      'amazon' => 'Amazon',
      'flipkart' => 'Flipkart',
      'shopsy' => 'Shopsy',
      'myntra' => 'Myntra',
      'jiomart' => 'JioMart',
      'instamart' => 'Instamart',
      'reliance-digital' => 'Reliance Digital',
      'vijaysales' => 'Vijay Sales',
      'sangeetha' => 'Sangeetha',
      'imagine' => 'Imagine',
      'apple' => 'Apple',
      'motorola' => 'Motorola',
      'iqoo' => 'iQOO',
      'vivo' => 'vivo',
      'oppo' => 'OPPO',
      'tata-neu' => 'Tata Neu',
      _ => 'Store',
    };
  }

  /// Resolve card master id from API `offer` / bank card name.
  static String cardIdFromName(String? raw) {
    final n = (raw ?? '').trim().toLowerCase();
    if (n.isEmpty) return 'any';
    if (n == 'any' || n.contains('any card') || n.contains('any credit')) return 'any';
    if (n.contains('flipkart') && n.contains('axis')) return 'axis';
    if (n.contains('american express') || n.contains('amex')) return 'amex';
    if (n.contains('one card') || n.contains('onecard')) return 'onecard';
    if (n.contains('scapia')) return 'scapia';
    if (n.contains('indus')) return 'indusind';
    if (n.contains('federal')) return 'federal';
    if (n.contains('canara')) return 'canara';
    if (n.contains('hsbc')) return 'hsbc';
    if (n.contains('idfc')) return 'idfc';
    if (n.contains('kotak')) return 'kotak';
    if (n.contains('yes')) return 'yes';
    if (n.contains('baroda') || n.contains('bob') || RegExp(r'\bbob\b').hasMatch(n)) {
      return 'bob';
    }
    if (n.contains('pnb') || n.contains('punjab')) return 'pnb';
    if (n.contains('rbl')) return 'rbl';
    if (n.contains('sbi') || n.contains('state bank')) return 'sbi';
    if (n.contains('icici')) return 'icici';
    if (n.contains('hdfc')) return 'hdfc';
    if (n.contains('axis')) return 'axis';
    final slug = n.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    if (cardIds.contains(slug)) return slug;
    return 'any';
  }

  static String cardLabel(String? raw, String cardId) {
    final t = (raw ?? '').trim();
    if (t.isNotEmpty) return t;
    return switch (cardId) {
      'any' => 'Any card',
      'amex' => 'American Express',
      'axis' => 'Axis',
      'bob' => 'Bank of Baroda',
      'canara' => 'Canara',
      'federal' => 'Federal',
      'hdfc' => 'HDFC',
      'hsbc' => 'HSBC',
      'icici' => 'ICICI',
      'idfc' => 'IDFC',
      'indusind' => 'IndusInd',
      'kotak' => 'Kotak',
      'onecard' => 'OneCard',
      'pnb' => 'PNB',
      'rbl' => 'RBL',
      'sbi' => 'SBI',
      'scapia' => 'Scapia',
      'yes' => 'Yes Bank',
      _ => 'Card',
    };
  }
}
