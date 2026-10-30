/// Courier dropdown for Order detail Tracking step.
/// Display list is curated (spelling locked). Partner IDs come from live `getLogistics`.
class MintzerCouriers {
  MintzerCouriers._();

  /// Preferred order — matches locked demo + common Flipkart/Amazon partners.
  static const options = <String>[
    'Xpressbees',
    'Ekart',
    'Amazon Logistics',
    'Delhivery',
    'Blue Dart',
    'Shadowfax',
    'Ecom Express',
    'Shiprocket',
    'Om Logistics',
    'DTDC',
    'Others',
  ];

  /// Live `logistic_id` by normalized lowercase label.
  static Map<String, String> _liveIds = {
    'ekart': '1',
    'shiprocket': '2',
    'ecom express': '3',
    'others': '4',
    'xpressbees': '5',
    'om logistics': '6',
    'amazon logistics': '7',
    'blue dart': '8',
    'delhivery': '9',
  };

  static void applyLivePartnerIds(Map<String, String> map) {
    if (map.isEmpty) return;
    _liveIds = {..._liveIds, ...map};
  }

  static bool isJunkLabel(String label) {
    final n = label.toLowerCase().trim();
    return n == 'swiggy' ||
        n == 'express' ||
        n == 'dummy' ||
        n == 'test' ||
        n == 'n/a';
  }

  /// Guess from tracking ID. Empty = unknown (do not invent a default).
  static String detect(String tracking) {
    final u = tracking.trim().toUpperCase();
    if (u.isEmpty) return '';
    if (u.startsWith('FMP') || u.startsWith('EK') || u.startsWith('FMPC') || u.startsWith('FMPP')) {
      return 'Ekart';
    }
    if (u.startsWith('BLUEDART') || RegExp(r'^BD\d').hasMatch(u) || u.startsWith('BL')) {
      return 'Blue Dart';
    }
    if (u.startsWith('XB') || u.startsWith('XPRESSBEES') || u.startsWith('XZ')) {
      return 'Xpressbees';
    }
    if (u.startsWith('SFX') || u.startsWith('SHADOWFAX')) return 'Shadowfax';
    if (u.startsWith('AMZL') || u.startsWith('TBA') || u.startsWith('AMAZON')) {
      return 'Amazon Logistics';
    }
    if (u.startsWith('JIT') || u.startsWith('DLV') || RegExp(r'^1\d{11,}$').hasMatch(u)) {
      return 'Delhivery';
    }
    if (u.startsWith('DTDC') || u.startsWith('D7')) return 'DTDC';
    if (u.startsWith('ECOM') || u.startsWith('EE')) return 'Ecom Express';
    return '';
  }

  /// Name for a live `delivery_partner_id`. Empty when unknown or Others.
  static String labelForPartnerId(String? id) {
    final raw = (id ?? '').trim();
    if (raw.isEmpty || raw == '4') return '';
    for (final entry in _liveIds.entries) {
      if (entry.value != raw) continue;
      final label = normalize(entry.key);
      if (label.isEmpty || label == 'Others' || isJunkLabel(label)) return '';
      return label;
    }
    return '';
  }

  /// Live `delivery_partner_id` (+ `logistic_name` when Others / unmapped).
  static ({String partnerId, String? logisticName}) partnerForApi(String courier) {
    final label = normalize(courier);
    if (label.isEmpty) return (partnerId: '4', logisticName: 'Others');
    final id = _liveIds[label.toLowerCase()];
    if (id != null && id != '4') {
      return (partnerId: id, logisticName: null);
    }
    // Known curated labels without a live row → Others + name.
    if (label != 'Others') {
      return (partnerId: '4', logisticName: label);
    }
    return (partnerId: '4', logisticName: null);
  }

  /// Fix common misspellings / live API labels before save or display.
  static String normalize(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final n = t.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (n == 'bluedart' || n == 'blue dart' || n == 'blue-dart') return 'Blue Dart';
    if (n == 'amazon' ||
        n == 'amazon logictics' ||
        n == 'amazon logistics' ||
        n == 'amazon shipping' ||
        n == 'amzl') {
      return 'Amazon Logistics';
    }
    if (n == 'xpress bees' || n == 'xpressbees' || n == 'xpress-bees') return 'Xpressbees';
    if (n == 'shadow fax' || n == 'shadowfax') return 'Shadowfax';
    if (n == 'other' || n == 'others') return 'Others';
    if (n == 'ekart' || n == 'e-kart') return 'Ekart';
    if (n == 'delhivery') return 'Delhivery';
    if (n == 'ecom express' || n == 'ecomexpress' || n == 'ecom') return 'Ecom Express';
    if (n == 'shiprocket' || n == 'ship rocket') return 'Shiprocket';
    if (n == 'om logistics' || n == 'omlogistic' || n == 'om') return 'Om Logistics';
    if (n == 'dtdc') return 'DTDC';
    for (final o in options) {
      if (o.toLowerCase() == n) return o;
    }
    return t;
  }
}
