/// Mintzer delivery address from `getDealDetail` → `address` (dealer pool).
///
/// Panel columns → store checkout titles (rename only — same values):
/// `display_name`, `address`, `address2`, `landmark`, `city`, `state`, `pincode`, `company_name`
class DeliveryAddress {
  const DeliveryAddress({
    required this.addressId,
    this.displayName = '',
    this.line1 = '',
    this.line2 = '',
    this.landmark = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.phone = '',
    this.companyName = '',
  });

  final int addressId;
  final String displayName;
  /// Panel `address` — Flipkart **Location** / Amazon Area·Street.
  final String line1;
  /// Panel `address2` — Flat / House no.
  final String line2;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final String companyName;

  /// Combined locality line (map / Location search).
  String get locationLine {
    final parts = <String>[
      if (line1.trim().isNotEmpty) line1.trim(),
      if (landmark.trim().isNotEmpty) landmark.trim(),
      if (city.trim().isNotEmpty) city.trim(),
      if (state.trim().isNotEmpty) state.trim(),
      if (pincode.trim().isNotEmpty) pincode.trim(),
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    return '';
  }

  String get flatHouse {
    if (line2.trim().isNotEmpty) return line2.trim();
    return '';
  }

  /// Rows for Place order — titles match Flipkart / Amazon checkout labels.
  /// Phone is never the dealer mobile — user enters their own at checkout.
  List<({String label, String value, bool copyable})> copyRows({
    required bool gst,
    String storeId = 'flipkart',
    String? gstNumber,
  }) {
    final amazon = storeId == 'amazon';
    final rows = <({String label, String value, bool copyable})>[
      (
        label: amazon ? 'Full name' : 'Name',
        value: displayName,
        copyable: true,
      ),
      (
        label: 'Mobile number',
        value: 'Use your own number',
        copyable: false,
      ),
      (label: 'Pincode', value: pincode, copyable: true),
      if (amazon) ...[
        (
          label: 'Flat, House no., Building, Company',
          value: flatHouse.isNotEmpty ? flatHouse : line1,
          copyable: true,
        ),
        (
          label: 'Area, Street, Sector, Village',
          value: line1,
          copyable: true,
        ),
        (label: 'Landmark', value: landmark, copyable: true),
        (label: 'Town/City', value: city, copyable: true),
      ] else ...[
        // Flipkart: panel has no "location" column — `address` (+ city/pin) is that field.
        (label: 'Location', value: locationLine, copyable: true),
        (
          label: 'Flat, House no., Building',
          value: flatHouse,
          copyable: true,
        ),
        (label: 'Landmark', value: landmark, copyable: true),
        (label: 'City', value: city, copyable: true),
      ],
      // GSTIN first (copy). Company below — display only, no Copy (easy to mistype on store).
      if (gst) (label: 'GSTIN', value: (gstNumber ?? '').trim(), copyable: true),
      if (gst) (label: 'Company', value: companyName, copyable: false),
    ];
    return rows.where((r) => r.value.trim().isNotEmpty).toList();
  }

  factory DeliveryAddress.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('address json null');
    }
    int id = 0;
    final rawId = json['address_id'];
    if (rawId is int) {
      id = rawId;
    } else {
      id = int.tryParse('${rawId ?? ''}') ?? 0;
    }
    String s(dynamic v) => (v ?? '').toString().trim();
    return DeliveryAddress(
      addressId: id,
      displayName: s(json['display_name']),
      line1: s(json['address']),
      line2: s(json['address2']),
      landmark: s(json['landmark']),
      city: s(json['city']),
      state: s(json['state']),
      pincode: s(json['pincode']),
      phone: s(json['mobile']),
      companyName: s(json['company_name']),
    );
  }
}
